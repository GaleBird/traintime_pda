import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/score/gxu_course_selection_state.dart';
import 'package:watermeter/page/score/gxu_course_selection_summary_card_parts.dart';

class GxuCourseSelectionSummaryCard extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(12, 12, 12, 12);

  final GxuCourseSelectionSummary summary;
  final String semesterLabel;
  final String categoryLabel;
  final String searchKeyword;

  const GxuCourseSelectionSummaryCard({
    super.key,
    required this.summary,
    required this.semesterLabel,
    required this.categoryLabel,
    required this.searchKeyword,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalCoursesLabel = FlutterI18n.translate(
      context,
      "score.course_selection.total_courses",
    );
    final totalCreditsLabel = FlutterI18n.translate(
      context,
      "score.course_selection.total_credits",
    );
    final subtitle =
        "${summary.courseCount} $totalCoursesLabel · "
        "${summary.totalCredits.toStringAsFixed(2)} $totalCreditsLabel";
    final metricTags = [
      GxuCourseSelectionSummaryMetricTag(
        label: totalCreditsLabel,
        value: summary.totalCredits.toStringAsFixed(2),
        accentColor: scheme.primary,
      ),
      GxuCourseSelectionSummaryMetricTag(
        label: totalCoursesLabel,
        value: summary.courseCount.toString(),
        accentColor: scheme.primary,
      ),
      GxuCourseSelectionSummaryMetricTag(
        label: FlutterI18n.translate(
          context,
          "score.course_selection.degree_courses",
        ),
        value: summary.degreeCourseCount.toString(),
        accentColor: scheme.primary,
      ),
      GxuCourseSelectionSummaryMetricTag(
        label: FlutterI18n.translate(
          context,
          "score.course_selection.degree_credits",
        ),
        value: summary.degreeCredits.toStringAsFixed(2),
        accentColor: scheme.primary,
      ),
      GxuCourseSelectionSummaryMetricTag(
        label: FlutterI18n.translate(
          context,
          "score.course_selection.non_degree_courses",
        ),
        value: summary.nonDegreeCourseCount.toString(),
        accentColor: scheme.secondary,
      ),
      GxuCourseSelectionSummaryMetricTag(
        label: FlutterI18n.translate(
          context,
          "score.course_selection.non_degree_credits",
        ),
        value: summary.nonDegreeCredits.toStringAsFixed(2),
        accentColor: scheme.secondary,
      ),
    ];

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GxuCourseSelectionSummaryHeadline(
            semesterLabel: semesterLabel,
            categoryLabel: categoryLabel,
            searchKeyword: searchKeyword,
            subtitle: subtitle,
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: metricTags),
        ],
      ),
    );
  }
}
