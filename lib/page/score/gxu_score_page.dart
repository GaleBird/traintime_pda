import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/public_widget/empty_list_view.dart';
import 'package:watermeter/page/score/gxu_score_state.dart';
import 'package:watermeter/page/score/score_statics.dart';
import 'package:watermeter/page/score/gxu_score_widgets.dart';

class GxuScorePage extends StatefulWidget {
  const GxuScorePage({super.key});

  @override
  State<GxuScorePage> createState() => _GxuScorePageState();
}

class _GxuScorePageState extends State<GxuScorePage> {
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
    return Consumer<GxuScoreState>(
      builder: (context, state, _) {
        final sheet = state.sheet;
        if (sheet == null) {
          return const SizedBox.shrink();
        }
        _syncSearchController(state.search);
        return Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  GxuScoreArchiveCard(profile: sheet.profile),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => state.search = value,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: FlutterI18n.translate(
                        context,
                        "score.score_page.search_hint",
                      ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GxuSemesterFilters(state: state),
                  const SizedBox(height: 12),
                  if (state.groupedEntries.isEmpty)
                    EmptyListView(
                      text: FlutterI18n.translate(
                        context,
                        "score.gxu_page.no_record",
                      ),
                      type: EmptyListViewType.reading,
                    )
                  else
                    ...state.groupedEntries.entries.map(
                      (section) => GxuSemesterSection(
                        title: state.semesterLabelOf(section.key),
                        subtitle: section.key,
                        entries: section.value,
                        state: state,
                      ),
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => state.setSelectMode(!state.isSelectMode),
            child: const Icon(Icons.calculate),
          ),
          bottomNavigationBar: Visibility(
            visible: state.isSelectMode,
            child: BottomAppBar(
              height: 136,
              elevation: 5.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () =>
                            state.setVisibleSelectionState(ChoiceState.all),
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "score.score_page.select_all",
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () =>
                            state.setVisibleSelectionState(ChoiceState.none),
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "score.score_page.select_nothing",
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => state.setVisibleSelectionState(
                          ChoiceState.original,
                        ),
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "score.score_page.reset_select",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text(state.bottomInfo(context))),
                      IconButton(
                        onPressed: () => _showSummaryDialog(context, state),
                        icon: const Icon(Icons.info),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  void _showSummaryDialog(BuildContext context, GxuScoreState state) {
    context.pushDialog(
      AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "score.score_choice.sum_dialog_title"),
        ),
        content: Text(state.dialogSummary(context)),
      ),
    );
  }
}
