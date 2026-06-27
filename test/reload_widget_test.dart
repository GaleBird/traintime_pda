import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';

void main() {
  testWidgets('reload widget can show concise custom error copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReloadWidget(
            title: '学校官网暂时无法访问',
            errorStatus: '当前时间段学校官网可能处于维护或暂时关闭，请稍后再试。',
            buttonName: '刷新',
            function: () {},
          ),
        ),
      ),
    );

    expect(find.text('学校官网暂时无法访问'), findsOneWidget);
    expect(find.textContaining('当前时间段学校官网'), findsOneWidget);
    expect(find.textContaining('Description:'), findsNothing);
  });
}
