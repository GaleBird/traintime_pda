import 'package:flutter/material.dart';
import 'package:watermeter/page/classtable/classtable_constant.dart';

const int _jumpBaseMs = changePageTime;
const int _jumpPerWeekMs = 70;
const int _jumpMaxMs = 900;

Duration classTableWeekJumpDuration({required int distance}) {
  if (distance <= 0) {
    return const Duration(milliseconds: _jumpBaseMs);
  }
  final ms = _jumpBaseMs + (distance - 1) * _jumpPerWeekMs;
  final clampedMs = ms.clamp(_jumpBaseMs, _jumpMaxMs).toInt();
  return Duration(milliseconds: clampedMs);
}

double classTableWeekHighlightAlpha({
  required double page,
  required int index,
  required double selectedAlpha,
  required double unselectedAlpha,
}) {
  final distance = (page - index).abs();
  if (distance >= 1) {
    return unselectedAlpha;
  }

  final t = 1 - distance;
  final eased = Curves.easeOutCubic.transform(t);
  return unselectedAlpha + (selectedAlpha - unselectedAlpha) * eased;
}

double classTableWeekRowItemExtent() =>
    weekButtonWidth + 2 * weekButtonHorizontalPadding;

double classTableWeekRowMaxOffset({
  required int semesterLength,
  required double viewportWidth,
}) {
  final maxOffset =
      semesterLength * classTableWeekRowItemExtent() - viewportWidth;
  if (maxOffset <= 0) {
    return 0;
  }
  return maxOffset;
}

double classTableWeekRowOffsetForIndex({
  required int index,
  required int semesterLength,
  required double viewportWidth,
}) {
  final itemExtent = classTableWeekRowItemExtent();
  final centered = index * itemExtent - (viewportWidth - itemExtent) / 2;
  return centered.clamp(
    0.0,
    classTableWeekRowMaxOffset(
      semesterLength: semesterLength,
      viewportWidth: viewportWidth,
    ),
  );
}
