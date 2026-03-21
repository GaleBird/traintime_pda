// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:synchronized/synchronized.dart';
import 'package:watermeter/model/pda_service/message.dart';
import 'package:watermeter/repository/fork_info.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/preference.dart' as pref;

enum UpdateCheckResult { available, latest, localAhead, noRelease, failed }

Rxn<UpdateMessage> updateMessage = Rxn<UpdateMessage>(null);
Rxn<UpdateCheckResult> updateResult = Rxn<UpdateCheckResult>(null);
RxBool updateState = false.obs;
Rxn<Object> updateError = Rxn<Object>(null);

Dio get dio => Dio()..interceptors.add(logDioAdapter);
final updateLock = Lock(reentrant: false);

Future<UpdateCheckResult> checkUpdate() {
  return updateLock.synchronized(() async {
    _startUpdateCheck();
    try {
      final response = await dio.get(ForkInfo.updateManifestUrl);
      final message = await _buildUpdateMessage(response.data);
      updateMessage.value = message;
      updateError.value = null;
      updateResult.value = _compareWithLocalVersion(message.code);
      return updateResult.value!;
    } on DioException catch (e, s) {
      log.warning('[update][checkUpdate] failed', e, s);
      updateMessage.value = null;
      if (e.response?.statusCode == HttpStatus.notFound) {
        updateError.value = null;
        updateResult.value = UpdateCheckResult.noRelease;
        return updateResult.value!;
      }
      updateError.value = e;
      updateResult.value = UpdateCheckResult.failed;
      return updateResult.value!;
    } catch (e, s) {
      log.warning('[update][checkUpdate] failed', e, s);
      updateMessage.value = null;
      updateError.value = e;
      updateResult.value = UpdateCheckResult.failed;
      return updateResult.value!;
    } finally {
      updateState.value = false;
    }
  });
}

void _startUpdateCheck() {
  updateMessage.value = null;
  updateResult.value = null;
  updateError.value = null;
  updateState.value = true;
}

Future<UpdateMessage> _buildUpdateMessage(dynamic rawData) async {
  final json = _asJsonMap(rawData);
  final releaseUrl = _readString(
    json,
    'html_url',
    fallback: ForkInfo.releasePageUrl,
  );
  final androidUrl = await _pickAndroidDownloadUrl(json['assets'], releaseUrl);
  return UpdateMessage(
    code: _normalizeVersionTag(_readString(json, 'tag_name')),
    update: _parseReleaseNotes(_readString(json, 'body')),
    ioslink: releaseUrl,
    github: releaseUrl,
    fdroid: androidUrl,
  );
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

String _readString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

String _normalizeVersionTag(String rawTag) {
  final match = RegExp(r'(\d+(?:\.\d+)*)(?:\+(\d+))?').firstMatch(rawTag);
  if (match == null) {
    throw FormatException('Unsupported release tag: $rawTag');
  }
  final version = match.group(1)!;
  final build = match.group(2);
  if (build == null) {
    return version;
  }
  return '$version+$build';
}

List<String> _parseReleaseNotes(String body) {
  return body
      .split('\n')
      .map(_cleanReleaseLine)
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _cleanReleaseLine(String line) {
  var text = line.trim();
  if (text == '---') {
    return '';
  }
  text = text.replaceFirst(RegExp(r'^#+\s*'), '');
  text = text.replaceFirst(RegExp(r'^[-*]\s*'), '');
  text = text.replaceFirst(RegExp(r'^\d+\.\s*'), '');
  return text.trim();
}

Future<String> _pickAndroidDownloadUrl(
  dynamic rawAssets,
  String fallbackUrl,
) async {
  final apkAssets = _parseAssets(
    rawAssets,
  ).where((asset) => asset.name.endsWith('.apk')).toList(growable: false);
  if (apkAssets.isEmpty) {
    return fallbackUrl;
  }
  final preferredKeywords = await _preferredAndroidAssetKeywords();
  final preferred = _findPreferredAsset(apkAssets, preferredKeywords);
  return preferred?.downloadUrl ?? apkAssets.first.downloadUrl;
}

List<_ReleaseAsset> _parseAssets(dynamic rawAssets) {
  if (rawAssets is! List) {
    return const [];
  }
  final assets = <_ReleaseAsset>[];
  for (final item in rawAssets) {
    final json = _asJsonMap(item);
    final name = _readString(json, 'name').toLowerCase();
    final url = _readString(json, 'browser_download_url');
    if (name.isEmpty || url.isEmpty) {
      continue;
    }
    assets.add(_ReleaseAsset(name: name, downloadUrl: url));
  }
  return assets;
}

Future<List<String>> _preferredAndroidAssetKeywords() async {
  const fallback = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
  if (!Platform.isAndroid) {
    return fallback;
  }
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    final detected = info.supportedAbis
        .map(_abiToAssetKeyword)
        .whereType<String>()
        .toList(growable: false);
    return [...detected, ...fallback.where((item) => !detected.contains(item))];
  } catch (e, s) {
    log.warning('[update][abiDetect] failed', e, s);
    return fallback;
  }
}

String? _abiToAssetKeyword(String abi) {
  final normalized = abi.toLowerCase();
  if (normalized.contains('arm64')) {
    return 'arm64-v8a';
  }
  if (normalized.contains('armeabi') || normalized.contains('armv7')) {
    return 'armeabi-v7a';
  }
  if (normalized.contains('x86_64')) {
    return 'x86_64';
  }
  if (normalized == 'x86') {
    return 'x86';
  }
  return null;
}

_ReleaseAsset? _findPreferredAsset(
  List<_ReleaseAsset> assets,
  List<String> keywords,
) {
  for (final keyword in keywords) {
    for (final asset in assets) {
      if (asset.name.contains(keyword)) {
        return asset;
      }
    }
  }
  return null;
}

UpdateCheckResult _compareWithLocalVersion(String remoteCode) {
  final localVersion = _AppVersion.parse(
    '${pref.packageInfo.version}+${pref.packageInfo.buildNumber}',
  );
  final remoteVersion = _AppVersion.parse(remoteCode);
  final partComparison = _compareVersionParts(
    remoteVersion.parts,
    localVersion.parts,
  );
  if (partComparison > 0) {
    return UpdateCheckResult.available;
  }
  if (partComparison < 0) {
    return UpdateCheckResult.localAhead;
  }
  if (!remoteVersion.hasBuildNumber) {
    return UpdateCheckResult.latest;
  }
  if (remoteVersion.build > localVersion.build) {
    return UpdateCheckResult.available;
  }
  if (remoteVersion.build < localVersion.build) {
    return UpdateCheckResult.localAhead;
  }
  return UpdateCheckResult.latest;
}

int _compareVersionParts(List<int> remote, List<int> local) {
  for (int i = 0; i < math.max(remote.length, local.length); i++) {
    final remotePart = i < remote.length ? remote[i] : 0;
    final localPart = i < local.length ? local[i] : 0;
    if (remotePart == localPart) {
      continue;
    }
    return remotePart.compareTo(localPart);
  }
  return 0;
}

class _ReleaseAsset {
  const _ReleaseAsset({required this.name, required this.downloadUrl});

  final String name;
  final String downloadUrl;
}

class _AppVersion {
  const _AppVersion({
    required this.parts,
    required this.build,
    required this.hasBuildNumber,
  });

  final List<int> parts;
  final int build;
  final bool hasBuildNumber;

  factory _AppVersion.parse(String rawVersion) {
    final match = RegExp(r'(\d+(?:\.\d+)*)(?:\+(\d+))?').firstMatch(rawVersion);
    if (match == null) {
      throw FormatException('Unsupported version: $rawVersion');
    }
    return _AppVersion(
      parts: match.group(1)!.split('.').map(int.parse).toList(growable: false),
      build: int.tryParse(match.group(2) ?? '') ?? 0,
      hasBuildNumber: match.group(2) != null,
    );
  }
}
