// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_session.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart' as repo_general;
import 'package:watermeter/repository/notification/notification_registrar.dart';
import 'package:watermeter/repository/preference.dart' as preference;

Future<void> initializeAppBootstrap() async {
  repo_general.supportPath = await getApplicationSupportDirectory();
  await _initializePreferences();
  await _ensureGxuMode();
  preference.packageInfo = await PackageInfo.fromPlatform();
}

Future<void> _initializePreferences() async {
  const sharedPreferencesOptions = SharedPreferencesOptions();
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getKeys().isNotEmpty) {
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: prefs,
      sharedPreferencesAsyncOptions: sharedPreferencesOptions,
      migrationCompletedKey: 'pdaMigrationCompleted',
    );
  }
  preference.prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
}

Future<void> _ensureGxuMode() async {
  if (preference.getBool(preference.Preference.isGxuMode)) {
    return;
  }
  await preference.setBool(preference.Preference.isGxuMode, true);
}

void warmUpAppAfterFirstFrame() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_warmUpApp());
  });
}

Future<void> _warmUpApp() async {
  await Future.wait([
    loadCachedGxuNetworkUsage(),
    _initializeNotificationServices(),
  ]);
}

Future<void> _initializeNotificationServices() async {
  try {
    await NotificationServiceRegistrar().initializeAllServices();
    final services = NotificationServiceRegistrar().getAllServices();
    await Future.wait(
      services.map((service) => service.handleAppLaunchFromNotification()),
    );
  } catch (error, stackTrace) {
    log.error('Failed to initialize notification services', error, stackTrace);
  }
}
