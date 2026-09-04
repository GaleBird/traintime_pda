#!/usr/bin/env python3
"""Upload a file to the R2 bucket gxu-apk (replaces the old DO Spaces upload in CI).

Auth: R2 S3-style credentials derived from an API token created via the
Cloudflare user-tokens API with bucket-scoped R2 Object Read & Write:
  Access Key ID = token UUID (32 hex chars)
  Secret Access Key = sha256(token value)

Falls back to a single PUT for small files and multipart upload (20MB parts)
for larger ones, with retries for flaky connections.
"""
import argparse
import hashlib
import hmac
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import datetime

PART_SIZE = 20 * 1024 * 1024
MULTIPART_THRESHOLD = 20 * 1024 * 1024
MAX_TRIES = 5


class R2Client:
  def __init__(self, account_id, access_key_id, secret, bucket):
    self._host = f'{account_id}.r2.cloudflarestorage.com'
    self._bucket = bucket
    self._access_key_id = access_key_id
    self._secret = secret
    self._region = 'auto'
    self._service = 's3'

  def _sign(self, method, raw_path, query_pairs, payload_hash):
    now = datetime.datetime.now(datetime.timezone.utc)
    amzdate = now.strftime('%Y%m%dT%H%M%SZ')
    datestamp = amzdate[:8]
    path = urllib.parse.quote(raw_path, safe='/')
    query = '&'.join(
        f'{urllib.parse.quote(str(k), safe="")}={urllib.parse.quote(str(v), safe="")}'
        for k, v in sorted(query_pairs.items())
    )
    canonical_headers = (
        f'host:{self._host}\n'
        f'x-amz-content-sha256:{payload_hash}\n'
        f'x-amz-date:{amzdate}\n'
    )
    signed_headers = 'host;x-amz-content-sha256;x-amz-date'
    canonical_request = (
        f'{method}\n{path}\n{query}\n{canonical_headers}\n'
        f'{signed_headers}\n{payload_hash}'
    )
    scope = f'{datestamp}/{self._region}/{self._service}/aws4_request'
    string_to_sign = (
        f'AWS4-HMAC-SHA256\n{amzdate}\n{scope}\n'
        f'{hashlib.sha256(canonical_request.encode()).hexdigest()}'
    )
    key = hmac.new(('AWS4' + self._secret).encode(), datestamp.encode(),
                   hashlib.sha256).digest()
    for part in (self._region, self._service, 'aws4_request'):
      key = hmac.new(key, part.encode(), hashlib.sha256).digest()
    signature = hmac.new(key, string_to_sign.encode(),
                         hashlib.sha256).hexdigest()
    authorization = (
        f'AWS4-HMAC-SHA256 Credential={self._access_key_id}/{scope}, '
        f'SignedHeaders={signed_headers}, Signature={signature}'
    )
    return authorization, amzdate, path, query

  def _request(self, method, path, query_pairs, data, payload_hash,
               content_type=None, cache_control=None):
    last_error = None
    for attempt in range(MAX_TRIES):
      auth, amzdate, enc_path, query = self._sign(method, path, query_pairs,
                                                  payload_hash)
      url = f'https://{self._host}{enc_path}'
      if query:
        url = f'{url}?{query}'
      try:
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header('Authorization', auth)
        req.add_header('x-amz-date', amzdate)
        req.add_header('x-amz-content-sha256', payload_hash)
        if content_type:
          req.add_header('Content-Type', content_type)
        if cache_control:
          req.add_header('Cache-Control', cache_control)
        return urllib.request.urlopen(req, timeout=300)
      except urllib.error.HTTPError as e:
        body = e.read().decode(errors='replace')[:200]
        print(f'  HTTP {e.code}: {body}', file=sys.stderr)
        last_error = e
      except Exception as e:  # noqa: BLE001 - network flakiness
        print(f'  retry {attempt + 1}: {str(e)[:80]}', file=sys.stderr)
        last_error = e
      time.sleep(2)
    raise RuntimeError(f'retries exhausted: {last_error}')

  def put_object(self, key, data, content_type=None, cache_control=None):
    payload_hash = hashlib.sha256(data).hexdigest()
    object_path = f'/{self._bucket}/{key}'
    self._request('PUT', object_path, {}, data, payload_hash, content_type,
                  cache_control)
    print(f'PUT OK {key} ({len(data) // 1024} KB)')

  def upload(self, key, data, content_type=None, cache_control=None):
    if len(data) <= MULTIPART_THRESHOLD:
      self.put_object(key, data, content_type, cache_control)
      return

    object_path = f'/{self._bucket}/{key}'
    empty_hash = hashlib.sha256(b'').hexdigest()
    r = self._request('POST', object_path, {'uploads': ''}, b'', empty_hash,
                      content_type, cache_control)
    upload_id = r.read().decode().split('<UploadId>')[1].split('</UploadId>')[0]

    total = len(data)
    nparts = (total + PART_SIZE - 1) // PART_SIZE
    parts = []
    for i in range(nparts):
      chunk = data[i * PART_SIZE:(i + 1) * PART_SIZE]
      part_number = i + 1
      chunk_hash = hashlib.sha256(chunk).hexdigest()
      r = self._request(
          'PUT', object_path,
          {'partNumber': str(part_number), 'uploadId': upload_id},
          chunk, chunk_hash)
      etag = r.headers.get('ETag')
      parts.append(
          f'<Part><PartNumber>{part_number}</PartNumber>'
          f'<ETag>{etag}</ETag></Part>')
      print(f'  part {part_number}/{nparts} done '
            f'({len(chunk) // 1024 // 1024} MB)')

    body = (f'<CompleteMultipartUpload>{"".join(parts)}'
            f'</CompleteMultipartUpload>').encode()
    body_hash = hashlib.sha256(body).hexdigest()
    r = self._request('POST', object_path, {'uploadId': upload_id}, body,
                      body_hash)
    resp = r.read().decode()
    if '<Error>' in resp:
      raise RuntimeError(f'complete failed: {resp[:300]}')
    print(f'UPLOAD OK {key} ({total // 1024 // 1024} MB, {nparts} parts)')


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--account-id', required=True)
  parser.add_argument('--bucket', default='gxu-apk')
  parser.add_argument('--token-id', required=True,
                      help='API token UUID (32 hex chars), used as Access Key ID')
  parser.add_argument('--token-value', required=True,
                      help='API token value (cfut_...); secret is sha256 of it')
  parser.add_argument('--key', required=True,
                      help='object key, e.g. releases/v1.0.7+51/app-arm64-v8a-release.apk')
  parser.add_argument('--file', required=True)
  parser.add_argument('--content-type', default=None)
  parser.add_argument('--cache-control', default=None)
  args = parser.parse_args()

  secret = hashlib.sha256(args.token_value.encode()).hexdigest()
  client = R2Client(args.account_id, args.token_id, secret, args.bucket)
  data = open(args.file, 'rb').read()
  client.upload(args.key, data, args.content_type, args.cache_control)


if __name__ == '__main__':
  main()
