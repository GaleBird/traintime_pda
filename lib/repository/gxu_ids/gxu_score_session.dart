import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/security/secure_file_store.dart';

class GxuScoreSession {
  static const _scorePagePath = "/cp/templateList/p/up_016_014";
  static const _portalPagePath = "/view?m=up";
  static const _scoreWarmUpAttempts = 2;
  static const _scoreWarmUpRetryDelay = Duration(milliseconds: 250);
  static const scoreListCacheName = "gxu_scores.json";
  static final File file = File("${supportPath.path}/$scoreListCacheName");
  static final SecureFileStore _cacheStore = SecureFileStore(
    file: file,
    namespace: "gxu_score",
  );
  static bool isScoreListCacheUsed = false;

  final GxuCASession caSession;

  GxuScoreSession({GxuCASession? caSession})
    : caSession = caSession ?? GxuCASession();

  static bool get isCacheExist => file.existsSync();

  Future<GxuScoreSheet> getScoreSheet({bool force = false}) async {
    final cache = _loadCache();
    if (!force && cache != null && _isCacheFresh()) {
      isScoreListCacheUsed = true;
      return cache;
    }
    try {
      final sheet = await _fetchRemote();
      _dumpCache(sheet);
      isScoreListCacheUsed = false;
      return sheet;
    } catch (e) {
      if (cache != null) {
        log.warning(
          "[GxuScoreSession] Load remote score failed, fallback to cache: $e",
        );
        isScoreListCacheUsed = true;
        return cache;
      }
      isScoreListCacheUsed = false;
      rethrow;
    }
  }

  GxuScoreSheet? _loadCache() {
    final rawText = _cacheStore.readAsStringSync();
    if (rawText == null) {
      return null;
    }
    final raw = jsonDecode(rawText);
    if (raw is! Map) {
      throw const LoginFailedException(msg: "广西大学成绩缓存已损坏。");
    }
    return GxuScoreSheet.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  bool _isCacheFresh() {
    if (!file.existsSync()) {
      return false;
    }
    return DateTime.now().difference(file.lastModifiedSync()).inMinutes < 15;
  }

  void _dumpCache(GxuScoreSheet sheet) {
    _cacheStore.writeAsStringSync(jsonEncode(sheet.toJson()));
  }

  Future<GxuScoreSheet> _fetchRemote() async {
    await caSession.ensureYjsxtLoggedIn(
      username: preference.getString(preference.Preference.idsAccount),
      password: preference.getString(preference.Preference.idsPassword),
    );
    await _prepareScoreModule();
    final canPreview = await _checkPrintableScoreSheet();
    if (!canPreview) {
      throw const LoginFailedException(msg: "培养评价未完成，研究生成绩单暂时不可查询。");
    }
    final response = await _postScoreRequest(
      "${GxuCASession.yjsxtBase}/yjs/py/cjgl/cjdpldy/getCjddyyl",
      data: {"xh": "", "lx": ""},
    );
    final data = _decodeMap(response.data, "成绩单预览");
    return GxuScoreSheet.fromPreviewJson(data);
  }

  Future<void> _prepareScoreModule() async {
    for (var attempt = 1; attempt <= _scoreWarmUpAttempts; attempt++) {
      await _openScorePage();
      final data = await _warmUpScoreModule();
      if (_isWarmUpSuccess(data)) {
        return;
      }
      if (attempt == _scoreWarmUpAttempts) {
        throw LoginFailedException(msg: _scoreWarmUpErrorMessage(data));
      }
      log.warning(
        "[GxuScoreSession] Score module warm-up returned unsuccessful payload on attempt $attempt: $data",
      );
      await Future<void>.delayed(_scoreWarmUpRetryDelay);
    }
  }

  Future<Map<String, dynamic>> _warmUpScoreModule() async {
    final response = await _postScoreRequest(
      "${GxuCASession.yjsxtBase}/yjs/py/kcpj/loadJxzlpj",
      data: <String, dynamic>{},
    );
    return _decodeMap(response.data, "成绩模块初始化");
  }

  Future<bool> _checkPrintableScoreSheet() async {
    final response = await _postScoreRequest(
      "${GxuCASession.yjsxtBase}/yjs/py/cjgl/cjdpldy/checkdDycjd",
      data: <String, dynamic>{},
    );
    final result = response.data.toString().replaceAll('"', "").trim();
    return result == "1";
  }

  bool _isWarmUpSuccess(Map<String, dynamic> data) {
    return data["success"] == true || data["code"]?.toString() == "200";
  }

  String _scoreWarmUpErrorMessage(Map<String, dynamic> data) {
    final remoteMessage = _extractRemoteMessage(data);
    if (remoteMessage.isEmpty) {
      return "广西大学成绩模块初始化失败。";
    }
    return "广西大学成绩模块初始化失败：$remoteMessage";
  }

  String _extractRemoteMessage(Map<String, dynamic> data) {
    for (final key in ["msg", "message", "errorMsg", "error", "reason"]) {
      final value = data[key]?.toString().trim() ?? "";
      if (value.isNotEmpty && value != "null") {
        return value;
      }
    }
    return "";
  }

  Future<void> _openScorePage() async {
    await caSession.dio.get(
      "${GxuCASession.yjsxtBase}$_scorePagePath",
      options: _pageOptions(),
    );
  }

  Map<String, dynamic> _decodeMap(dynamic data, String scene) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    throw LoginFailedException(msg: "广西大学$scene接口返回异常。");
  }

  Future<Response<dynamic>> _postScoreRequest(
    String path, {
    required Map<String, dynamic> data,
  }) {
    return caSession.dio.post(path, data: data, options: _ajaxOptions());
  }

  Options _pageOptions() {
    return Options(
      headers: {
        HttpHeaders.refererHeader: "${GxuCASession.yjsxtBase}$_portalPagePath",
      },
    );
  }

  Options _ajaxOptions() {
    return Options(
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Origin": "https://yjsxt.gxu.edu.cn",
        "Referer": "${GxuCASession.yjsxtBase}$_scorePagePath",
      },
    );
  }
}
