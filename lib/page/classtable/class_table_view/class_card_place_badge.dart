// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ClassCardPlaceBadge extends StatelessWidget {
  static const double _radius = 6;
  static const double _borderWidth = 0.8;
  static const EdgeInsets _paddingPhone = EdgeInsets.fromLTRB(4, 3, 4, 3);
  static const EdgeInsets _paddingTablet = EdgeInsets.fromLTRB(5, 4, 5, 4);

  final MaterialColor color;
  final bool isPhoneLayout;
  final String value;
  final int maxLines;
  final double minFontSize;
  final TextStyle style;

  const ClassCardPlaceBadge({
    super.key,
    required this.color,
    required this.isPhoneLayout,
    required this.value,
    required this.maxLines,
    required this.minFontSize,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.shade200.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: color.shade400.withValues(alpha: 0.7),
          width: _borderWidth,
        ),
      ),
      child: Padding(
        padding: isPhoneLayout ? _paddingPhone : _paddingTablet,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AutoSizeText(
            value,
            style: style,
            maxLines: maxLines,
            minFontSize: minFontSize,
            stepGranularity: 0.1,
            overflowReplacement: _CompressedPlaceText(
              value: value,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompressedPlaceText extends StatelessWidget {
  final String value;
  final TextStyle style;

  const _CompressedPlaceText({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text(value, maxLines: 1, softWrap: false, style: style),
    );
  }
}
