import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/score/gxu_course_selection_state.dart';

class GxuCourseSelectionSemesterFilters extends StatelessWidget {
  static const double _radius = 14;

  final GxuCourseSelectionState state;

  const GxuCourseSelectionSemesterFilters({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: state.selectedSemesterCode,
      isExpanded: true,
      borderRadius: BorderRadius.circular(_radius),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_month_rounded),
        labelText: FlutterI18n.translate(
          context,
          "score.course_selection.semester_filter_label",
        ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      items: [
        DropdownMenuItem<String>(
          value: "",
          child: Text(FlutterI18n.translate(context, "score.all_semester")),
        ),
        ...state.semesterCodes.map(
          (code) => DropdownMenuItem<String>(
            value: code,
            child: Text(
              state.semesterLabelOf(code),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) => state.selectedSemesterCode = value ?? "",
    );
  }
}

class GxuCourseSelectionCategoryFilters extends StatelessWidget {
  final GxuCourseSelectionState state;

  const GxuCourseSelectionCategoryFilters({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<GxuCourseCategoryFilter>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: GxuCourseCategoryFilter.all,
            label: Text(
              FlutterI18n.translate(
                context,
                "score.course_selection.filter_all",
              ),
            ),
          ),
          ButtonSegment(
            value: GxuCourseCategoryFilter.degree,
            label: Text(
              FlutterI18n.translate(
                context,
                "score.course_selection.filter_degree",
              ),
            ),
          ),
          ButtonSegment(
            value: GxuCourseCategoryFilter.nonDegree,
            label: Text(
              FlutterI18n.translate(
                context,
                "score.course_selection.filter_non_degree",
              ),
            ),
          ),
        ],
        selected: {state.categoryFilter},
        onSelectionChanged: (selection) {
          if (selection.isEmpty) {
            return;
          }
          state.categoryFilter = selection.first;
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStatePropertyAll(textStyle),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }
}
