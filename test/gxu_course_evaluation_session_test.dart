import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_evaluation.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_session.dart';

void main() {
  test(
    'official evaluation uri opens portal shell instead of raw module page',
    () {
      expect(gxuCourseEvaluationOfficialUri.path, '/tp/view');
      expect(gxuCourseEvaluationOfficialUri.query, 'm=up');
      expect(
        gxuCourseEvaluationOfficialUri.fragment,
        'act=yjs/py/kcpj/kcpjIndex?item_id=up_016_015',
      );
    },
  );

  test(
    'submits pending course evaluation and validates score unlock',
    () async {
      final client = _FakeEvaluationClient(
        pages: [
          {
            'pageNum': 1,
            'pages': 1,
            'list': [
              {
                'jxjhxxid': 'course-1',
                'kcmc': '测试课程',
                'jxzlpjtxid': '001',
                'jxzlpjsfwc': 'N',
              },
            ],
          },
        ],
        details: {'course-1': _detailPayload()},
        submitResponses: const [
          {'msg': '1'},
        ],
        canPreviewScoreSheet: true,
      );

      final report = await GxuCourseEvaluationSession(
        client: client,
      ).autoEvaluateRequiredCourses();

      expect(report.submittedCourseCount, 1);
      expect(client.openedEvaluationPage, isTrue);
      expect(client.submissions.single['jxjhxxid'], 'course-1');
      expect(client.submissions.single['kgtjg'], contains('best-option'));
      final subjectiveAnswers =
          jsonDecode(client.submissions.single['zgtjg'] as String) as List;
      expect(
        gxuCourseEvaluationCommentOptions,
        contains(subjectiveAnswers.single['tmda']),
      );
      expect(client.checkedScoreSheet, isTrue);
    },
  );

  test('throws when remote save endpoint rejects a submission', () async {
    final client = _FakeEvaluationClient(
      pages: [
        {
          'pageNum': 1,
          'pages': 1,
          'list': [
            {
              'jxjhxxid': 'course-1',
              'kcmc': '测试课程',
              'jxzlpjtxid': '001',
              'jxzlpjsfwc': 'N',
            },
          ],
        },
      ],
      details: {'course-1': _detailPayload()},
      submitResponses: const [
        {'msg': '5'},
      ],
      canPreviewScoreSheet: true,
    );

    expect(
      () => GxuCourseEvaluationSession(
        client: client,
      ).autoEvaluateRequiredCourses(),
      throwsA(isA<LoginFailedException>()),
    );
  });

  test(
    'throws evaluation-required when score sheet remains locked after submissions',
    () async {
      final client = _FakeEvaluationClient(
        pages: [
          {
            'pageNum': 1,
            'pages': 1,
            'list': [
              {
                'jxjhxxid': 'course-1',
                'kcmc': '测试课程',
                'jxzlpjtxid': '001',
                'jxzlpjsfwc': 'N',
              },
            ],
          },
        ],
        details: {'course-1': _detailPayload()},
        submitResponses: const [
          {'msg': '1'},
        ],
        canPreviewScoreSheet: false,
      );

      expect(
        () => GxuCourseEvaluationSession(
          client: client,
        ).autoEvaluateRequiredCourses(),
        throwsA(isA<GxuScoreEvaluationRequiredException>()),
      );
    },
  );
}

class _FakeEvaluationClient implements GxuCourseEvaluationClient {
  final List<Map<String, dynamic>> pages;
  final Map<String, Map<String, dynamic>> details;
  final List<Map<String, dynamic>> submitResponses;
  final bool canPreviewScoreSheet;
  final submissions = <Map<String, dynamic>>[];
  bool openedEvaluationPage = false;
  bool checkedScoreSheet = false;

  _FakeEvaluationClient({
    required this.pages,
    required this.details,
    required this.submitResponses,
    required this.canPreviewScoreSheet,
  });

  @override
  Future<void> ensureLoggedIn() async {}

  @override
  Future<void> openEvaluationPage() async {
    openedEvaluationPage = true;
  }

  @override
  Future<Map<String, dynamic>> fetchCoursePage({
    required int pageNum,
    required int pageSize,
  }) async {
    return pages[pageNum - 1];
  }

  @override
  Future<Map<String, dynamic>> fetchCourseDetail(String coursePlanId) async {
    return details[coursePlanId]!;
  }

  @override
  Future<Map<String, dynamic>> submitEvaluation(
    Map<String, dynamic> data,
  ) async {
    submissions.add(data);
    return submitResponses[submissions.length - 1];
  }

  @override
  Future<bool> checkPrintableScoreSheet() async {
    checkedScoreSheet = true;
    return canPreviewScoreSheet;
  }
}

Map<String, dynamic> _detailPayload() {
  return {
    'data': {
      'pjtxlbdm': '01',
      'jsxxList': [
        {'jszgh': 'T001', 'jsxm': '张老师'},
      ],
      'ypjsList': [],
      'tmlbList': [
        {
          'tmxxList': [
            {
              'jxzlpjtmxxid': 'Q1',
              'tmbh': '1',
              'sfzgt': 'N',
              'sffzxx': 'N',
              'kgtxxList': [
                {'jxzlpjkgtxxxxid': 'best-option', 'xxbh': 'A', 'fs': 5},
              ],
            },
            {'jxzlpjtmxxid': 'Q2', 'tmbh': '2', 'sfzgt': 'Y'},
          ],
        },
      ],
    },
  };
}
