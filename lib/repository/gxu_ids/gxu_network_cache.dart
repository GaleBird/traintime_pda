// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/security/secure_file_store.dart';

const _gxuNetworkCacheName = "GxuNetworkUsage.json";

File _cacheFile() => File("${supportPath.path}/$_gxuNetworkCacheName");
SecureFileStore _cacheStore() =>
    SecureFileStore(file: _cacheFile(), namespace: "gxu_network_usage");

Future<GxuNetworkUsage?> loadGxuNetworkUsageCache() async {
  final file = _cacheFile();
  if (!file.existsSync()) {
    return null;
  }

  try {
    final raw = await _cacheStore().readAsString();
    if (raw == null) {
      return null;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return GxuNetworkUsage.fromJson(json);
  } catch (error, stackTrace) {
    log.warning(
      "[GxuNetworkCache] Failed to load cached network usage.",
      error,
      stackTrace,
    );
    return null;
  }
}

Future<void> saveGxuNetworkUsageCache(GxuNetworkUsage usage) async {
  try {
    await _cacheStore().writeAsString(jsonEncode(usage.toJson()));
  } catch (error, stackTrace) {
    log.warning(
      "[GxuNetworkCache] Failed to save network usage cache.",
      error,
      stackTrace,
    );
  }
}
