import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';

void main() {
  test('parse gxu score preview payload', () {
    final payload =
        jsonDecode('''
{
  "textMap": {
    "xh": "2513390261",
    "xm": "李信董",
    "szyxsmc": "计算机与电子信息学院",
    "bxzymc": "人工智能",
    "xslbmc": "专业硕士(全日制)",
    "pyccmc": "硕士",
    "jqpjcj": "82.38",
    "pjjd": "3.24",
    "yxxf1": "32",
    "yxxf2": "8",
    "yxzxf": "8",
    "xwkxf": "5",
    "date": "2026年3月18日",
    "jmzf": "验证码：1e7a6f",
    "yzwz": "验证网站：http://yjsglxt.gxu.edu.cn/verify"
  },
  "tableList": [
    {
      "zcj": "74",
      "ywzcj": "74",
      "ksxzmc": "正考",
      "sort": 1,
      "kcywmc": "Theory and Practice of Socialism with Chinese Characteristics in the New Era",
      "xf": "2",
      "kch": "10002M",
      "kcxzmc": "学位课",
      "kcxzywmc": "D",
      "zxs": "32",
      "xqmc": "2025年秋季",
      "xqdm": "2025-2026-1",
      "jd": "2.4",
      "kcmc": "新时代中国特色社会主义理论与实践"
    },
    {
      "zcj": "80",
      "ywzcj": "80",
      "ksxzmc": "正考",
      "sort": 2,
      "kcywmc": "Mathematical Optimization",
      "xf": "3",
      "kch": "113085420M",
      "kcxzmc": "学位课",
      "kcxzywmc": "D",
      "zxs": "48",
      "xqmc": "2025年秋季",
      "xqdm": "2025-2026-1",
      "jd": "3.0",
      "kcmc": "数学优化"
    }
  ]
}
''')
            as Map<String, dynamic>;

    final sheet = GxuScoreSheet.fromPreviewJson(payload);

    expect(sheet.profile.studentId, "2513390261");
    expect(sheet.profile.averageGpa, "3.24");
    expect(sheet.profile.earnedCredits, "8");
    expect(sheet.entries, hasLength(2));
    expect(sheet.entries.first.courseName, "新时代中国特色社会主义理论与实践");
    expect(sheet.entries.first.semesterCode, "2025-2026-1");
    expect(sheet.entries.first.gpa, "2.4");
  });
}
