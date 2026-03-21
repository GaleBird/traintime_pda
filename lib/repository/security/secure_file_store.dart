// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/security/app_secure_storage.dart';

const _secureFileFormat = 'secure_file_v1';
const _secureFileKeyStorageKey = 'security:secure_file_master_key';
const _secureFileKeyLength = 32;
const _secureFileNonceLength = 12;
const _secureFileMacBits = 128;

final Random _secureFileRandom = Random.secure();
Uint8List? _secureFileMasterKey;

Future<void> initializeSecureFileStore() async {
  if (_secureFileMasterKey != null) {
    return;
  }
  final stored = await appSecureStorage.read(key: _secureFileKeyStorageKey);
  if (stored != null && stored.isNotEmpty) {
    final decoded = base64Decode(stored);
    if (decoded.length != _secureFileKeyLength) {
      throw const FormatException('Secure file master key is corrupted.');
    }
    _secureFileMasterKey = Uint8List.fromList(decoded);
    return;
  }
  final generated = Uint8List.fromList(
    List<int>.generate(
      _secureFileKeyLength,
      (_) => _secureFileRandom.nextInt(256),
      growable: false,
    ),
  );
  await appSecureStorage.write(
    key: _secureFileKeyStorageKey,
    value: base64Encode(generated),
  );
  _secureFileMasterKey = generated;
}

void resetSecureFileStore() {
  _secureFileMasterKey = null;
}

class SecureFileStore {
  const SecureFileStore({required this.file, required this.namespace});

  final File file;
  final String namespace;

  String? readAsStringSync({bool migrateLegacy = true}) {
    if (!file.existsSync()) {
      return null;
    }
    final raw = file.readAsStringSync();
    final encrypted = _tryDecrypt(raw);
    if (encrypted != null) {
      return encrypted;
    }
    if (migrateLegacy) {
      writeAsStringSync(raw);
      log.info(
        '[SecureFileStore] Migrated legacy plaintext cache: ${path.basename(file.path)}',
      );
    }
    return raw;
  }

  Future<String?> readAsString({bool migrateLegacy = true}) async {
    if (!file.existsSync()) {
      return null;
    }
    final raw = await file.readAsString();
    final encrypted = _tryDecrypt(raw);
    if (encrypted != null) {
      return encrypted;
    }
    if (migrateLegacy) {
      await writeAsString(raw);
      log.info(
        '[SecureFileStore] Migrated legacy plaintext cache: ${path.basename(file.path)}',
      );
    }
    return raw;
  }

  void writeAsStringSync(String value) {
    _ensureInitialized();
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_encrypt(value));
  }

  Future<void> writeAsString(String value) async {
    _ensureInitialized();
    await file.parent.create(recursive: true);
    await file.writeAsString(_encrypt(value));
  }

  Future<void> delete() async {
    if (!file.existsSync()) {
      return;
    }
    await file.delete();
  }

  String _encrypt(String value) {
    final nonce = _randomBytes(_secureFileNonceLength);
    final cipher = GCMBlockCipher(AESEngine());
    final parameters = AEADParameters<KeyParameter>(
      KeyParameter(_masterKey()),
      _secureFileMacBits,
      nonce,
      _aad(),
    );
    cipher.init(true, parameters);
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(value)));
    return jsonEncode({
      'format': _secureFileFormat,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(encrypted),
    });
  }

  String? _tryDecrypt(String raw) {
    final envelope = _parseEnvelope(raw);
    if (envelope == null) {
      return null;
    }
    try {
      final nonce = base64Decode(envelope['nonce']!);
      final ciphertext = base64Decode(envelope['ciphertext']!);
      final cipher = GCMBlockCipher(AESEngine());
      final parameters = AEADParameters<KeyParameter>(
        KeyParameter(_masterKey()),
        _secureFileMacBits,
        nonce,
        _aad(),
      );
      cipher.init(false, parameters);
      final plaintext = cipher.process(Uint8List.fromList(ciphertext));
      return utf8.decode(plaintext);
    } on FormatException {
      rethrow;
    } on InvalidCipherTextException {
      throw const FormatException(
        'Secure cache payload authentication failed.',
      );
    } catch (_) {
      throw const FormatException('Secure cache payload is corrupted.');
    }
  }

  Map<String, String>? _parseEnvelope(String raw) {
    final trimmed = raw.trimLeft();
    if (!trimmed.startsWith('{')) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    if (map['format'] != _secureFileFormat) {
      return null;
    }
    final nonce = map['nonce'];
    final ciphertext = map['ciphertext'];
    if (nonce is! String || ciphertext is! String) {
      throw const FormatException('Secure cache payload is corrupted.');
    }
    return {'nonce': nonce, 'ciphertext': ciphertext};
  }

  Uint8List _aad() {
    final aad = '$namespace|${path.basename(file.path)}';
    return Uint8List.fromList(utf8.encode(aad));
  }

  void _ensureInitialized() {
    if (_secureFileMasterKey != null) {
      return;
    }
    throw StateError('SecureFileStore used before initialization.');
  }

  Uint8List _masterKey() {
    final key = _secureFileMasterKey;
    if (key == null) {
      throw StateError('SecureFileStore used before initialization.');
    }
    return key;
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(
        length,
        (_) => _secureFileRandom.nextInt(256),
        growable: false,
      ),
    );
  }
}
