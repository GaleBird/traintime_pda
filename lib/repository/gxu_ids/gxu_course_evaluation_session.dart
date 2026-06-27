import 'dart:io';

import 'package:dio/dio.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_evaluation.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_exceptions.dart';
import 'package:watermeter/repository/preference.dart' as preference;

const gxuCourseEvaluationRiskText = '客观题默认选择最高分，主观题从评语池中随机挑选正向评语。';
const gxuCourseEvaluationWarningText = '提交后通常不可撤回，请确认这符合本人意愿。';
const gxuCourseEvaluationPagePath = '/yjs/py/kcpj/kcpjIndex?item_id=up_016_015';
const gxuCourseEvaluationRefererPath = '/view?m=up#act=yjs/py/kcpj/kcpjIndex';
const gxuCourseEvaluationPortalPath =
    '/view?m=up#act=yjs/py/kcpj/kcpjIndex?item_id=up_016_015';
final Uri gxuCourseEvaluationOfficialUri = Uri.parse(
  '${GxuCASession.yjsxtBase}$gxuCourseEvaluationPortalPath',
);

abstract class GxuAutoCourseEvaluator {
  Future<GxuCourseEvaluationReport> autoEvaluateRequiredCourses();
}

abstract class GxuCourseEvaluationClient {
  Future<void> ensureLoggedIn();
  Future<void> openEvaluationPage();

  Future<Map<String, dynamic>> fetchCoursePage({
    required int pageNum,
    required int pageSize,
  });

  Future<Map<String, dynamic>> fetchCourseDetail(String coursePlanId);
  Future<Map<String, dynamic>> submitEvaluation(Map<String, dynamic> data);
  Future<bool> checkPrintableScoreSheet();
}

class GxuCourseEvaluationReport {
  final int submittedCourseCount;
  final int skippedCourseCount;

  const GxuCourseEvaluationReport({
    required this.submittedCourseCount,
    required this.skippedCourseCount,
  });
}

class GxuCourseEvaluationSession implements GxuAutoCourseEvaluator {
  static const _pageSize = 100;

  final GxuCourseEvaluationClient client;

  GxuCourseEvaluationSession({
    GxuCASession? caSession,
    GxuCourseEvaluationClient? client,
  }) : client =
           client ?? _DioGxuCourseEvaluationClient(caSession ?? GxuCASession());

  @override
  Future<GxuCourseEvaluationReport> autoEvaluateRequiredCourses() async {
    await client.ensureLoggedIn();
    await client.openEvaluationPage();
    final courses = await _fetchPendingCourses();
    var submitted = 0;
    var skipped = 0;
    for (final course in courses) {
      final submission = await _buildSubmission(course);
      if (submission.isEmpty) {
        skipped++;
        continue;
      }
      await _submit(submission, course);
      submitted++;
    }
    await _ensureScoreSheetUnlocked();
    return GxuCourseEvaluationReport(
      submittedCourseCount: submitted,
      skippedCourseCount: skipped,
    );
  }

  Future<List<GxuCourseEvaluationCourse>> _fetchPendingCourses() async {
    final courses = <GxuCourseEvaluationCourse>[];
    var pageNum = 1;
    var totalPages = 1;
    while (pageNum <= totalPages) {
      final page = await client.fetchCoursePage(
        pageNum: pageNum,
        pageSize: _pageSize,
      );
      courses.addAll(
        _coursesOf(page).where((course) => course.needsEvaluation),
      );
      totalPages = _intOf(page['pages'], fallback: 1);
      if (_coursesOf(page).isEmpty) {
        break;
      }
      pageNum++;
    }
    return courses;
  }

  Future<GxuCourseEvaluationSubmission> _buildSubmission(
    GxuCourseEvaluationCourse course,
  ) async {
    final detail = await client.fetchCourseDetail(course.coursePlanId);
    return GxuCourseEvaluationSubmission.fromDetail(
      coursePlanId: course.coursePlanId,
      detail: detail,
    );
  }

  Future<void> _submit(
    GxuCourseEvaluationSubmission submission,
    GxuCourseEvaluationCourse course,
  ) async {
    final result = await client.submitEvaluation(submission.toRequestData());
    if (_stringOf(result['msg']) == '1') {
      return;
    }
    throw LoginFailedException(msg: _saveErrorMessage(result, course));
  }

  Future<void> _ensureScoreSheetUnlocked() async {
    if (await client.checkPrintableScoreSheet()) {
      return;
    }
    throw const GxuScoreEvaluationRequiredException(
      msg: '课程评价已提交，但成绩查询仍未开放，请稍后重试。',
    );
  }

  List<GxuCourseEvaluationCourse> _coursesOf(Map<String, dynamic> page) {
    return _listOf(
      page['list'],
    ).map(_mapOf).map(GxuCourseEvaluationCourse.fromRemoteMap).toList();
  }

  String _saveErrorMessage(
    Map<String, dynamic> result,
    GxuCourseEvaluationCourse course,
  ) {
    final msg = _stringOf(result['msg']);
    final remoteData = _stringOf(result['data']);
    final detail = _knownSaveError(msg);
    if (remoteData.isNotEmpty) {
      return '课程《${course.courseName}》评教提交失败：$remoteData';
    }
    return '课程《${course.courseName}》评教提交失败：$detail';
  }

  String _knownSaveError(String msg) {
    switch (msg) {
      case '2':
        return '未导入待评价课程。';
      case '3':
        return '题目不存在。';
      case '4':
        return '题目分数不正确。';
      case '5':
        return '题目选项不正确。';
      case '6':
        return '题目选项不存在。';
      case '7':
        return '题目选项分数不正确。';
      case '8':
        return '评价结果被系统拒绝。';
      default:
        return '系统返回 $msg。';
    }
  }
}

class _DioGxuCourseEvaluationClient implements GxuCourseEvaluationClient {
  final GxuCASession caSession;

  const _DioGxuCourseEvaluationClient(this.caSession);

  @override
  Future<void> ensureLoggedIn() {
    return caSession.ensureYjsxtLoggedIn(
      username: preference.getString(preference.Preference.idsAccount),
      password: preference.getString(preference.Preference.idsPassword),
    );
  }

  @override
  Future<void> openEvaluationPage() async {
    await caSession.dio.get(
      '${GxuCASession.yjsxtBase}$gxuCourseEvaluationPagePath',
      options: _pageOptions(),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchCoursePage({
    required int pageNum,
    required int pageSize,
  }) async {
    final response = await caSession.dio.post(
      '${GxuCASession.yjsxtBase}/yjs/py/kcpj/findKcpjPage',
      data: {'pageNum': pageNum, 'pageSize': pageSize},
      options: _jsonOptions(),
    );
    return _decodeMap(response.data, '课程评价列表');
  }

  @override
  Future<Map<String, dynamic>> fetchCourseDetail(String coursePlanId) async {
    final response = await caSession.dio.post(
      '${GxuCASession.yjsxtBase}/yjs/py/kcpj/findKcpjByJxjhxxid',
      data: {'jxjhxxid': coursePlanId},
      options: _formOptions(),
    );
    return _decodeMap(response.data, '课程评价题目');
  }

  @override
  Future<Map<String, dynamic>> submitEvaluation(
    Map<String, dynamic> data,
  ) async {
    final response = await caSession.dio.post(
      '${GxuCASession.yjsxtBase}/yjs/py/kcpj/saveKdpj',
      data: data,
      options: _formOptions(),
    );
    return _decodeMap(response.data, '课程评价提交');
  }

  @override
  Future<bool> checkPrintableScoreSheet() async {
    final response = await caSession.dio.post(
      '${GxuCASession.yjsxtBase}/yjs/py/cjgl/cjdpldy/checkdDycjd',
      data: <String, dynamic>{},
      options: _formOptions(),
    );
    final result = response.data.toString().replaceAll('"', '').trim();
    return result == '1';
  }

  Options _pageOptions() {
    return Options(
      headers: {
        HttpHeaders.refererHeader:
            '${GxuCASession.yjsxtBase}$gxuCourseEvaluationRefererPath',
      },
    );
  }

  Options _formOptions() {
    return Options(
      headers: _ajaxHeaders(),
      contentType: Headers.formUrlEncodedContentType,
    );
  }

  Options _jsonOptions() {
    return Options(
      headers: _ajaxHeaders(),
      contentType: Headers.jsonContentType,
    );
  }

  Map<String, String> _ajaxHeaders() {
    return {
      'X-Requested-With': 'XMLHttpRequest',
      'Origin': 'https://yjsxt.gxu.edu.cn',
      'Referer': '${GxuCASession.yjsxtBase}$gxuCourseEvaluationPagePath',
    };
  }
}

Map<String, dynamic> _decodeMap(dynamic data, String scene) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  throw LoginFailedException(msg: '广西大学$scene接口返回异常。');
}

List<dynamic> _listOf(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is List) {
    return value.cast<dynamic>();
  }
  return const [];
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const FormatException('GXU course evaluation list item is invalid.');
}

String _stringOf(dynamic value) => value?.toString().trim() ?? '';

int _intOf(dynamic value, {required int fallback}) {
  return int.tryParse(_stringOf(value)) ?? fallback;
}
