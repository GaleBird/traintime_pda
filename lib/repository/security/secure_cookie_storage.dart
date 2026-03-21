// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path/path.dart' as path;
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/security/app_secure_storage.dart';

class SecureCookieStorage implements Storage {
  SecureCookieStorage({required this.namespace, required this.legacyDir});

  final String namespace;
  final String legacyDir;

  late final String _storagePrefix;
  late final String _legacyDirectory;
  bool _initialized = false;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    if (_initialized) {
      return;
    }
    _storagePrefix = _buildStoragePrefix(
      namespace: namespace,
      persistSession: persistSession,
      ignoreExpires: ignoreExpires,
    );
    _legacyDirectory = _buildLegacyDirectory(
      legacyDir: legacyDir,
      persistSession: persistSession,
      ignoreExpires: ignoreExpires,
    );
    await _migrateLegacyCookies();
    _initialized = true;
  }

  @override
  Future<String?> read(String key) async {
    _ensureInitialized();
    return appSecureStorage.read(key: _storageKey(key));
  }

  @override
  Future<void> write(String key, String value) async {
    _ensureInitialized();
    await appSecureStorage.write(key: _storageKey(key), value: value);
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();
    await appSecureStorage.delete(key: _storageKey(key));
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    _ensureInitialized();
    final all = await appSecureStorage.readAll();
    final targets = all.keys
        .where((key) => key.startsWith(_storagePrefix))
        .toList(growable: false);
    for (final key in targets) {
      await appSecureStorage.delete(key: key);
    }
    final legacy = Directory(_legacyDirectory);
    if (legacy.existsSync()) {
      await legacy.delete(recursive: true);
    }
  }

  void _ensureInitialized() {
    if (_initialized) {
      return;
    }
    throw StateError('SecureCookieStorage used before initialization.');
  }

  String _storageKey(String key) => '$_storagePrefix$key';

  Future<void> _migrateLegacyCookies() async {
    final legacy = Directory(_legacyDirectory);
    if (!legacy.existsSync()) {
      return;
    }

    final all = await appSecureStorage.readAll();
    final hasSecureCookies = all.keys.any(
      (key) => key.startsWith(_storagePrefix),
    );
    if (hasSecureCookies) {
      await legacy.delete(recursive: true);
      return;
    }

    try {
      final files = legacy
          .listSync(recursive: true)
          .whereType<File>()
          .toList(growable: false);
      for (final file in files) {
        final relativePath = path
            .relative(file.path, from: legacy.path)
            .replaceAll('\\', '/');
        if (relativePath.isEmpty) {
          continue;
        }
        final value = await file.readAsString();
        await appSecureStorage.write(
          key: _storageKey(relativePath),
          value: value,
        );
      }
      await legacy.delete(recursive: true);
    } catch (error, stackTrace) {
      log.warning(
        '[SecureCookieStorage] Failed to migrate legacy cookies for $namespace.',
        error,
        stackTrace,
      );
      if (legacy.existsSync()) {
        await legacy.delete(recursive: true);
      }
    }
  }

  String _buildStoragePrefix({
    required String namespace,
    required bool persistSession,
    required bool ignoreExpires,
  }) {
    return 'cookie:$namespace:ie${ignoreExpires ? 1 : 0}:ps${persistSession ? 1 : 0}:';
  }

  String _buildLegacyDirectory({
    required String legacyDir,
    required bool persistSession,
    required bool ignoreExpires,
  }) {
    var base = legacyDir.replaceAll('\\', '/');
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    return '${base}ie${ignoreExpires ? 1 : 0}_ps${persistSession ? 1 : 0}/';
  }
}
