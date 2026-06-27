import 'package:flutter/material.dart';
import 'package:watermeter/page/score/gxu_auto_evaluation_disclaimer_dialog.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:watermeter/page/score/gxu_auto_evaluation_disclaimer_dialog.dart';

const _spaceXs = 4.0;
const _spaceSm = 8.0;
const _spaceMd = 12.0;
const _spaceLg = 16.0;
const _spaceXl = 24.0;
const _wideCardBreakpoint = 560.0;
const _requiredCardMaxWidth = 520.0;
const _fetchingMaxWidth = 460.0;

Future<void> openGxuOfficialEvaluation(BuildContext context) async {
  final opened = await launchUrl(
    gxuCourseEvaluationOfficialUri,
    mode: LaunchMode.externalApplication,
  );
  if (context.mounted && !opened) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法打开官网评教页面')));
  }
}

Future<void> confirmAndRunGxuAutoEvaluation(
  BuildContext context,
  VoidCallback onAutoEvaluate,
) async {
  final confirmed = await showGxuAutoEvaluationDisclaimerDialog(context);
  if (confirmed && context.mounted) {
    onAutoEvaluate();
  }
}

class GxuScoreFetchingView extends StatelessWidget {
  final bool isAutoEvaluating;
  final String? autoEvaluationStatus;

  const GxuScoreFetchingView({
    super.key,
    this.isAutoEvaluating = false,
    this.autoEvaluationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = isAutoEvaluating ? '正在检查课程评价并刷新成绩' : '正在查询成绩';
    final subtitle = isAutoEvaluating
        ? autoEvaluationStatus ?? '正在确认是否还有待评课程；如果已完成，会直接刷新成绩并提示结果。'
        : '如果系统提示需先评教，会显示后续处理入口。';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_spaceXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _fetchingMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: _spaceXl),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: _spaceSm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GxuAutoEvaluationFeedbackBanner extends StatelessWidget {
  final String message;

  const GxuAutoEvaluationFeedbackBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(_spaceMd),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(_spaceLg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: scheme.primary),
          const SizedBox(width: _spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '课程评价结果',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: _spaceXs),
                Text(message, style: TextStyle(color: scheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GxuScoreEvaluationRequiredView extends StatelessWidget {
  final String? error;
  final VoidCallback onOpenOfficial;
  final VoidCallback onAutoEvaluate;

  const GxuScoreEvaluationRequiredView({
    super.key,
    required this.error,
    required this.onOpenOfficial,
    required this.onAutoEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_spaceXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _requiredCardMaxWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_outlined, color: scheme.primary),
                  const SizedBox(height: _spaceMd),
                  Text(
                    '需要先完成课程评价',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: _spaceSm),
                  Text(
                    error ?? '研究生成绩单暂时不可查询。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: _spaceLg),
                  _EvaluationActionButtons(
                    onOpenOfficial: onOpenOfficial,
                    onAutoEvaluate: () =>
                        confirmAndRunGxuAutoEvaluation(context, onAutoEvaluate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GxuCourseEvaluationEntryCard extends StatelessWidget {
  final VoidCallback onOpenOfficial;
  final VoidCallback onAutoEvaluate;

  const GxuCourseEvaluationEntryCard({
    super.key,
    required this.onOpenOfficial,
    required this.onAutoEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideCardBreakpoint;
        return Container(
          padding: const EdgeInsets.all(_spaceLg),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(_spaceXl),
            border: Border.all(color: accent.withValues(alpha: 0.14)),
          ),
          child: isWide ? _wideContent(context) : _narrowContent(context),
        );
      },
    );
  }

  Widget _wideContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: _EvaluationIntro()),
        const SizedBox(width: _spaceLg),
        _EvaluationActionButtons(
          onOpenOfficial: onOpenOfficial,
          onAutoEvaluate: () =>
              confirmAndRunGxuAutoEvaluation(context, onAutoEvaluate),
        ),
      ],
    );
  }

  Widget _narrowContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EvaluationIntro(),
        const SizedBox(height: _spaceMd),
        _EvaluationActionButtons(
          expanded: true,
          onOpenOfficial: onOpenOfficial,
          onAutoEvaluate: () =>
              confirmAndRunGxuAutoEvaluation(context, onAutoEvaluate),
        ),
      ],
    );
  }
}

class _EvaluationIntro extends StatelessWidget {
  const _EvaluationIntro();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _EvaluationIcon(),
        const SizedBox(width: _spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '课程评价',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvaluationIcon extends StatelessWidget {
  const _EvaluationIcon();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.rate_review_outlined,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

class _EvaluationActionButtons extends StatelessWidget {
  final VoidCallback onOpenOfficial;
  final VoidCallback onAutoEvaluate;
  final bool expanded;

  const _EvaluationActionButtons({
    required this.onOpenOfficial,
    required this.onAutoEvaluate,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Row(
        children: [
          Expanded(child: _officialButton()),
          const SizedBox(width: _spaceMd),
          Expanded(child: _autoButton()),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _spaceMd,
      runSpacing: _spaceSm,
      children: [_officialButton(), _autoButton()],
    );
  }

  Widget _officialButton() {
    return OutlinedButton.icon(
      onPressed: onOpenOfficial,
      icon: const Icon(Icons.open_in_browser),
      label: const Text('官网评教'),
    );
  }

  Widget _autoButton() {
    return FilledButton.icon(
      onPressed: onAutoEvaluate,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('自动评教'),
    );
  }
}
