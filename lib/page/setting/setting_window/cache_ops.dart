// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:watermeter/repository/classtable_storage.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_selection_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_session.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/xidian_sport_session.dart';

const String gxuNetworkCacheName = 'GxuNetworkUsage.json';

class CookieClearResult {
  final List<String> failures;

  const CookieClearResult({required this.failures});

  bool get hasFailures => failures.isNotEmpty;

  String summary({int maxItems = 2}) {
    final visibleFailures = failures.take(maxItems).toList(growable: false);
    final remainingCount = failures.length - visibleFailures.length;
    final summaryText = visibleFailures.join('; ');
    if (remainingCount <= 0) {
      return summaryText;
    }
    return '$summaryText; +$remainingCount';
  }
}

Future<CookieClearResult> clearAllCookies() async {
  final failures = <String>[];
  await _clearCookieStore(
    label: 'general',
    action: () => NetworkSession().clearCookieJar(),
    failures: failures,
  );
  await _clearCookieStore(
    label: 'gxu',
    action: () => GxuCASession().clearCookieJar(),
    failures: failures,
  );
  await _clearCookieStore(
    label: 'gxuNetwork',
    action: () => GxuNetworkSession().clearCookieJar(),
    failures: failures,
  );
  await _clearCookieStore(
    label: 'sport',
    action: () => SportSession().sportCookieJar.deleteAll(),
    failures: failures,
  );
  return CookieClearResult(failures: failures);
}

void removeCacheFiles() {
  _removeFiles([
    ClasstableStorage.schoolClassName,
    GxuScoreSession.scoreListCacheName,
    GxuCourseSelectionSession.courseSelectionCacheName,
    gxuNetworkCacheName,
  ]);
  resetGxuNetworkRuntimeState();
}

void removeAllFiles() {
  _removeFiles([
    ClasstableStorage.schoolClassName,
    ClasstableStorage.userDefinedClassName,
    ClasstableStorage.decorationName,
    GxuScoreSession.scoreListCacheName,
    GxuCourseSelectionSession.courseSelectionCacheName,
    gxuNetworkCacheName,
  ]);
  resetGxuNetworkRuntimeState();
}

void _removeFiles(List<String> names) {
  for (final name in names) {
    final file = File('${supportPath.path}/$name');
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

Future<void> _clearCookieStore({
  required String label,
  required Future<void> Function() action,
  required List<String> failures,
}) async {
  try {
    await action();
  } catch (e, s) {
    log.warning('[setting][clearCookies] $label failed', e, s);
    failures.add('$label: $e');
  }
}
