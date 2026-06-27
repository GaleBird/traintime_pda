import 'package:dio/dio.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_exceptions.dart';

const int _badGatewayStatusCode = 502;
const String _officialUnavailableTitle = '学校官网暂时无法访问';
const String _officialUnavailableDescription =
    '当前时间段学校官网可能处于维护或暂时关闭，选课/成绩查询暂时不可用。请稍后再试。';

class GxuServiceErrorMessage {
  final String? title;
  final String description;

  const GxuServiceErrorMessage({this.title, required this.description});
}

GxuServiceErrorMessage describeGxuServiceError(Object error) {
  if (_isBadGateway(error)) {
    return const GxuServiceErrorMessage(
      title: _officialUnavailableTitle,
      description: _officialUnavailableDescription,
    );
  }
  if (error is GxuScoreAutoEvaluationRefreshException) {
    return GxuServiceErrorMessage(title: '成绩刷新失败', description: error.msg);
  }
  if (error is LoginFailedException) {
    return GxuServiceErrorMessage(description: error.msg);
  }
  return GxuServiceErrorMessage(description: error.toString());
}

bool _isBadGateway(Object error) {
  return error is DioException &&
      error.response?.statusCode == _badGatewayStatusCode;
}
