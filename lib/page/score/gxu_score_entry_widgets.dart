import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';

class GxuScoreEntryCard extends StatelessWidget {
  final GxuScoreEntry entry;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;

  const GxuScoreEntryCard({
    super.key,
    required this.entry,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context, entry.scoreValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: isSelectMode && !isSelected ? 0.42 : 1,
        child: Material(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EntryBody(
                      entry: entry,
                      isSelectMode: isSelectMode,
                      isSelected: isSelected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _EntryScore(entry: entry, accent: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(BuildContext context, double? score) {
    final scheme = Theme.of(context).colorScheme;
    if (score == null) return scheme.primary;
    if (score < 60) return scheme.error;
    if (score >= 90) return scheme.tertiary;
    if (score >= 80) return scheme.primary;
    return scheme.secondary;
  }
}

class _EntryBody extends StatelessWidget {
  final GxuScoreEntry entry;
  final bool isSelectMode;
  final bool isSelected;

  const _EntryBody({
    required this.entry,
    required this.isSelectMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.courseName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (isSelectMode) ...[
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DetailTag(text: entry.courseType),
            _DetailTag(text: entry.examType),
            _DetailTag(
              text:
                  "${FlutterI18n.translate(context, "score.score_compose_card.credit")} ${entry.credit}",
            ),
            _DetailTag(
              text:
                  "${FlutterI18n.translate(context, "score.gxu_page.hours")} ${entry.totalHours}",
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "${FlutterI18n.translate(context, "score.gxu_page.course_code")}: ${entry.courseCode}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EntryScore extends StatelessWidget {
  final GxuScoreEntry entry;
  final Color accent;

  const _EntryScore({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          entry.score,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          "${FlutterI18n.translate(context, "score.score_compose_card.gpa")} ${entry.gpa}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DetailTag extends StatelessWidget {
  final String text;

  const _DetailTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

void showGxuScoreDetail(BuildContext context, GxuScoreEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _ScoreDetailSheet(entry: entry),
  );
}

class _ScoreDetailSheet extends StatelessWidget {
  final GxuScoreEntry entry;

  const _ScoreDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String>>[
      MapEntry(
        FlutterI18n.translate(context, "score.gxu_page.course_code"),
        entry.courseCode,
      ),
      MapEntry(
        FlutterI18n.translate(context, "score.gxu_page.course_type"),
        entry.courseType,
      ),
      MapEntry(
        FlutterI18n.translate(context, "score.gxu_page.exam_type"),
        entry.examType,
      ),
      MapEntry(
        FlutterI18n.translate(context, "score.score_compose_card.credit"),
        entry.credit,
      ),
      MapEntry(
        FlutterI18n.translate(context, "score.gxu_page.hours"),
        entry.totalHours,
      ),
      MapEntry(
        FlutterI18n.translate(context, "score.score_compose_card.score"),
        entry.score,
      ),
      MapEntry(
        FlutterI18n.translate(context, "score.score_compose_card.gpa"),
        entry.gpa,
      ),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            entry.courseName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (entry.englishCourseName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.englishCourseName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 18),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.key),
              subtitle: Text(item.value.isEmpty ? "-" : item.value),
            ),
          ),
        ],
      ),
    );
  }
}
