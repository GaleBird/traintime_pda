import 'package:flutter/material.dart';

const _gxuWordmarkAsset = 'assets/new_name_wordmark.png';
const _gxuWordmarkDarkTint = Color(0xFFF3F0E8);
const _gxuWordmarkDarkOpacity = 0.92;

class GxuWordmark extends StatelessWidget {
  const GxuWordmark({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.colorFilter,
    this.adaptToDarkTheme = false,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final ColorFilter? colorFilter;
  final bool adaptToDarkTheme;

  @override
  Widget build(BuildContext context) {
    final tint = colorFilter == null ? _resolveDarkThemeTint(context) : null;
    final image = Image.asset(
      _gxuWordmarkAsset,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
    );
    if (colorFilter == null) {
      return image;
    }
    return ColorFiltered(colorFilter: colorFilter!, child: image);
  }

  Color? _resolveDarkThemeTint(BuildContext context) {
    if (!adaptToDarkTheme) {
      return null;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return null;
    }
    return _gxuWordmarkDarkTint.withValues(alpha: _gxuWordmarkDarkOpacity);
  }
}
