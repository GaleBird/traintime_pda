import 'package:flutter/material.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';

const _spaceMd = 12.0;

Future<bool> showGxuAutoEvaluationDisclaimerDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const GxuAutoEvaluationDisclaimerDialog(),
  );
  return result ?? false;
}

class GxuAutoEvaluationDisclaimerDialog extends StatefulWidget {
  final VoidCallback? onConfirmed;

  const GxuAutoEvaluationDisclaimerDialog({super.key, this.onConfirmed});

  @override
  State<GxuAutoEvaluationDisclaimerDialog> createState() =>
      _GxuAutoEvaluationDisclaimerDialogState();
}

class _GxuAutoEvaluationDisclaimerDialogState
    extends State<GxuAutoEvaluationDisclaimerDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自动评教免责声明'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AutoEvaluationRiskText(),
          const SizedBox(height: _spaceMd),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('我已知晓并确认执行自动评教'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _accepted ? _confirm : null,
          child: const Text('确认自动评教'),
        ),
      ],
    );
  }

  void _confirm() {
    widget.onConfirmed?.call();
    Navigator.of(context).maybePop(true);
  }
}

class _AutoEvaluationRiskText extends StatelessWidget {
  const _AutoEvaluationRiskText();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: gxuCourseEvaluationRiskText),
          TextSpan(
            text: '\n\n$gxuCourseEvaluationWarningText',
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
