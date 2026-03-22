#!/usr/bin/env python3

import argparse
import base64
import hashlib
import json
from pathlib import Path

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

HASH_CHUNK_SIZE = 1024 * 1024


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser()
  parser.add_argument("--tag", required=True)
  parser.add_argument("--release-url", required=True)
  parser.add_argument("--cdn-base-url", required=True)
  parser.add_argument("--body-file", required=True)
  parser.add_argument("--output", required=True)
  parser.add_argument("--signing-key", required=True)
  parser.add_argument("--key-id", required=True)
  parser.add_argument("--asset-path", action="append", required=True)
  return parser.parse_args()


def build_manifest_payload(args: argparse.Namespace) -> dict:
  if not args.cdn_base_url.strip():
    raise ValueError("cdn-base-url must not be empty")
  if not args.key_id.strip():
    raise ValueError("key-id must not be empty")
  body = Path(args.body_file).read_text(encoding="utf-8")
  cdn_base_url = args.cdn_base_url.rstrip("/")
  tag = args.tag.strip()
  assets = []
  for asset_path in args.asset_path:
    asset_file = Path(asset_path)
    asset_name = asset_file.name
    if not asset_name:
      raise ValueError("asset-path must point to a file")
    sha256 = hashlib.sha256()
    with asset_file.open("rb") as f:
      for chunk in iter(lambda: f.read(HASH_CHUNK_SIZE), b""):
        sha256.update(chunk)
    assets.append({
      "name": asset_name,
      "browser_download_url": f"{cdn_base_url}/releases/{tag}/{asset_name}",
      "size": asset_file.stat().st_size,
      "sha256": sha256.hexdigest(),
    })
  return {
    "tag_name": tag,
    "html_url": args.release_url.strip(),
    "body": body,
    "assets": assets,
  }


def canonicalize(value) -> str:
  return json.dumps(
    value,
    ensure_ascii=False,
    separators=(",", ":"),
    sort_keys=True,
  )


def sign_payload(payload: dict, args: argparse.Namespace) -> dict:
  private_key_bytes = Path(args.signing_key).read_bytes()
  private_key = serialization.load_pem_private_key(
    private_key_bytes,
    password=None,
  )
  signature = private_key.sign(
    canonicalize(payload).encode("utf-8"),
    padding.PKCS1v15(),
    hashes.SHA256(),
  )
  return {
    "algorithm": "RSA-SHA256",
    "key_id": args.key_id.strip(),
    "value": base64.b64encode(signature).decode("ascii"),
  }


def main() -> None:
  args = parse_args()
  payload = build_manifest_payload(args)
  manifest = {
    **payload,
    "signature": sign_payload(payload, args),
  }
  output_path = Path(args.output)
  output_path.parent.mkdir(parents=True, exist_ok=True)
  output_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
  )


if __name__ == "__main__":
  main()
