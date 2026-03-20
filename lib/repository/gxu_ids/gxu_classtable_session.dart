import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:watermeter/model/gxu_ids/gxu_semester_option.dart';
import 'package:watermeter/model/xidian_ids/classtable.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_classtable_parser.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/classtable_storage.dart';

class GxuClasstableSession {
  static const _classPath = "yjs/py/pkgl/ckkbOfYjs";
  static const _classItemId = "up_016_005";

  final GxuCASession caSession;
  final GxuClasstableParser parser;

  GxuClasstableSession({GxuCASession? caSession, GxuClasstableParser? parser})
    : caSession = caSession ?? GxuCASession(),
      parser = parser ?? GxuClasstableParser();

  Future<String> getCurrentSemesterCode() async {
    final options = await getSemesterOptions();
    return _currentSemesterOption(options).code;
  }

  Future<List<GxuSemesterOption>> getSemesterOptions() async {
    final classPage = await _loadClassPage();
    final options = _extractSemesterOptions(classPage.data.toString());
    if (options.isEmpty) {
      throw const LoginFailedException(msg: "广西大学课表页没有返回学期列表。");
    }
    return options;
  }

  Future<ClassTableData> getClassTable() async {
    final classPage = await _loadClassPage();
    final semesterOptions = _extractSemesterOptions(classPage.data.toString());
    final currentSemesterCode = _currentSemesterOption(semesterOptions).code;
    final semesterCode = _resolveTargetSemester(
      semesterOptions,
      currentSemesterCode,
    );
    final termStartDay = await _resolveTermStartDay(
      semesterCode: semesterCode,
      currentSemesterCode: currentSemesterCode,
    );
    final courseRows = await _fetchCourseRows();
    await _syncSemesterPreference(
      currentSemesterCode: currentSemesterCode,
      selectedSemesterCode: semesterCode,
    );
    return parser.parse(
      semesterCode: semesterCode,
      termStartDay: termStartDay,
      rawCourses: courseRows,
    );
  }

  Future<Response<dynamic>> _loadClassPage() async {
    await caSession.ensureYjsxtLoggedIn(
      username: preference.getString(preference.Preference.idsAccount),
      password: preference.getString(preference.Preference.idsPassword),
    );
    return caSession.dio.get(
      "${GxuCASession.yjsxtBase}/$_classPath",
      queryParameters: {"item_id": _classItemId},
      options: _ajaxOptions(),
    );
  }

  List<GxuSemesterOption> _extractSemesterOptions(String html) {
    final options = parse(
      html,
    ).querySelectorAll('.xzxq select[name="xqdm"] option');
    return options
        .map(_parseSemesterOption)
        .whereType<GxuSemesterOption>()
        .toList();
  }

  GxuSemesterOption? _parseSemesterOption(Element option) {
    final code = option.attributes["value"]?.trim() ?? "";
    if (code.isEmpty) {
      return null;
    }
    final label = option.text.replaceAll(RegExp(r"\s+"), " ").trim();
    return GxuSemesterOption(
      code: code,
      label: label,
      isSelected: option.attributes.containsKey("selected"),
    );
  }

  GxuSemesterOption _currentSemesterOption(List<GxuSemesterOption> options) {
    if (options.isEmpty) {
      throw const LoginFailedException(msg: "广西大学课表页没有返回学期列表。");
    }
    return options.firstWhere(
      (item) => item.isSelected,
      orElse: () => options.first,
    );
  }

  String _resolveTargetSemester(
    List<GxuSemesterOption> options,
    String currentSemesterCode,
  ) {
    final storedSemester = preference.getString(
      preference.Preference.currentSemester,
    );
    final isUserDefinedSemester = preference.getBool(
      preference.Preference.isUserDefinedSemester,
    );
    if (!isUserDefinedSemester) {
      return currentSemesterCode;
    }
    if (options.any((item) => item.code == storedSemester)) {
      return storedSemester;
    }
    return currentSemesterCode;
  }

  Future<void> _syncSemesterPreference({
    required String currentSemesterCode,
    required String selectedSemesterCode,
  }) async {
    final storedSemester = preference.getString(
      preference.Preference.currentSemester,
    );
    final wasUserDefined = preference.getBool(
      preference.Preference.isUserDefinedSemester,
    );
    final followCurrent = selectedSemesterCode == currentSemesterCode;
    await preference.setString(
      preference.Preference.currentSemester,
      selectedSemesterCode,
    );
    await preference.setBool(
      preference.Preference.isUserDefinedSemester,
      !followCurrent,
    );
    if (!followCurrent || storedSemester.isEmpty) {
      return;
    }
    if (storedSemester != currentSemesterCode && !wasUserDefined) {
      _clearUserDefinedClassCache();
    }
  }

  void _clearUserDefinedClassCache() {
    final userClassFile = File(
      "${supportPath.path}/${ClasstableStorage.userDefinedClassName}",
    );
    if (userClassFile.existsSync()) {
      userClassFile.deleteSync();
    }
  }

  Future<String> _resolveTermStartDay({
    required String semesterCode,
    required String currentSemesterCode,
  }) async {
    if (semesterCode == currentSemesterCode) {
      final currentWeek = await _fetchCurrentWeek();
      return _buildCurrentTermStartDay(currentWeek);
    }
    return _estimateTermStartDay(semesterCode);
  }

  Future<int> _fetchCurrentWeek() async {
    final weekRange = _currentWeekRange();
    final response = await caSession.dio.post(
      "${GxuCASession.yjsxtBase}/yjs/py/pkgl/findZkb2",
      data: weekRange..["type"] = "2",
      options: _ajaxOptions(),
    );
    final data = _mapOf(response.data, "广西大学当前周次");
    return int.tryParse(data["msg"]?.toString() ?? "") ?? 1;
  }

  Map<String, String> _currentWeekRange() {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return {"ksrq": _formatDate(monday), "jsrq": _formatDate(sunday)};
  }

  String _buildCurrentTermStartDay(int currentWeek) {
    final today = DateTime.now();
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final termStart = weekStart.subtract(Duration(days: (currentWeek - 1) * 7));
    return "${_formatDate(termStart)} 00:00:00";
  }

  String _estimateTermStartDay(String semesterCode) {
    final parts = semesterCode.split("-");
    if (parts.length != 3) {
      throw LoginFailedException(msg: "广西大学学期编码格式异常：$semesterCode");
    }
    final startYear = int.tryParse(parts[0]);
    final endYear = int.tryParse(parts[1]);
    final semester = int.tryParse(parts[2]);
    if (startYear == null || endYear == null || semester == null) {
      throw LoginFailedException(msg: "广西大学学期编码格式异常：$semesterCode");
    }
    final monthStart = switch (semester) {
      1 => DateTime(startYear, 9, 1),
      2 => DateTime(endYear, 2, 1),
      _ => throw LoginFailedException(msg: "广西大学学期编码格式异常：$semesterCode"),
    };
    final monday = _firstMondayFrom(monthStart);
    return "${_formatDate(monday)} 00:00:00";
  }

  DateTime _firstMondayFrom(DateTime date) {
    final delta = (DateTime.monday - date.weekday + 7) % 7;
    return date.add(Duration(days: delta));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "${date.year}-$month-$day";
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
    final data = _mapOf(response.data, "广西大学课程列表");
    final list = (data["list"] as List<dynamic>? ?? const [])
        .map((item) => _mapOf(item, "广西大学课程列表"))
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
    throw LoginFailedException(msg: "$scene接口返回异常。");
  }

  Options _ajaxOptions() {
    return Options(
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Origin": "https://yjsxt.gxu.edu.cn",
        "Referer": "${GxuCASession.yjsxtBase}/view?m=up#act=$_classPath",
      },
    );
  }

  Options _jsonOptions() {
    return Options(
      contentType: Headers.jsonContentType,
      headers: _ajaxOptions().headers,
    );
  }
}
