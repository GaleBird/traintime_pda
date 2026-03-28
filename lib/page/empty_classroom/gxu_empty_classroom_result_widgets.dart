import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_status_chip.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_result_state_cards.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';
import 'package:watermeter/page/public_widget/empty_list_view.dart';
import 'package:watermeter/repository/network_session.dart';

class GxuEmptyClassroomResultSliver extends StatelessWidget {
  final GxuEmptyClassroomState state;
  final TextEditingController searchController;

  const GxuEmptyClassroomResultSliver({
    super.key,
    required this.state,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return _buildLoadingSliver();
    }
    final toolbar = _buildToolbar();
    if (state.filteredRows.isEmpty) {
      return _buildEmptySliver(context, toolbar);
    }
    return _buildResultListSliver(context, toolbar);
  }

  bool get _isInitialLoading =>
      state.resultState == SessionState.fetching && state.result == null;

  Widget _buildLoadingSliver() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  _ResultToolbar? _buildToolbar() {
    if (state.result == null) {
      return null;
    }
    return _ResultToolbar(state: state, searchController: searchController);
  }

  Widget _buildEmptySliver(BuildContext context, _ResultToolbar? toolbar) {
    final emptyState = _buildEmptyState(context);
    if (toolbar == null) {
      return SliverToBoxAdapter(child: emptyState);
    }
    return SliverList(
      delegate: SliverChildListDelegate([
        toolbar,
        const SizedBox(height: 12),
        emptyState,
      ]),
    );
  }

  Widget _buildResultListSliver(BuildContext context, _ResultToolbar? toolbar) {
    final rows = state.visibleRows;
    final prefixCount = toolbar == null ? 0 : 2;
    final showLoadMore = state.hasMoreRows;
    final childCount = prefixCount + rows.length + (showLoadMore ? 1 : 0);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (toolbar != null) {
            if (index == 0) {
              return toolbar;
            }
            if (index == 1) {
              return const SizedBox(height: 12);
            }
            index -= 2;
          }
          if (index < rows.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClassroomCard(row: rows[index]),
            );
          }
          return _buildLoadMoreButton(context, rows.length);
        },
        childCount: childCount,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context, int shownRows) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: state.loadMoreRows,
        icon: const Icon(Icons.expand_more_rounded),
        label: Text(
          FlutterI18n.translate(
            context,
            "empty_classroom.load_more",
            translationParams: {
              "shown": shownRows.toString(),
              "total": state.totalRowCount.toString(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (state.resultState == SessionState.none) {
      return GxuEmptyClassroomHintStateCard(
        icon: Icons.tune_rounded,
        title: FlutterI18n.translate(
          context,
          "empty_classroom.result_idle_title",
        ),
        message: FlutterI18n.translate(
          context,
          "empty_classroom.result_idle_hint",
        ),
      );
    }
    if (state.resultState == SessionState.error) {
      return GxuEmptyClassroomInlineStateCard(
        icon: Icons.sync_problem_rounded,
        title: FlutterI18n.translate(context, "empty_classroom.query_failed"),
        message:
            state.resultError ?? FlutterI18n.translate(context, "query_failed"),
        actionLabel: FlutterI18n.translate(context, "click_to_refresh"),
        onPressed: state.refreshResults,
      );
    }
    final text = state.searchKeyword.trim().isEmpty
        ? FlutterI18n.translate(context, "empty_classroom.no_result")
        : FlutterI18n.translate(
            context,
            "empty_classroom.no_result_with_keyword",
            translationParams: {"keyword": state.searchKeyword.trim()},
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: EmptyListView(text: text, type: EmptyListViewType.reading),
    );
  }
}

class _ResultToolbar extends StatelessWidget {
  final GxuEmptyClassroomState state;
  final TextEditingController searchController;

  const _ResultToolbar({required this.state, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          const SizedBox(height: 6),
          _buildHint(context, scheme),
          const SizedBox(height: 12),
          _buildSearchField(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      FlutterI18n.translate(context, "empty_classroom.result_title"),
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildHint(BuildContext context, ColorScheme scheme) {
    return Text(
      FlutterI18n.translate(
        context,
        "empty_classroom.result_hint",
        translationParams: {
          "shown": state.visibleRows.length.toString(),
          "total": state.totalRowCount.toString(),
        },
      ),
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: searchController,
      onChanged: (value) => state.searchKeyword = value,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: FlutterI18n.translate(
          context,
          "empty_classroom.result_search_hint",
        ),
        suffixIcon: state.searchKeyword.isEmpty
            ? null
            : IconButton(
                onPressed: () => state.searchKeyword = "",
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final GxuEmptyClassroomRow row;

  const _ClassroomCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, scheme),
            const SizedBox(height: 12),
            _buildHint(context, scheme),
            const SizedBox(height: 12),
            _buildCells(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (row.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  row.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        _AvailabilityBadge(
          availableCount: row.availableCount,
          totalCount: row.totalCount,
        ),
      ],
    );
  }

  Widget _buildHint(BuildContext context, ColorScheme scheme) {
    return Text(
      FlutterI18n.translate(context, "empty_classroom.cell_hint"),
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  Widget _buildCells() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final cell in row.cells) GxuEmptyClassroomStatusChip(cell: cell),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final int availableCount;
  final int totalCount;

  const _AvailabilityBadge({
    required this.availableCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "$availableCount/$totalCount",
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
