import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/page/score/gxu_score_evaluation_widgets.dart';

void main() {
  testWidgets('fetching view does not show auto evaluation disclaimer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GxuScoreFetchingView())),
    );

    expect(find.textContaining('自动提交当前未完成的课程评价'), findsNothing);
    expect(find.textContaining('需先评教'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('fetching view describes auto evaluation progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GxuScoreFetchingView(isAutoEvaluating: true)),
      ),
    );

    expect(find.text('正在检查课程评价并刷新成绩'), findsOneWidget);
    expect(find.textContaining('确认是否还有待评课程'), findsOneWidget);
  });

  testWidgets('fetching view shows concrete auto evaluation status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GxuScoreFetchingView(
            isAutoEvaluating: true,
            autoEvaluationStatus: '课程评价已全部完成，正在刷新成绩。',
          ),
        ),
      ),
    );

    expect(find.text('正在检查课程评价并刷新成绩'), findsOneWidget);
    expect(find.text('课程评价已全部完成，正在刷新成绩。'), findsOneWidget);
  });
}
