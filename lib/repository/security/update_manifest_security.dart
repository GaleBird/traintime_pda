// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:watermeter/repository/fork_info.dart';

const _manifestSignatureAlgorithm = 'RSA-SHA256';

Map<String, dynamic> validateAndStripUpdateManifestSignature(dynamic rawData) {
  final json = _asJsonMap(rawData);
  final signature = _parseSignature(json['signature']);
  final payload = Map<String, dynamic>.from(json)..remove('signature');
  final canonical = canonicalizeSignedJson(payload);
  final publicKey = RSAKeyParser().parse(ForkInfo.updateManifestPublicKey);
  if (publicKey is! RSAPublicKey) {
    throw const FormatException('Update manifest public key is invalid.');
  }
  final verifier = RSASigner(RSASignDigest.SHA256, publicKey: publicKey);
  final verified = verifier.verify(
    Uint8List.fromList(utf8.encode(canonical)),
    Encrypted(base64Decode(signature.value)),
  );
  if (!verified) {
    throw const FormatException(
      'Update manifest signature verification failed.',
    );
  }
  return payload;
}

String ensureTrustedUpdateUrl(
  String rawUrl, {
  required Set<String> allowedHosts,
  String? requiredPathPrefix,
}) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) {
    throw FormatException('Invalid update URL: $rawUrl');
  }
  if (uri.scheme != 'https') {
    throw FormatException('Update URL must use HTTPS: $rawUrl');
  }
  if (!allowedHosts.contains(uri.host)) {
    throw FormatException('Update URL host is not trusted: ${uri.host}');
  }
  if (requiredPathPrefix != null && !uri.path.startsWith(requiredPathPrefix)) {
    throw FormatException('Update URL path is not trusted: ${uri.path}');
  }
  return uri.toString();
}

String canonicalizeSignedJson(dynamic value) {
  if (value is Map) {
    final entries = value.entries.toList(growable: false)
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    final buffer = StringBuffer('{');
    for (var index = 0; index < entries.length; index++) {
      if (index > 0) {
        buffer.write(',');
      }
      buffer.write(jsonEncode(entries[index].key.toString()));
      buffer.write(':');
      buffer.write(canonicalizeSignedJson(entries[index].value));
    }
    buffer.write('}');
    return buffer.toString();
  }
  if (value is List) {
    final buffer = StringBuffer('[');
    for (var index = 0; index < value.length; index++) {
      if (index > 0) {
        buffer.write(',');
      }
      buffer.write(canonicalizeSignedJson(value[index]));
    }
    buffer.write(']');
    return buffer.toString();
  }
  return jsonEncode(value);
}

Map<String, dynamic> _asJsonMap(dynamic rawData) {
  if (rawData is Map<String, dynamic>) {
    return rawData;
  }
  if (rawData is Map) {
    return rawData.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Unexpected update manifest payload.');
}

_ManifestSignature _parseSignature(dynamic rawSignature) {
  final json = _asJsonMap(rawSignature);
  final algorithm = _readRequiredString(json, 'algorithm');
  if (algorithm != _manifestSignatureAlgorithm) {
    throw FormatException('Unsupported update signature algorithm: $algorithm');
  }
  final keyId = _readRequiredString(json, 'key_id');
  if (keyId != ForkInfo.updateManifestKeyId) {
    throw FormatException('Unexpected update signature key: $keyId');
  }
  return _ManifestSignature(value: _readRequiredString(json, 'value'));
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw FormatException('Update manifest field "$key" is missing.');
}

class _ManifestSignature {
  const _ManifestSignature({required this.value});

  final String value;
}
