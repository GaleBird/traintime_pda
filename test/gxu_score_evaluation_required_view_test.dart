import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/page/score/gxu_score_evaluation_widgets.dart';

void main() {
  testWidgets('persistent evaluation card uses light blue tinted surface', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.green);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: GxuCourseEvaluationEntryCard(
              onOpenOfficial: () {},
              onAutoEvaluate: () {},
            ),
          ),
        ),
      ),
    );

    final decoration = _entryCardDecoration(tester);
    expect(decoration.color, scheme.secondary.withValues(alpha: 0.08));
    expect(decoration.color, isNot(scheme.surfaceContainerHighest));
  });

  testWidgets('evaluation required view shows official and auto options', (
    tester,
  ) async {
    var officialCount = 0;
    var autoCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GxuScoreEvaluationRequiredView(
            error: '培养评价未完成',
            onOpenOfficial: () => officialCount++,
            onAutoEvaluate: () => autoCount++,
          ),
        ),
      ),
    );

    expect(find.text('官网评教'), findsOneWidget);
    expect(find.text('自动评教'), findsOneWidget);
    await tester.tap(find.text('官网评教'));
    expect(officialCount, 1);
    expect(autoCount, 0);
  });

  testWidgets('auto evaluation disclaimer requires checkbox confirmation', (
    tester,
  ) async {
    var confirmed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GxuAutoEvaluationDisclaimerDialog(
            onConfirmed: () => confirmed++,
          ),
        ),
      ),
    );

    final confirmButton = find.widgetWithText(FilledButton, '确认自动评教');
    expect(find.textContaining('会先检查课程评价状态', findRichText: true), findsNothing);
    expect(
      find.textContaining('客观题默认选择最高分', findRichText: true),
      findsOneWidget,
    );
    expect(_highlightedWarningCount(tester), greaterThanOrEqualTo(1));
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);
    await tester.tap(confirmButton);
    expect(confirmed, 1);
  });

  testWidgets('persistent evaluation card confirms before auto evaluation', (
    tester,
  ) async {
    var officialCount = 0;
    var autoCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GxuCourseEvaluationEntryCard(
            onOpenOfficial: () => officialCount++,
            onAutoEvaluate: () => autoCount++,
          ),
        ),
      ),
    );

    expect(find.text('课程评价'), findsOneWidget);
    expect(find.text('官网评教'), findsOneWidget);
    expect(find.text('自动评教'), findsOneWidget);
    expect(find.textContaining('未完成评教'), findsNothing);

    await tester.tap(find.text('官网评教'));
    expect(officialCount, 1);
    expect(autoCount, 0);

    await tester.tap(find.text('自动评教'));
    await tester.pumpAndSettle();
    final confirmButton = find.widgetWithText(FilledButton, '确认自动评教');
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(confirmButton);
    expect(autoCount, 1);
  });

  testWidgets('persistent evaluation card uses balanced mobile actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              child: GxuCourseEvaluationEntryCard(
                onOpenOfficial: () {},
                onAutoEvaluate: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final officialSize = tester.getSize(
      find.widgetWithText(OutlinedButton, '官网评教'),
    );
    final autoSize = tester.getSize(find.widgetWithText(FilledButton, '自动评教'));
    expect((officialSize.width - autoSize.width).abs(), lessThan(1));
    expect(officialSize.width, greaterThan(150));
    expect(autoSize.width, greaterThan(150));
    final titleBottom = tester.getBottomLeft(find.text('课程评价')).dy;
    final buttonTop = tester
        .getTopLeft(find.widgetWithText(OutlinedButton, '官网评教'))
        .dy;
    expect(buttonTop - titleBottom, lessThan(32));
  });

  testWidgets('auto evaluation feedback banner keeps result visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GxuAutoEvaluationFeedbackBanner(
            message: '课程评价已全部完成，成绩已刷新，无需重复提交。',
          ),
        ),
      ),
    );

    expect(find.text('课程评价结果'), findsOneWidget);
    expect(find.textContaining('无需重复提交'), findsOneWidget);
  });
}

int _highlightedWarningCount(WidgetTester tester) {
  final spans = tester
      .widgetList<RichText>(find.byType(RichText))
      .expand((widget) => _flattenTextSpan(widget.text))
      .where((span) => span.toPlainText().contains('提交后通常不可撤回'))
      .where((span) => span.style?.color != null)
      .where((span) => span.style?.fontWeight == FontWeight.w700)
      .length;
  return spans;
}

Iterable<InlineSpan> _flattenTextSpan(InlineSpan span) sync* {
  yield span;
  final children = span is TextSpan ? span.children : null;
  if (children == null) {
    return;
  }
  for (final child in children) {
    yield* _flattenTextSpan(child);
  }
}

BoxDecoration _entryCardDecoration(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .map((widget) => widget.decoration)
      .whereType<BoxDecoration>()
      .singleWhere(
        (decoration) => decoration.borderRadius == BorderRadius.circular(24),
      );
}
