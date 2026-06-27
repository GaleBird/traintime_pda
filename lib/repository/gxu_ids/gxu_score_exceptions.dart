import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';

class GxuScoreEvaluationRequiredException extends LoginFailedException {
  const GxuScoreEvaluationRequiredException({
    super.msg = '培养评价未完成，研究生成绩单暂时不可查询。',
  });
}

class GxuScoreAutoEvaluationRefreshException extends LoginFailedException {
  final GxuCourseEvaluationReport report;
  final Object cause;

  GxuScoreAutoEvaluationRefreshException({
    required this.report,
    required this.cause,
  }) : super(msg: '课程评价流程已完成，但成绩刷新失败：${_scoreRefreshCauseMessage(cause)}');
}

String _scoreRefreshCauseMessage(Object cause) {
  if (cause is LoginFailedException) {
    return cause.msg;
  }
  return cause.toString();
}
