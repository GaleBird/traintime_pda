import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_service_error_message.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_session.dart';

void main() {
  test('describes GXU official 502 as temporary unavailable', () {
    final options = RequestOptions(path: 'https://yjsxt.gxu.edu.cn/tp');
    final error = DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 502),
      type: DioExceptionType.badResponse,
    );

    final message = describeGxuServiceError(error);

    expect(message.title, '学校官网暂时无法访问');
    expect(message.description, contains('当前时间段学校官网'));
    expect(message.description, contains('稍后再试'));
    expect(message.description, isNot(contains('DioException')));
  });

  test('uses login failure message without exception wrapper', () {
    const error = LoginFailedException(msg: '缺少账号或密码，请重新登录。');

    final message = describeGxuServiceError(error);

    expect(message.title, isNull);
    expect(message.description, '缺少账号或密码，请重新登录。');
  });

  test(
    'describes auto evaluation refresh failure with score refresh title',
    () {
      final error = GxuScoreAutoEvaluationRefreshException(
        report: const GxuCourseEvaluationReport(
          submittedCourseCount: 1,
          skippedCourseCount: 0,
        ),
        cause: const LoginFailedException(msg: '广西大学成绩模块初始化失败：0'),
      );

      final message = describeGxuServiceError(error);

      expect(message.title, '成绩刷新失败');
      expect(message.description, contains('课程评价流程已完成'));
      expect(message.description, contains('广西大学成绩模块初始化失败：0'));
    },
  );
}
