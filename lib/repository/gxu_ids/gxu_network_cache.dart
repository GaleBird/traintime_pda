// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';

const _gxuNetworkCacheName = "GxuNetworkUsage.json";

File _cacheFile() => File("${supportPath.path}/$_gxuNetworkCacheName");

Future<GxuNetworkUsage?> loadGxuNetworkUsageCache() async {
  final file = _cacheFile();
  if (!file.existsSync()) {
    return null;
  }

  try {
    final raw = await file.readAsString();
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
    await _cacheFile().writeAsString(jsonEncode(usage.toJson()));
  } catch (error, stackTrace) {
    log.warning(
      "[GxuNetworkCache] Failed to save network usage cache.",
      error,
      stackTrace,
    );
  }
}
