import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/page/public_widget/empty_list_view.dart';
import 'package:watermeter/page/score/gxu_course_selection_filter_widgets.dart';
import 'package:watermeter/page/score/gxu_course_selection_summary_card.dart';
import 'package:watermeter/page/score/gxu_course_selection_state.dart';
import 'package:watermeter/page/score/gxu_course_selection_widgets.dart';

class GxuCourseSelectionPage extends StatefulWidget {
  const GxuCourseSelectionPage({super.key});

  @override
  State<GxuCourseSelectionPage> createState() => _GxuCourseSelectionPageState();
}

class _GxuCourseSelectionPageState extends State<GxuCourseSelectionPage> {
  static const double _controlPanelRadius = 22;
  static const EdgeInsets _controlPanelPadding = EdgeInsets.fromLTRB(
    10,
    10,
    10,
    10,
  );

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GxuCourseSelectionState>(
      builder: (context, state, _) {
        if (state.sheet == null) {
          return const SizedBox.shrink();
        }
        _syncSearchController(state.search);
        final groupedEntries = state.groupedEntries;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                GxuCourseSelectionSummaryCard(
                  summary: state.summary,
                  semesterLabel: _semesterLabel(context, state),
                  categoryLabel: _categoryLabel(context, state),
                  searchKeyword: state.search,
                ),
                const SizedBox(height: 14),
                _FilterPanel(
                  state: state,
                  searchController: _searchController,
                  onClearSearch: _clearSearch,
                ),
                const SizedBox(height: 12),
                if (groupedEntries.isEmpty)
                  EmptyListView(
                    text: FlutterI18n.translate(
                      context,
                      "score.course_selection.no_record",
                    ),
                    type: EmptyListViewType.reading,
                  )
                else
                  ...groupedEntries.entries.map(
                    (section) => GxuCourseSelectionSemesterSection(
                      title: state.semesterLabelOf(section.key),
                      subtitle: section.key,
                      entries: section.value,
                      summary: state.summaryOf(section.key),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _semesterLabel(BuildContext context, GxuCourseSelectionState state) {
    if (state.selectedSemesterCode.isEmpty) {
      return FlutterI18n.translate(context, "score.all_semester");
    }
    return state.semesterLabelOf(state.selectedSemesterCode);
  }

  String _categoryLabel(BuildContext context, GxuCourseSelectionState state) {
    return switch (state.categoryFilter) {
      GxuCourseCategoryFilter.all => FlutterI18n.translate(
        context,
        "score.course_selection.filter_all",
      ),
      GxuCourseCategoryFilter.degree => FlutterI18n.translate(
        context,
        "score.course_selection.filter_degree",
      ),
      GxuCourseCategoryFilter.nonDegree => FlutterI18n.translate(
        context,
        "score.course_selection.filter_non_degree",
      ),
    };
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<GxuCourseSelectionState>().search = "";
  }

  void _syncSearchController(String value) {
    if (_searchController.text == value) {
      return;
    }
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final GxuCourseSelectionState state;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  const _FilterPanel({
    required this.state,
    required this.searchController,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final searchField = TextField(
      controller: searchController,
      onChanged: (value) => state.search = value,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: FlutterI18n.translate(
          context,
          "score.course_selection.search_hint",
        ),
        suffixIcon: state.search.isEmpty
            ? null
            : IconButton(
                onPressed: onClearSearch,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );

    return Container(
      padding: _GxuCourseSelectionPageState._controlPanelPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          _GxuCourseSelectionPageState._controlPanelRadius,
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              if (!isWide) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    GxuCourseSelectionSemesterFilters(state: state),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: searchField),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: GxuCourseSelectionSemesterFilters(state: state),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          GxuCourseSelectionCategoryFilters(state: state),
        ],
      ),
    );
  }
}
