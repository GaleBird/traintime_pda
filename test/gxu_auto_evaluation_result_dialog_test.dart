import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/page/score/gxu_auto_evaluation_result_dialog.dart';

void main() {
  testWidgets(
    'auto evaluation result dialog keeps completed feedback visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GxuAutoEvaluationResultDialog(
              message: '已确认课程评价全部完成，本次没有提交新评价，成绩已刷新。',
            ),
          ),
        ),
      );

      expect(find.text('课程评价结果'), findsOneWidget);
      expect(find.textContaining('本次没有提交新评价'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '知道了'), findsOneWidget);
    },
  );
}
