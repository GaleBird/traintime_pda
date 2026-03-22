// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/classtable/classtable_constant.dart';
import 'package:watermeter/page/classtable/classtable_responsive.dart';

/// The index row of the class table, shows the index of the day and the week.
class ClassTableDateRow extends StatelessWidget {
  final ClassTableGridMetrics metrics;
  final List<DateTime> dateList = [];
  ClassTableDateRow({
    super.key,
    required DateTime firstDay,
    required this.metrics,
  }) {
    /// Here, we get the first day of the week, and generate the date row.
    dateList.addAll(List.generate(7, (i) => firstDay.add(Duration(days: i))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      /// This will detertime the height of the row, also the way week info and
      /// day shows.
      height: metrics.dateRowHeight,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
      child: Row(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              FlutterI18n.translate(
                context,
                "classtable.month",
                translationParams: {"month": dateList.first.month.toString()},
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: metrics.monthFontSize,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ).center().constrained(width: metrics.leftColumnWidth),
          ...List.generate(
            7,
            (index) => Expanded(
              child: WeekInfomation(time: dateList[index], metrics: metrics),
            ),
          ),
        ],
      ),
    );
  }
}

/// The week index info, shows the day and the week.
class WeekInfomation extends StatelessWidget {
  static const double _weekdayLineHeight = 1.0;
  static const double _dayLineHeight = 1.0;
  static const double _todayCellAlpha = 0.55;
  static const double _todayBorderAlpha = 0.40;
  static const double _todayBorderWidth = 1.0;
  static const double _todayPillAlpha = 0.18;

  final DateTime time;
  final ClassTableGridMetrics metrics;

  const WeekInfomation({super.key, required this.time, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: metrics.dateCellPaddingVertical),
      decoration: isToday
          ? BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: _todayCellAlpha),
              borderRadius: BorderRadius.circular(metrics.todayRadius),
              border: Border.all(
                color: scheme.primary.withValues(alpha: _todayBorderAlpha),
                width: _todayBorderWidth,
              ),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  getWeekString(context, time.weekday - 1),
                  style: TextStyle(
                    fontSize: metrics.weekdayFontSize,
                    height: _weekdayLineHeight,
                    fontWeight: isToday ? FontWeight.w800 : null,
                    color: isToday ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.dateCellGap),
          SizedBox(
            width: metrics.dayPillWidth,
            height: metrics.dayPillHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isToday
                    ? scheme.primary.withValues(alpha: _todayPillAlpha)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(metrics.todayPillRadius),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    time.day.toString(),
                    style: TextStyle(
                      fontSize: metrics.dayFontSize,
                      height: _dayLineHeight,
                      fontWeight: isToday ? FontWeight.w800 : null,
                      color: isToday ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
