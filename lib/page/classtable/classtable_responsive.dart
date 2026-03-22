// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:watermeter/model/time_list.dart';
import 'package:watermeter/page/classtable/classtable_constant.dart';

const double _gxuCompactScreenHeight = 700;
const double _gxuTinyScreenHeight = 620;
const double _compactViewportHeight = 600;
const double _tinyViewportHeight = 520;
const double _compactViewportWidth = 360;

class ClassTableHeaderMetrics {
  final double topViewHeight;
  final EdgeInsets weekChoiceInnerPadding;

  const ClassTableHeaderMetrics({
    required this.topViewHeight,
    required this.weekChoiceInnerPadding,
  });
}

class ClassTableGridMetrics {
  final double leftColumnWidth;
  final double dateRowHeight;
  final double monthFontSize;
  final double weekdayFontSize;
  final double dayFontSize;
  final double dateCellPaddingVertical;
  final double dateCellGap;
  final double dayPillWidth;
  final double dayPillHeight;
  final double todayRadius;
  final double todayPillRadius;
  final double periodIndexFontSize;
  final double periodTimeFontSize;
  final double breakLabelFontSize;
  final double periodCellVerticalPadding;

  const ClassTableGridMetrics({
    required this.leftColumnWidth,
    required this.dateRowHeight,
    required this.monthFontSize,
    required this.weekdayFontSize,
    required this.dayFontSize,
    required this.dateCellPaddingVertical,
    required this.dateCellGap,
    required this.dayPillWidth,
    required this.dayPillHeight,
    required this.todayRadius,
    required this.todayPillRadius,
    required this.periodIndexFontSize,
    required this.periodTimeFontSize,
    required this.breakLabelFontSize,
    required this.periodCellVerticalPadding,
  });
}

ClassTableHeaderMetrics resolveClassTableHeaderMetrics(Size viewportSize) {
  if (!isGxuMode) {
    final useLargeTopRow = viewportSize.height >= 500;
    return ClassTableHeaderMetrics(
      topViewHeight: useLargeTopRow ? topRowHeightBig : topRowHeightSmall,
      weekChoiceInnerPadding: const EdgeInsets.all(5),
    );
  }

  if (viewportSize.height < _gxuTinyScreenHeight) {
    return const ClassTableHeaderMetrics(
      topViewHeight: 42,
      weekChoiceInnerPadding: EdgeInsets.all(3),
    );
  }

  if (viewportSize.height < _gxuCompactScreenHeight) {
    return const ClassTableHeaderMetrics(
      topViewHeight: 46,
      weekChoiceInnerPadding: EdgeInsets.all(4),
    );
  }

  return const ClassTableHeaderMetrics(
    topViewHeight: topRowHeightBigCompact,
    weekChoiceInnerPadding: EdgeInsets.all(5),
  );
}

ClassTableGridMetrics resolveClassTableGridMetrics(Size viewport) {
  final isTiny =
      viewport.height < _tinyViewportHeight ||
      viewport.width < _compactViewportWidth;
  if (isTiny) {
    return const ClassTableGridMetrics(
      leftColumnWidth: 24,
      dateRowHeight: 42,
      monthFontSize: 12,
      weekdayFontSize: 12,
      dayFontSize: 10,
      dateCellPaddingVertical: 0.5,
      dateCellGap: 1,
      dayPillWidth: 24,
      dayPillHeight: 18,
      todayRadius: 10,
      todayPillRadius: 8,
      periodIndexFontSize: 10,
      periodTimeFontSize: 6.8,
      breakLabelFontSize: 10.5,
      periodCellVerticalPadding: 1,
    );
  }

  final isCompact = viewport.height < _compactViewportHeight;
  if (isCompact) {
    return const ClassTableGridMetrics(
      leftColumnWidth: 25,
      dateRowHeight: 46,
      monthFontSize: 13,
      weekdayFontSize: 13,
      dayFontSize: 11,
      dateCellPaddingVertical: 1,
      dateCellGap: 1.5,
      dayPillWidth: 26,
      dayPillHeight: 19,
      todayRadius: 11,
      todayPillRadius: 9,
      periodIndexFontSize: 10.5,
      periodTimeFontSize: 7.2,
      breakLabelFontSize: 11,
      periodCellVerticalPadding: 1.5,
    );
  }

  return const ClassTableGridMetrics(
    leftColumnWidth: leftRow,
    dateRowHeight: midRowHeight,
    monthFontSize: 14,
    weekdayFontSize: 14,
    dayFontSize: 12,
    dateCellPaddingVertical: 1,
    dateCellGap: 2,
    dayPillWidth: 28,
    dayPillHeight: 20,
    todayRadius: 12,
    todayPillRadius: 10,
    periodIndexFontSize: 11,
    periodTimeFontSize: 8,
    breakLabelFontSize: 12,
    periodCellVerticalPadding: 2,
  );
}
