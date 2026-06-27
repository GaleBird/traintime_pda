import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/page/score/gxu_score_state.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';

void main() {
  test('describes submitted auto evaluation result for user feedback', () {
    const report = GxuCourseEvaluationReport(
      submittedCourseCount: 2,
      skippedCourseCount: 0,
    );

    expect(describeGxuAutoEvaluationFeedback(report), '已完成 2 门课程评价，成绩已刷新。');
  });

  test('describes already completed auto evaluation result', () {
    const report = GxuCourseEvaluationReport(
      submittedCourseCount: 0,
      skippedCourseCount: 0,
    );

    expect(
      describeGxuAutoEvaluationFeedback(report),
      '已确认课程评价全部完成，本次没有提交新评价，成绩已刷新。',
    );
  });

  test('describes already completed progress before score refresh', () {
    const report = GxuCourseEvaluationReport(
      submittedCourseCount: 0,
      skippedCourseCount: 0,
    );

    expect(describeGxuAutoEvaluationProgress(report), '已确认课程评价全部完成，正在刷新成绩。');
  });

  test('describes skipped auto evaluation result', () {
    const report = GxuCourseEvaluationReport(
      submittedCourseCount: 0,
      skippedCourseCount: 1,
    );

    expect(
      describeGxuAutoEvaluationFeedback(report),
      '未发现新的可提交评教，1 门课程无需重复提交，成绩已刷新。',
    );
  });

  test('appends score refresh note to auto evaluation feedback', () {
    const report = GxuCourseEvaluationReport(
      submittedCourseCount: 1,
      skippedCourseCount: 0,
    );

    expect(
      describeGxuAutoEvaluationFeedback(
        report,
        refreshNote: '官网初始化返回 0，已直接读取成绩单。',
      ),
      '已完成 1 门课程评价，成绩已刷新。官网初始化返回 0，已直接读取成绩单。',
    );
  });
}
