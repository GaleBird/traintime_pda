import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class ContributionRow extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String bodyKey;

  const ContributionRow({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FlutterI18n.translate(context, titleKey),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                FlutterI18n.translate(context, bodyKey),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NoticeRow extends StatelessWidget {
  final String textKey;
  final Map<String, String>? translationParams;

  const NoticeRow({super.key, required this.textKey, this.translationParams});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            FlutterI18n.translate(
              context,
              textKey,
              translationParams: translationParams,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
