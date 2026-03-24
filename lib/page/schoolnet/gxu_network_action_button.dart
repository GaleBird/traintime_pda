import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class GxuNetworkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const GxuNetworkActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
    final style = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: textStyle,
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: textStyle,
          );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(height: 4),
        SizedBox(
          height: 14,
          child: AutoSizeText(
            label,
            maxLines: 1,
            minFontSize: 9,
            stepGranularity: 0.5,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: content)
        : OutlinedButton(onPressed: onPressed, style: style, child: content);
  }
}
