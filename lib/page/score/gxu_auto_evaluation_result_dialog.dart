import 'package:flutter/material.dart';

const _spaceSm = 8.0;
const _spaceMd = 12.0;
const _spaceLg = 16.0;

Future<void> showGxuAutoEvaluationResultDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => GxuAutoEvaluationResultDialog(message: message),
  );
}

class GxuAutoEvaluationResultDialog extends StatelessWidget {
  final String message;

  const GxuAutoEvaluationResultDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.check_circle_outline, color: scheme.primary),
      title: const Text('课程评价结果'),
      content: Text(message, style: const TextStyle(height: 1.45)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        _spaceLg,
        _spaceSm,
        _spaceLg,
        _spaceMd,
      ),
    );
  }
}
