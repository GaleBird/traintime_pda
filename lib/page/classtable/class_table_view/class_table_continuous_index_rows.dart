import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/model/time_list.dart';

List<Widget> buildContinuousClassTableIndexRows(
  BuildContext context, {
  required double leftRowWidth,
  required double Function(double blocks) blockHeight,
}) {
  return List.generate(timeList.length ~/ 2, (index) {
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "${index + 1}\n"),
            TextSpan(
              text: "${timeList[index * 2]}\n",
              style: const TextStyle(fontSize: 8),
            ),
            TextSpan(
              text: timeList[index * 2 + 1],
              style: const TextStyle(fontSize: 8),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    ).center().constrained(width: leftRowWidth, height: blockHeight(1));
  });
}
