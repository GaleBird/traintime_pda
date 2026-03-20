import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class GxuCourseSelectionSummaryHeadline extends StatelessWidget {
  static const double _sectionGap = 8;
  static const double _subtitleGap = 2;

  final String semesterLabel;
  final String categoryLabel;
  final String searchKeyword;
  final String subtitle;

  const GxuCourseSelectionSummaryHeadline({
    super.key,
    required this.semesterLabel,
    required this.categoryLabel,
    required this.searchKeyword,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FlutterI18n.translate(context, "score.course_selection.summary"),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: _subtitleGap),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onPrimaryContainer.withValues(alpha: 0.88),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: _sectionGap),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GxuCourseSelectionScopeChip(
              icon: Icons.calendar_month_rounded,
              text: semesterLabel,
            ),
            GxuCourseSelectionScopeChip(
              icon: Icons.tune_rounded,
              text: categoryLabel,
            ),
            if (searchKeyword.trim().isNotEmpty)
              GxuCourseSelectionScopeChip(
                icon: Icons.search_rounded,
                text: searchKeyword.trim(),
              ),
          ],
        ),
      ],
    );
  }
}

class GxuCourseSelectionSummaryMetricTag extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const GxuCourseSelectionSummaryMetricTag({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class GxuCourseSelectionScopeChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const GxuCourseSelectionScopeChip({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
