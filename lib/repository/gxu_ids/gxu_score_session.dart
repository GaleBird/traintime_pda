import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_exceptions.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/security/corrupted_cache_recovery.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/security/secure_file_store.dart';

export 'package:watermeter/repository/gxu_ids/gxu_score_exceptions.dart';

abstract class GxuScoreRemoteSource {
  Future<void> prepareScoreModule();
  Future<bool> checkPrintableScoreSheet();
  Future<Map<String, dynamic>> fetchScorePreview();
}

abstract class GxuScoreCache {
  GxuScoreSheet? load();
  bool isFresh();
  void dump(GxuScoreSheet sheet);
}

class GxuScoreAutoEvaluationResult {
  final GxuScoreSheet sheet;
  final GxuCourseEvaluationReport report;
  final String? refreshNote;

  const GxuScoreAutoEvaluationResult({
    required this.sheet,
    required this.report,
    this.refreshNote,
  });
}

class GxuScoreSession {
  static const _scorePagePath = '/cp/templateList/p/up_016_014';
  static const _portalPagePath = '/view?m=up';
  static const scoreListCacheName = 'gxu_scores.json';
  static final File file = File('${supportPath.path}/$scoreListCacheName');
  static final SecureFileStore _cacheStore = SecureFileStore(
    file: file,
    namespace: 'gxu_score',
  );
  static bool isScoreListCacheUsed = false;

  final GxuScoreRemoteSource remoteSource;
  final GxuAutoCourseEvaluator autoEvaluator;
  final GxuScoreCache cache;

  factory GxuScoreSession({
    GxuCASession? caSession,
    GxuScoreRemoteSource? remoteSource,
    GxuAutoCourseEvaluator? autoEvaluator,
    GxuScoreCache? cache,
  }) {
    final needsCaSession = remoteSource == null || autoEvaluator == null;
    final resolvedCaSession = needsCaSession
        ? caSession ?? GxuCASession()
        : caSession;
    return GxuScoreSession._(
      remoteSource:
          remoteSource ?? _DioGxuScoreRemoteSource(resolvedCaSession!),
      autoEvaluator:
          autoEvaluator ??
          GxuCourseEvaluationSession(caSession: resolvedCaSession!),
      cache: cache ?? GxuScoreFileCache(),
    );
  }

  const GxuScoreSession._({
    required this.remoteSource,
    required this.autoEvaluator,
    required this.cache,
  });

  static bool get isCacheExist => file.existsSync();

  Future<GxuScoreSheet> getScoreSheet({bool force = false}) async {
    final cachedSheet = cache.load();
    if (!force && cachedSheet != null && cache.isFresh()) {
      isScoreListCacheUsed = true;
      return cachedSheet;
    }
    try {
      final sheet = await _fetchRemote(allowAutoEvaluation: false);
      cache.dump(sheet);
      isScoreListCacheUsed = false;
      return sheet;
    } catch (e) {
      if (e is GxuScoreEvaluationRequiredException) {
        isScoreListCacheUsed = false;
        rethrow;
      }
      if (cachedSheet != null) {
        log.warning(
          '[GxuScoreSession] Load remote score failed, fallback to cache: $e',
        );
        isScoreListCacheUsed = true;
        return cachedSheet;
      }
      isScoreListCacheUsed = false;
      rethrow;
    }
  }

  Future<GxuScoreSheet> autoEvaluateAndGetScoreSheet() async {
    final result = await autoEvaluateAndFetchScoreSheet();
    return result.sheet;
  }

  Future<GxuScoreAutoEvaluationResult> autoEvaluateAndFetchScoreSheet({
    void Function(GxuCourseEvaluationReport report)? onEvaluationReport,
  }) async {
    final result = await _evaluateThenFetchRemote(
      onEvaluationReport: onEvaluationReport,
    );
    cache.dump(result.sheet);
    isScoreListCacheUsed = false;
    return result;
  }

  Future<GxuScoreSheet> _fetchRemote({
    required bool allowAutoEvaluation,
  }) async {
    await remoteSource.prepareScoreModule();
    if (!await remoteSource.checkPrintableScoreSheet()) {
      if (!allowAutoEvaluation) {
        throw const GxuScoreEvaluationRequiredException();
      }
      await autoEvaluator.autoEvaluateRequiredCourses();
      if (!await remoteSource.checkPrintableScoreSheet()) {
        throw const GxuScoreEvaluationRequiredException();
      }
    }
    final data = await remoteSource.fetchScorePreview();
    return GxuScoreSheet.fromPreviewJson(data);
  }

  Future<GxuScoreAutoEvaluationResult> _evaluateThenFetchRemote({
    void Function(GxuCourseEvaluationReport report)? onEvaluationReport,
  }) async {
    final report = await autoEvaluator.autoEvaluateRequiredCourses();
    onEvaluationReport?.call(report);
    try {
      if (!await remoteSource.checkPrintableScoreSheet()) {
        throw const GxuScoreEvaluationRequiredException();
      }
      return await _fetchPrintableScoreAfterEvaluation(report);
    } catch (e) {
      if (e is GxuScoreEvaluationRequiredException) {
        rethrow;
      }
      throw GxuScoreAutoEvaluationRefreshException(report: report, cause: e);
    }
  }

  Future<GxuScoreAutoEvaluationResult> _fetchPrintableScoreAfterEvaluation(
    GxuCourseEvaluationReport report,
  ) async {
    final refreshNote = await _warmUpScoreModuleAfterEvaluation();
    final data = await remoteSource.fetchScorePreview();
    return GxuScoreAutoEvaluationResult(
      sheet: GxuScoreSheet.fromPreviewJson(data),
      report: report,
      refreshNote: refreshNote,
    );
  }

  Future<String?> _warmUpScoreModuleAfterEvaluation() async {
    try {
      await remoteSource.prepareScoreModule();
      return null;
    } catch (e, s) {
      log.warning(
        '[GxuScoreSession] Score module warm-up failed after evaluation, trying direct score preview.',
        e,
        s,
      );
      return _directScorePreviewNote(e);
    }
  }
}

String _directScorePreviewNote(Object cause) =>
    '成绩模块初始化失败，已直接读取成绩单。原因：${_shortCauseMessage(cause)}';

String _shortCauseMessage(Object cause) {
  if (cause is LoginFailedException) {
    return cause.msg;
  }
  return cause.toString();
}

class GxuScoreFileCache implements GxuScoreCache {
  const GxuScoreFileCache();

  @override
  GxuScoreSheet? load() {
    return loadRecoverableCache(
      label: 'gxu_score',
      file: GxuScoreSession.file,
      readRawText: GxuScoreSession._cacheStore.readAsStringSync,
      decode: _decodeCache,
    );
  }

  @override
  bool isFresh() {
    if (!GxuScoreSession.file.existsSync()) {
      return false;
    }
    final cacheAge = DateTime.now().difference(
      GxuScoreSession.file.lastModifiedSync(),
    );
    return cacheAge.inMinutes < 15;
  }

  @override
  void dump(GxuScoreSheet sheet) {
    GxuScoreSession._cacheStore.writeAsStringSync(jsonEncode(sheet.toJson()));
  }

  GxuScoreSheet _decodeCache(String rawText) {
    final raw = jsonDecode(rawText);
    if (raw is! Map) {
      throw const FormatException('GXU score cache is corrupted.');
    }
    return GxuScoreSheet.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

class _DioGxuScoreRemoteSource implements GxuScoreRemoteSource {
  static const _scoreWarmUpAttempts = 2;
  static const _scoreWarmUpRetryDelay = Duration(milliseconds: 250);

  final GxuCASession caSession;

  const _DioGxuScoreRemoteSource(this.caSession);

  @override
  Future<void> prepareScoreModule() async {
    await caSession.ensureYjsxtLoggedIn(
      username: preference.getString(preference.Preference.idsAccount),
      password: preference.getString(preference.Preference.idsPassword),
    );
    await _prepareScoreModule();
  }

  @override
  Future<bool> checkPrintableScoreSheet() async {
    final response = await _postScoreRequest(
      '${GxuCASession.yjsxtBase}/yjs/py/cjgl/cjdpldy/checkdDycjd',
      data: <String, dynamic>{},
    );
    final result = response.data.toString().replaceAll('"', '').trim();
    return result == '1';
  }

  @override
  Future<Map<String, dynamic>> fetchScorePreview() async {
    final response = await _postScoreRequest(
      '${GxuCASession.yjsxtBase}/yjs/py/cjgl/cjdpldy/getCjddyyl',
      data: {'xh': '', 'lx': ''},
    );
    return _decodeMap(response.data, '成绩单预览');
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
        '[GxuScoreSession] Score module warm-up returned unsuccessful payload on attempt $attempt: $data',
      );
      await Future<void>.delayed(_scoreWarmUpRetryDelay);
    }
  }

  Future<Map<String, dynamic>> _warmUpScoreModule() async {
    final response = await _postScoreRequest(
      '${GxuCASession.yjsxtBase}/yjs/py/kcpj/loadJxzlpj',
      data: <String, dynamic>{},
    );
    return _decodeMap(response.data, '成绩模块初始化');
  }

  bool _isWarmUpSuccess(Map<String, dynamic> data) {
    return data['success'] == true || data['code']?.toString() == '200';
  }

  String _scoreWarmUpErrorMessage(Map<String, dynamic> data) {
    final remoteMessage = _extractRemoteMessage(data);
    if (remoteMessage.isEmpty) {
      return '广西大学成绩模块初始化失败。';
    }
    return '广西大学成绩模块初始化失败：$remoteMessage';
  }

  String _extractRemoteMessage(Map<String, dynamic> data) {
    for (final key in ['msg', 'message', 'errorMsg', 'error', 'reason']) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return '';
  }

  Future<void> _openScorePage() async {
    await caSession.dio.get(
      '${GxuCASession.yjsxtBase}${GxuScoreSession._scorePagePath}',
      options: _pageOptions(),
    );
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
        HttpHeaders.refererHeader:
            '${GxuCASession.yjsxtBase}${GxuScoreSession._portalPagePath}',
      },
    );
  }

  Options _ajaxOptions() {
    return Options(
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Origin': 'https://yjsxt.gxu.edu.cn',
        'Referer': '${GxuCASession.yjsxtBase}${GxuScoreSession._scorePagePath}',
      },
    );
  }
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
  throw LoginFailedException(msg: '广西大学$scene接口返回异常。');
}
