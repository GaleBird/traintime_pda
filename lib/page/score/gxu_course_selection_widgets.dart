import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_selection.dart';
import 'package:watermeter/page/score/gxu_course_selection_entry_card.dart';
import 'package:watermeter/page/score/gxu_course_selection_state.dart';

class GxuCourseSelectionSemesterSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<GxuCourseSelectionEntry> entries;
  final GxuCourseSelectionSummary summary;

  const GxuCourseSelectionSemesterSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _SummaryTag(
                      label: FlutterI18n.translate(
                        context,
                        "score.course_selection.total_courses",
                      ),
                      value: "${summary.courseCount}",
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryTag(
                      label: FlutterI18n.translate(
                        context,
                        "score.course_selection.degree_courses",
                      ),
                      value: "${summary.degreeCourseCount}",
                    ),
                    _SummaryTag(
                      label: FlutterI18n.translate(
                        context,
                        "score.course_selection.degree_credits",
                      ),
                      value: summary.degreeCredits.toStringAsFixed(2),
                    ),
                    _SummaryTag(
                      label: FlutterI18n.translate(
                        context,
                        "score.course_selection.non_degree_courses",
                      ),
                      value: "${summary.nonDegreeCourseCount}",
                    ),
                    _SummaryTag(
                      label: FlutterI18n.translate(
                        context,
                        "score.course_selection.non_degree_credits",
                      ),
                      value: summary.nonDegreeCredits.toStringAsFixed(2),
                    ),
                    _SummaryTag(
                      label: FlutterI18n.translate(
                        context,
                        "score.course_selection.total_credits",
                      ),
                      value: summary.totalCredits.toStringAsFixed(2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GxuCourseSelectionEntryCard(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          text: "$label ",
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
