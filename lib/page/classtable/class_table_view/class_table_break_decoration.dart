import 'package:flutter/material.dart';

class ClassTableBreakPalette {
  final Color backgroundColor;
  final Color foregroundColor;

  const ClassTableBreakPalette({
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class ClassTableBreakDecoration {
  static const double _stripeAlpha = 0.16;
  static const double _stripeBorderAlpha = 0.22;
  static const double _stripeBorderWidth = 0.6;

  static ClassTableBreakPalette palette(ColorScheme scheme, String i18nKey) {
    return switch (i18nKey) {
      "classtable.supper_break" => ClassTableBreakPalette(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
      ),
      _ => ClassTableBreakPalette(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
    };
  }

  static List<Widget> stripes({
    required bool enabled,
    required double left,
    required double width,
    required double Function(double blocks) blockHeight,
    required double periodSpanBlocks,
    required double breakSpanBlocks,
    required ColorScheme scheme,
  }) {
    if (!enabled) {
      return const [];
    }

    return [
      stripe(
        topBlocks: periodSpanBlocks * 4,
        left: left,
        width: width,
        blockHeight: blockHeight,
        breakSpanBlocks: breakSpanBlocks,
        palette: palette(scheme, "classtable.noon_break"),
      ),
      stripe(
        topBlocks: periodSpanBlocks * 8 + breakSpanBlocks,
        left: left,
        width: width,
        blockHeight: blockHeight,
        breakSpanBlocks: breakSpanBlocks,
        palette: palette(scheme, "classtable.supper_break"),
      ),
    ];
  }

  static Widget stripe({
    required double topBlocks,
    required double left,
    required double width,
    required double Function(double blocks) blockHeight,
    required double breakSpanBlocks,
    required ClassTableBreakPalette palette,
  }) {
    final borderColor = palette.foregroundColor.withValues(
      alpha: _stripeBorderAlpha,
    );
    return Positioned(
      top: blockHeight(topBlocks),
      height: blockHeight(breakSpanBlocks),
      left: left,
      width: width,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.backgroundColor.withValues(alpha: _stripeAlpha),
            border: Border(
              top: BorderSide(color: borderColor, width: _stripeBorderWidth),
              bottom: BorderSide(color: borderColor, width: _stripeBorderWidth),
            ),
          ),
        ),
      ),
    );
  }
}
