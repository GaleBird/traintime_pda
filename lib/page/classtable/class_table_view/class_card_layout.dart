// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/widgets.dart';

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
  required double height,
  required bool hasTeacher,
}) {
  if (isPhoneLayout) {
    if (height < 44) {
      return const ClassCardLayoutSpec(
        nameMaxLines: 1,
        placeMaxLines: 2,
        showTeacher: false,
        placeMinFontSize: 6.2,
        padding: EdgeInsets.fromLTRB(2, 3, 2, 3),
      );
    }
    if (height < 72 || !hasTeacher) {
      return const ClassCardLayoutSpec(
        nameMaxLines: 1,
        placeMaxLines: 3,
        showTeacher: false,
        placeMinFontSize: 6.6,
        padding: EdgeInsets.fromLTRB(2, 3, 2, 3),
      );
    }
    return const ClassCardLayoutSpec(
      nameMaxLines: 2,
      placeMaxLines: 2,
      showTeacher: true,
      placeMinFontSize: 6.8,
      padding: EdgeInsets.fromLTRB(3, 4, 3, 4),
    );
  }

  if (height < 60) {
    return const ClassCardLayoutSpec(
      nameMaxLines: 1,
      placeMaxLines: 2,
      showTeacher: false,
      placeMinFontSize: 7.2,
      padding: EdgeInsets.fromLTRB(3, 4, 3, 4),
    );
  }
  if (height < 96 || !hasTeacher) {
    return const ClassCardLayoutSpec(
      nameMaxLines: 2,
      placeMaxLines: 3,
      showTeacher: false,
      placeMinFontSize: 7.6,
      padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
    );
  }
  return const ClassCardLayoutSpec(
    nameMaxLines: 2,
    placeMaxLines: 3,
    showTeacher: true,
    placeMinFontSize: 7.8,
    padding: EdgeInsets.fromLTRB(4, 5, 4, 5),
  );
}
