// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/public_widget/app_icon.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';

class AppIconPage extends StatelessWidget {
  static const String _conceptAsset = 'assets/icon_gxu_concept.svg';

  const AppIconPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(context, 'setting.about_page.icon_page.title'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(_Layout.pagePadding),
        children: const [
          _IconHero(conceptAsset: _conceptAsset),
          SizedBox(height: _Layout.sectionGap),
          _DesignNotes(),
          SizedBox(height: _Layout.sectionGap),
          _Palette(),
          SizedBox(height: _Layout.sectionGap),
          _ShapePreview(conceptAsset: _conceptAsset),
        ],
      ),
    );
  }
}

class _Layout {
  static const double pagePadding = 16;
  static const double sectionGap = 16;
  static const double heroHeight = 232;
  static const double heroRadius = 26;
  static const double heroPadding = 18;
  static const double heroRowGap = 14;
  static const double heroTitleGap = 8;
  static const double heroSubtitleGap = 12;
  static const double heroCopyRightPadding = 10;
  static const double heroSurfaceAlpha = 0.92;
  static const double heroBorderAlpha = 0.50;
  static const double iconSize = 116;
  static const double miniIconSize = 54;
  static const double miniIconGap = 10;
  static const double miniIconLabelGap = 6;
  static const double iconStackGap = 12;
  static const double watermarkOpacity = 0.06;
  static const double patternOpacity = 0.10;
  static const double watermarkRight = -34;
  static const double watermarkBottom = -26;
  static const double watermarkWidth = 320;
  static const double iconRadius = 29 * iconSize / 120;
  static const double miniIconRadius = 29 * miniIconSize / 120;
}

class _GxuPalette {
  static const Color gxuGreen = Color(0xFF0F5E47);
  static const Color gxuGold = Color(0xFFD6B46A);
  static const Color paper = Color(0xFFF3F0E8);
}

class _IconHero extends StatelessWidget {
  static const String _gxuWordmark = 'assets/gxu_name.svg';
  static const int _patternSeed = 12;
  static const double _bgMix = 0.42;

  final String conceptAsset;
  const _IconHero({required this.conceptAsset});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base =
        Color.lerp(colorScheme.primaryContainer, colorScheme.surface, _bgMix) ??
        colorScheme.surface;

    return SizedBox(
      height: _Layout.heroHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_Layout.heroRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base,
                colorScheme.surface.withValues(alpha: _Layout.heroSurfaceAlpha),
              ],
            ),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: _Layout.heroBorderAlpha,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: _Layout.patternOpacity,
                  child: CustomPaint(
                    painter: _LeafPatternPainter(
                      seed: _patternSeed,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: _Layout.watermarkRight,
                bottom: _Layout.watermarkBottom,
                child: Opacity(
                  opacity: _Layout.watermarkOpacity,
                  child: SizedBox(
                    width: _Layout.watermarkWidth,
                    child: SvgPicture.asset(
                      _gxuWordmark,
                      colorFilter: ColorFilter.mode(
                        colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_Layout.heroPadding),
                child: Row(
                  children: [
                    const Expanded(child: _HeroCopy()),
                    const SizedBox(width: _Layout.heroRowGap),
                    _IconStack(conceptAsset: conceptAsset),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final title = FlutterI18n.translate(
      context,
      'setting.about_page.icon_page.hero_title',
    );
    final subtitle = FlutterI18n.translate(
      context,
      'setting.about_page.icon_page.hero_subtitle',
    );
    final hint = FlutterI18n.translate(
      context,
      'setting.about_page.icon_page.hero_hint',
    );

    return [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: _Layout.heroTitleGap),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: _Layout.heroSubtitleGap),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(right: _Layout.heroCopyRightPadding);
  }
}

class _IconStack extends StatelessWidget {
  static const double _ringStroke = 2.5;
  static const double _outlineAlpha = 0.70;

  final String conceptAsset;
  const _IconStack({required this.conceptAsset});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: _outlineAlpha);

    return [
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_Layout.iconRadius),
          border: Border.all(width: _ringStroke, color: outline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_Layout.iconRadius),
          child: SvgPicture.asset(
            conceptAsset,
            width: _Layout.iconSize,
            height: _Layout.iconSize,
          ),
        ),
      ),
      const SizedBox(height: _Layout.iconStackGap),
      [
        _MiniIcon(
          labelKey: 'setting.about_page.icon_page.current',
          icon: const AppIconWidget(size: _Layout.miniIconSize),
        ),
        const SizedBox(width: _Layout.miniIconGap),
        _MiniIcon(
          labelKey: 'setting.about_page.icon_page.concept',
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(_Layout.miniIconRadius),
            child: SvgPicture.asset(
              conceptAsset,
              width: _Layout.miniIconSize,
              height: _Layout.miniIconSize,
            ),
          ),
        ),
      ].toRow(),
    ].toColumn(crossAxisAlignment: CrossAxisAlignment.center);
  }
}

class _MiniIcon extends StatelessWidget {
  final String labelKey;
  final Widget icon;
  const _MiniIcon({required this.labelKey, required this.icon});

  @override
  Widget build(BuildContext context) {
    final label = FlutterI18n.translate(context, labelKey);

    return [
      icon,
      const SizedBox(height: _Layout.miniIconLabelGap),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ].toColumn();
  }
}

class _DesignNotes extends StatelessWidget {
  const _DesignNotes();

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: Text(
        FlutterI18n.translate(context, 'setting.about_page.icon_page.notes'),
      ).padding(bottom: 8).center(),
      remaining: const [],
      bottomRow: Text(
        FlutterI18n.translate(
          context,
          'setting.about_page.icon_page.notes_body',
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  static const double _wrapSpacing = 12;
  static const double _wrapRunSpacing = 10;

  const _Palette();

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: Text(
        FlutterI18n.translate(context, 'setting.about_page.icon_page.palette'),
      ).padding(bottom: 8).center(),
      remaining: const [],
      bottomRow: Wrap(
        spacing: _wrapSpacing,
        runSpacing: _wrapRunSpacing,
        children: const [
          _Swatch(color: _GxuPalette.gxuGreen, nameKey: 'palette_green'),
          _Swatch(color: _GxuPalette.paper, nameKey: 'palette_paper'),
          _Swatch(color: _GxuPalette.gxuGold, nameKey: 'palette_gold'),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  static const double _dotSize = 14;
  static const double _radius = 14;
  static const double _borderOpacity = 0.22;
  static const double _surfaceAlpha = 0.82;
  static const double _rowGap = 10;
  static const double _padding = 12;

  final Color color;
  final String nameKey;
  const _Swatch({required this.color, required this.nameKey});

  @override
  Widget build(BuildContext context) {
    final title = FlutterI18n.translate(
      context,
      'setting.about_page.icon_page.$nameKey',
    );
    final border = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: _borderOpacity);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: _surfaceAlpha),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: _dotSize),
        ),
        const SizedBox(width: _rowGap),
        Text(title, style: Theme.of(context).textTheme.labelLarge),
      ].toRow(mainAxisSize: MainAxisSize.min).padding(all: _padding),
    );
  }
}

class _ShapePreview extends StatelessWidget {
  static const double _maskSize = 92;
  static const double _maskRadius = 29 * _maskSize / 120;
  static const double _labelGap = 10;

  final String conceptAsset;
  const _ShapePreview({required this.conceptAsset});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: Text(
        FlutterI18n.translate(context, 'setting.about_page.icon_page.shapes'),
      ).padding(bottom: 8).center(),
      remaining: const [],
      bottomRow: [
        _MaskedIcon(
          titleKey: 'shape_ios',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_maskRadius),
            child: SvgPicture.asset(
              conceptAsset,
              width: _maskSize,
              height: _maskSize,
            ),
          ),
        ),
        const SizedBox(width: _labelGap),
        _MaskedIcon(
          titleKey: 'shape_android',
          child: ClipOval(
            child: SvgPicture.asset(
              conceptAsset,
              width: _maskSize,
              height: _maskSize,
            ),
          ),
        ),
      ].toRow(mainAxisAlignment: MainAxisAlignment.spaceEvenly),
    );
  }
}

class _MaskedIcon extends StatelessWidget {
  static const double _shadowOpacity = 0.10;
  static const double _blur = 14;
  static const double _spread = 0.2;
  static const double _labelGap = 8;
  static const double _paddingVertical = 6;

  final String titleKey;
  final Widget child;
  const _MaskedIcon({required this.titleKey, required this.child});

  @override
  Widget build(BuildContext context) {
    final title = FlutterI18n.translate(
      context,
      'setting.about_page.icon_page.$titleKey',
    );

    return [
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: _shadowOpacity),
                  blurRadius: _blur,
                  spreadRadius: _spread,
                ),
              ],
            ),
            child: child,
          ),
          const SizedBox(height: _labelGap),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
        ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.center)
        .padding(vertical: _paddingVertical);
  }
}

class _LeafPatternPainter extends CustomPainter {
  static const int _count = 18;
  static const double _minScale = 0.55;
  static const double _maxScale = 1.35;
  static const double _strokeWidth = 1.6;
  static const double _alpha = 0.14;

  final int seed;
  final Color color;
  const _LeafPatternPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _strokeWidth
      ..color = color.withValues(alpha: _alpha);

    final leaf = _leafPath();
    for (var i = 0; i < _count; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      final rot = (rand.nextDouble() * math.pi) - (math.pi / 2);
      final scale = _minScale + (rand.nextDouble() * (_maxScale - _minScale));

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rot);
      canvas.scale(scale, scale);
      canvas.drawPath(leaf, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LeafPatternPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}

Path _leafPath() {
  const double w = 26;
  const double h = 38;
  const double mid = w / 2;

  return Path()
    ..moveTo(0, h * 0.60)
    ..cubicTo(2, h * 0.20, mid * 0.55, 0, mid, 0)
    ..cubicTo(mid * 1.45, 0, w - 2, h * 0.20, w, h * 0.60)
    ..cubicTo(w - 2, h * 0.92, mid * 1.15, h, mid, h)
    ..cubicTo(mid * 0.85, h, 2, h * 0.92, 0, h * 0.60)
    ..close()
    ..moveTo(mid, 6)
    ..quadraticBezierTo(mid - 2, h * 0.45, mid - 5, h - 6);
}
