import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_evaluation.dart';

void main() {
  test('provides multiple positive comments for random evaluation', () {
    expect(gxuCourseEvaluationCommentOptions.length, greaterThanOrEqualTo(8));
    expect(
      gxuCourseEvaluationCommentOptions.toSet(),
      hasLength(greaterThanOrEqualTo(8)),
    );
    expect(
      gxuCourseEvaluationCommentOptions,
      everyElement(allOf(isNot(isEmpty), contains('老师'))),
    );
  });

  test('uses comment picker for subjective answers', () {
    var index = 0;
    final submission = GxuCourseEvaluationSubmission.fromDetail(
      coursePlanId: 'course-1',
      detail: _detailPayload(ypjsList: const []),
      commentPicker: () => ['评语一', '评语二'][index++],
    );

    expect(submission.subjectiveAnswers.single.tmda, '评语一');
  });

  test('builds best-score submission for pending teacher evaluation', () {
    final submission = GxuCourseEvaluationSubmission.fromDetail(
      coursePlanId: 'course-1',
      detail: _detailPayload(ypjsList: const []),
    );

    expect(submission.coursePlanId, 'course-1');
    expect(submission.objectiveAnswers, hasLength(2));
    expect(submission.subjectiveAnswers, hasLength(1));
    expect(submission.objectiveAnswers.first.jszgh, 'T001');
    expect(submission.objectiveAnswers.first.jxzlpjkgtxxxxid, 'best-option');
    expect(submission.objectiveAnswers.first.xxbh, 'A');
    expect(submission.objectiveAnswers.first.fs, '5');
    expect(submission.objectiveAnswers.last.jxzlpjkgtxxxxid, '');
    expect(submission.objectiveAnswers.last.xxbh, '');
    expect(submission.objectiveAnswers.last.fs, '10');
    expect(
      gxuCourseEvaluationCommentOptions,
      contains(submission.subjectiveAnswers.single.tmda),
    );
  });

  test('skips teachers that are already evaluated in detail payload', () {
    final submission = GxuCourseEvaluationSubmission.fromDetail(
      coursePlanId: 'course-1',
      detail: _detailPayload(ypjsList: const ['T001']),
    );

    expect(submission.isEmpty, isTrue);
  });

  test('skips teachers already evaluated when detail uses map payload', () {
    final submission = GxuCourseEvaluationSubmission.fromDetail(
      coursePlanId: 'course-1',
      detail: _detailPayload(
        ypjsList: const [
          {'jszgh': 'T001'},
        ],
      ),
    );

    expect(submission.isEmpty, isTrue);
  });

  test('throws instead of silently ranking invalid objective scores', () {
    expect(
      () => GxuCourseEvaluationSubmission.fromDetail(
        coursePlanId: 'course-1',
        detail: _detailPayload(
          ypjsList: const [],
          objectiveOptions: const [
            {'jxzlpjkgtxxxxid': 'invalid-option', 'xxbh': 'A', 'fs': '满分'},
            {'jxzlpjkgtxxxxid': 'numeric-option', 'xxbh': 'B', 'fs': 1},
          ],
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, dynamic> _detailPayload({
  required List<dynamic> ypjsList,
  List<Map<String, dynamic>> objectiveOptions = const [
    {'jxzlpjkgtxxxxid': 'weak-option', 'xxbh': 'B', 'fs': 3},
    {'jxzlpjkgtxxxxid': 'best-option', 'xxbh': 'A', 'fs': 5},
  ],
}) {
  return {
    'pjtxlbdm': '01',
    'jsxxList': [
      {'jszgh': 'T001', 'jsxm': '张老师'},
    ],
    'ypjsList': ypjsList,
    'tmlbList': [
      {
        'tmxxList': [
          {
            'jxzlpjtmxxid': 'Q1',
            'tmbh': '1',
            'sfzgt': 'N',
            'sffzxx': 'N',
            'fs': 5,
            'kgtxxList': objectiveOptions,
          },
          {
            'jxzlpjtmxxid': 'Q2',
            'tmbh': '2',
            'sfzgt': 'N',
            'sffzxx': 'Y',
            'fs': 10,
          },
          {'jxzlpjtmxxid': 'Q3', 'tmbh': '3', 'sfzgt': 'Y'},
        ],
      },
    ],
  };
}
