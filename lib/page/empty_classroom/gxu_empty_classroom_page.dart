import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_panels.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_result_widgets.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';

class GxuEmptyClassroomPage extends StatefulWidget {
  const GxuEmptyClassroomPage({super.key});

  @override
  State<GxuEmptyClassroomPage> createState() => _GxuEmptyClassroomPageState();
}

class _GxuEmptyClassroomPageState extends State<GxuEmptyClassroomPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GxuEmptyClassroomState>();
    final form = state.form;
    if (form == null) {
      return const SizedBox.shrink();
    }
    _syncSearchController(state.searchKeyword);
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(state),
      notificationPredicate: (notification) =>
          state.result != null &&
          defaultScrollNotificationPredicate(notification),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: CustomScrollView(
            key: const PageStorageKey<String>('gxu_empty_classroom_page_list'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: GxuEmptyClassroomFilterPanel(form: form, state: state),
                ),
              ),
              if (state.result != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: GxuEmptyClassroomOverviewPanel(
                      state: state,
                      form: form,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: GxuEmptyClassroomResultSliver(
                  state: state,
                  searchController: _searchController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _handleRefresh(GxuEmptyClassroomState state) async {
    if (state.result == null) {
      return;
    }
    await state.refreshResults();
  }
}
