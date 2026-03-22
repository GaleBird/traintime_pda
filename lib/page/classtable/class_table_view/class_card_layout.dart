// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/widgets.dart';

const double classCardTextStepGranularity = 0.5;
const double _phoneCompactWidth = 35.0;
const double _phoneTinyHeight = 44.0;
const double _phoneTeacherHeight = 72.0;
const double _desktopCompactHeight = 60.0;
const double _desktopTeacherHeight = 96.0;

class ClassCardLayoutSpec {
  final int nameMaxLines;
  final int placeMaxLines;
  final bool showTeacher;
  final double placeMinFontSize;
  final EdgeInsets padding;

  const ClassCardLayoutSpec({
    required this.nameMaxLines,
    required this.placeMaxLines,
    required this.showTeacher,
    required this.placeMinFontSize,
    required this.padding,
  });
}

ClassCardLayoutSpec resolveClassCardLayout({
  required bool isPhoneLayout,
  required double width,
  required double height,
  required bool hasTeacher,
}) {
  final isCompactWidth = width < _phoneCompactWidth;

  if (isPhoneLayout) {
    if (height < _phoneTinyHeight) {
      return const ClassCardLayoutSpec(
        nameMaxLines: 1,
        placeMaxLines: 2,
        showTeacher: false,
        placeMinFontSize: 6.0,
        padding: EdgeInsets.fromLTRB(2, 3, 2, 3),
      );
    }
    if (isCompactWidth) {
      return const ClassCardLayoutSpec(
        nameMaxLines: 1,
        placeMaxLines: 2,
        showTeacher: false,
        placeMinFontSize: 6.0,
        padding: EdgeInsets.fromLTRB(2, 3, 2, 3),
      );
    }
    if (height < _phoneTeacherHeight || !hasTeacher) {
      return const ClassCardLayoutSpec(
        nameMaxLines: 1,
        placeMaxLines: 3,
        showTeacher: false,
        placeMinFontSize: 6.5,
        padding: EdgeInsets.fromLTRB(2, 3, 2, 3),
      );
    }
    return const ClassCardLayoutSpec(
      nameMaxLines: 2,
      placeMaxLines: 2,
      showTeacher: true,
      placeMinFontSize: 7.0,
      padding: EdgeInsets.fromLTRB(3, 4, 3, 4),
    );
  }

  if (height < _desktopCompactHeight) {
    return const ClassCardLayoutSpec(
      nameMaxLines: 1,
      placeMaxLines: 2,
      showTeacher: false,
      placeMinFontSize: 7.0,
      padding: EdgeInsets.fromLTRB(3, 4, 3, 4),
    );
  }
  if (height < _desktopTeacherHeight || !hasTeacher) {
    return const ClassCardLayoutSpec(
      nameMaxLines: 2,
      placeMaxLines: 3,
      showTeacher: false,
      placeMinFontSize: 7.5,
      padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
    );
  }
  return const ClassCardLayoutSpec(
    nameMaxLines: 2,
    placeMaxLines: 3,
    showTeacher: true,
    placeMinFontSize: 8.0,
    padding: EdgeInsets.fromLTRB(4, 5, 4, 5),
  );
}
