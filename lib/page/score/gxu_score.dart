import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/page/score/gxu_score_page.dart';
import 'package:watermeter/page/score/gxu_score_state.dart';
import 'package:watermeter/page/score/score_statics.dart';

class GxuScoreWindow extends StatelessWidget {
  const GxuScoreWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GxuScoreState(context),
      child: Consumer<GxuScoreState>(
        builder: (context, state, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                FlutterI18n.translate(context, "score.score_page.title"),
              ),
              actions: [
                if (state.state == ScoreFetchState.ok)
                  IconButton(
                    icon: const Icon(Icons.replay_outlined),
                    onPressed: () =>
                        state.refreshingState(context, isForce: true),
                  ),
              ],
            ),
            body: Builder(
              builder: (context) {
                switch (state.state) {
                  case ScoreFetchState.ok:
                    return const GxuScorePage();
                  case ScoreFetchState.error:
                    return ReloadWidget(
                      errorStatus: state.error,
                      function: () => state.refreshingState(context),
                    );
                  case ScoreFetchState.fetching:
                    return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          );
        },
      ),
    );
  }
}
