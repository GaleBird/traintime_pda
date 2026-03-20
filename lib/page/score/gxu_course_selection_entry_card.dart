import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_selection.dart';

const _cardRadius = 20.0;
const _stripeWidth = 4.0;
const _backgroundAlpha = 0.08;
const _borderAlpha = 0.22;
const _stripeAlpha = 0.9;
const _badgeAlpha = 0.18;
const _gapTight = 4.0;
const _gapNormal = 6.0;
const _chipSpacing = 8.0;
const _infoIconGap = 6.0;
const _chipIconSize = 14.0;
const _infoIconSize = 15.0;
const _chipIconGap = 6.0;
const _titleMaxLines = 2;
const _contentPadding = EdgeInsets.fromLTRB(_stripeWidth + 12, 10, 12, 10);
const _chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
const _chipRadius = 999.0;

class GxuCourseSelectionEntryCard extends StatelessWidget {
  final GxuCourseSelectionEntry entry;

  const GxuCourseSelectionEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDegree = entry.isDegreeCourse;
    final scheme = Theme.of(context).colorScheme;
    final accent = isDegree ? scheme.primary : scheme.secondary;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _backgroundAlpha),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: accent.withValues(alpha: _borderAlpha)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _stripeWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: _stripeAlpha),
              ),
            ),
          ),
          Padding(
            padding: _contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CourseTitle(entry: entry),
                const SizedBox(height: _gapTight),
                _CourseCode(entry: entry),
                if (entry.primaryTeacher.isNotEmpty) ...[
                  const SizedBox(height: _gapNormal),
                  _CourseInfoRow(
                    icon: Icons.person_outline_rounded,
                    text: entry.primaryTeacher,
                  ),
                ],
                const SizedBox(height: _gapNormal),
                _CourseChips(
                  entry: entry,
                  isDegree: isDegree,
                  accentColor: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseTitle extends StatelessWidget {
  final GxuCourseSelectionEntry entry;

  const _CourseTitle({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Text(
      entry.courseName,
      maxLines: _titleMaxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _CourseCode extends StatelessWidget {
  final GxuCourseSelectionEntry entry;

  const _CourseCode({required this.entry});

  @override
  Widget build(BuildContext context) {
    final classInfo = [
      entry.classNumber,
      entry.className,
    ].where((item) => item.trim().isNotEmpty).join(" ");
    return Text(
      [
        "${FlutterI18n.translate(context, "score.gxu_page.course_code")}: ${entry.courseCode}",
        if (classInfo.isNotEmpty) classInfo,
      ].join("  ·  "),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _CourseInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CourseInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: _infoIconSize, color: style?.color),
        ),
        const SizedBox(width: _infoIconGap),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

class _CourseChips extends StatelessWidget {
  final GxuCourseSelectionEntry entry;
  final bool isDegree;
  final Color accentColor;

  const _CourseChips({
    required this.entry,
    required this.isDegree,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBackground = accentColor.withValues(alpha: _badgeAlpha);
    final chips = <Widget>[
      _EntryChip(
        text: FlutterI18n.translate(
          context,
          isDegree
              ? "score.course_selection.badge_degree"
              : "score.course_selection.badge_non_degree",
        ),
        icon: isDegree ? Icons.school_rounded : Icons.extension_rounded,
        foregroundColor: accentColor,
        backgroundColor: badgeBackground,
        fontWeight: FontWeight.w700,
      ),
    ];
    if (entry.credit.trim().isNotEmpty) {
      chips.add(
        _EntryChip(
          text:
              "${FlutterI18n.translate(context, "score.score_compose_card.credit")} ${entry.credit}",
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (entry.courseType.trim().isNotEmpty) {
      chips.add(_EntryChip(text: entry.courseType));
    }
    if (entry.status.trim().isNotEmpty) {
      chips.add(_EntryChip(text: entry.status));
    }
    return Wrap(
      spacing: _chipSpacing,
      runSpacing: _chipSpacing,
      children: chips,
    );
  }
}

class _EntryChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final FontWeight? fontWeight;

  const _EntryChip({
    required this.text,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: foregroundColor ?? scheme.onSurface,
      fontWeight: fontWeight,
    );
    return Container(
      padding: _chipPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: icon == null
          ? Text(text, style: style)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: _chipIconSize, color: style?.color),
                const SizedBox(width: _chipIconGap),
                Text(text, style: style),
              ],
            ),
    );
  }
}
