// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

// These are some constant used in the class table.

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/time_list.dart';

/// The width of the button.
const weekButtonWidth = 74.0;

/// The horizontal padding of the button.
const weekButtonHorizontalPadding = 2.0;

/// The width ratio for the week column.
const double leftRow = 26;

/// The height of the top row.
const topRowHeightBigWithOverview = 96.0;
const topRowHeightBigCompact = 56.0;
const topRowHeightSmall = 50.0;

double get topRowHeightBig =>
    isGxuMode ? topRowHeightBigCompact : topRowHeightBigWithOverview;

/// Change page time in milliseconds.
const changePageTime = 200;

/// The height of the middle row.
const midRowHeight = 54.0;
const currentWeekHighlightAlpha = 0.30;
const currentWeekUnselectedHighlightAlpha = 0.0;

Color buildClasstableHighlightColor(BuildContext context) {
  return Theme.of(
    context,
  ).highlightColor.withValues(alpha: currentWeekHighlightAlpha);
}

String getWeekString(BuildContext context, int index) {
  List<String> weekList = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  return FlutterI18n.translate(context, "weekday.${weekList[index]}");
}
