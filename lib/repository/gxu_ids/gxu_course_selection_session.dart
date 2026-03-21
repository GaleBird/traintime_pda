import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_selection.dart';
import 'package:watermeter/model/gxu_ids/gxu_semester_option.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_classtable_session.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/security/secure_file_store.dart';

class GxuCourseSelectionSession {
  static const _defaultCacheDuration = Duration(hours: 24);
  static const courseSelectionCacheName = "gxu_course_selection.json";
  static final File file = File(
    "${supportPath.path}/$courseSelectionCacheName",
  );
  static final SecureFileStore _cacheStore = SecureFileStore(
    file: file,
    namespace: "gxu_course_selection",
  );
  static bool isCourseSelectionCacheUsed = false;

  final GxuCASession caSession;

  GxuCourseSelectionSession({GxuCASession? caSession})
    : caSession = caSession ?? GxuCASession();

  Future<GxuCourseSelectionSheet> getCourseSelectionSheet({
    bool force = false,
  }) async {
    final cache = _loadCache();
    if (!force && cache != null && _isCacheFresh(cache)) {
      isCourseSelectionCacheUsed = true;
      return cache;
    }
    try {
      final sheet = await _fetchRemote();
      _dumpCache(sheet);
      isCourseSelectionCacheUsed = false;
      return sheet;
    } catch (e) {
      if (cache != null) {
        log.warning(
          "[GxuCourseSelectionSession] Load remote course selection failed, fallback to cache: $e",
        );
        isCourseSelectionCacheUsed = true;
        return cache;
      }
      isCourseSelectionCacheUsed = false;
      rethrow;
    }
  }

  GxuCourseSelectionSheet? _loadCache() {
    final rawText = _cacheStore.readAsStringSync();
    if (rawText == null) {
      return null;
    }
    final raw = jsonDecode(rawText);
    if (raw is! Map) {
      throw const LoginFailedException(msg: "广西大学选课缓存已损坏。");
    }
    return GxuCourseSelectionSheet.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  bool _isCacheFresh(GxuCourseSelectionSheet cache) {
    if (!file.existsSync()) {
      return false;
    }
    if (cache.selectionPhase == GxuCourseSelectionPhase.ended) {
      return true;
    }
    final cacheAge = DateTime.now().difference(file.lastModifiedSync());
    return cacheAge < _cacheDurationOf(cache.selectionPhase);
  }

  void _dumpCache(GxuCourseSelectionSheet sheet) {
    _cacheStore.writeAsStringSync(jsonEncode(sheet.toJson()));
  }

  Future<GxuCourseSelectionSheet> _fetchRemote() async {
    await caSession.ensureYjsxtLoggedIn(
      username: preference.getString(preference.Preference.idsAccount),
      password: preference.getString(preference.Preference.idsPassword),
    );
    final selectionPhase = await _fetchSelectionPhase();
    final semesterLabels = await _fetchSemesterLabels();
    final rows = await _fetchCourseRows();
    final entries = rows
        .map(GxuCourseSelectionEntry.fromRemoteMap)
        .map((entry) => _withSemesterLabel(entry, semesterLabels))
        .toList();
    return GxuCourseSelectionSheet(
      semesterLabels: semesterLabels,
      entries: entries,
      selectionPhase: selectionPhase,
    );
  }

  Future<GxuCourseSelectionPhase> _fetchSelectionPhase() async {
    try {
      final response = await caSession.dio.get(
        "${GxuCASession.yjsxtBase}/yjsjbxx/init/index/page",
        options: _ajaxOptions(refererPath: "/index.html"),
      );
      final body = _mapOf(response.data, "广西大学选课首页");
      final data = _mapOf(body["data"], "广西大学选课首页");
      final xuankeDate = _mapOf(data["xuankeDate"], "广西大学选课首页");
      return gxuCourseSelectionPhaseFromRemoteStatus(xuankeDate["STATUS"]);
    } catch (error, stackTrace) {
      log.warning(
        "[GxuCourseSelectionSession] Failed to load course selection phase, fallback to unknown.",
        error,
        stackTrace,
      );
      return GxuCourseSelectionPhase.unknown;
    }
  }

  Future<Map<String, String>> _fetchSemesterLabels() async {
    final options = await GxuClasstableSession(
      caSession: caSession,
    ).getSemesterOptions();
    return {for (final option in options) option.code: option.label};
  }

  GxuCourseSelectionEntry _withSemesterLabel(
    GxuCourseSelectionEntry entry,
    Map<String, String> labels,
  ) {
    if (entry.semesterName.isNotEmpty) {
      return entry;
    }
    final label = labels[entry.semesterCode];
    if (label == null || label.isEmpty) {
      return entry;
    }
    return entry.copyWith(semesterName: label);
  }

  Future<List<Map<String, dynamic>>> _fetchCourseRows() async {
    const pageSize = 100;
    final rows = <Map<String, dynamic>>[];
    var pageNum = 1;
    var totalPages = 1;
    while (pageNum <= totalPages) {
      final page = await _fetchCoursePage(pageNum: pageNum, pageSize: pageSize);
      rows.addAll(page.rows);
      if (page.rows.isEmpty) {
        break;
      }
      totalPages = page.totalPages;
      pageNum++;
    }
    return rows;
  }

  Future<GxuCoursePageResult> _fetchCoursePage({
    required int pageNum,
    required int pageSize,
  }) async {
    final response = await caSession.dio.post(
      "${GxuCASession.yjsxtBase}/yjs/py/xkgl/xkmdcx/findXkmdByXsPage",
      data: {"pageNum": pageNum, "pageSize": pageSize, "glrlx": "xs"},
      options: _jsonOptions(),
    );
    final data = _mapOf(response.data, "广西大学选课列表");
    final list = (data["list"] as List<dynamic>? ?? const [])
        .map((item) => _mapOf(item, "广西大学选课列表"))
        .toList();
    final totalPages = int.tryParse(data["pages"]?.toString() ?? "") ?? 1;
    return GxuCoursePageResult(rows: list, totalPages: totalPages);
  }

  Map<String, dynamic> _mapOf(dynamic value, String scene) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, item) => MapEntry(key.toString(), item));
      }
    }
    throw LoginFailedException(msg: "$scene接口返回异常。");
  }

  Duration _cacheDurationOf(GxuCourseSelectionPhase phase) {
    switch (phase) {
      case GxuCourseSelectionPhase.notStarted:
      case GxuCourseSelectionPhase.inProgress:
      case GxuCourseSelectionPhase.unknown:
        return _defaultCacheDuration;
      case GxuCourseSelectionPhase.ended:
        return _defaultCacheDuration;
    }
  }

  Options _ajaxOptions({required String refererPath}) {
    return Options(
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Origin": "https://yjsxt.gxu.edu.cn",
        "Referer": "${GxuCASession.yjsxtBase}$refererPath",
      },
    );
  }

  Options _jsonOptions() {
    return Options(
      contentType: Headers.jsonContentType,
      headers: _ajaxOptions(
        refererPath: "/view?m=up#act=yjs/py/pkgl/ckkbOfYjs",
      ).headers,
    );
  }
}
