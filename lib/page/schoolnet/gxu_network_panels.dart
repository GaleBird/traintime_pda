// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/page/schoolnet/gxu_network_formatter.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';

class GxuNetworkNoticeCard extends StatelessWidget {
  const GxuNetworkNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final foreground = Colors.orange[900]!;
    return [
          Icon(
            Icons.info_outline,
            size: 18,
            color: foreground,
          ).padding(right: 8),
          Expanded(
            child: Text(
              FlutterI18n.translate(
                context,
                "school_net.gxu.cache_hint_compact",
              ),
              style: TextStyle(fontSize: 12.5, color: foreground, height: 1.35),
            ),
          ),
        ]
        .toRow(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(horizontal: 12, vertical: 10)
        .decorated(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        )
        .width(double.infinity);
  }
}

class GxuNetworkNoCacheCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const GxuNetworkNoCacheCard({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return [
          Icon(
            Icons.wifi_tethering_off_rounded,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            FlutterI18n.translate(context, "school_net.gxu.no_cache_title"),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            FlutterI18n.translate(context, "school_net.gxu.no_cache_body"),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(FlutterI18n.translate(context, "school_net.refresh")),
          ),
        ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.center)
        .padding(all: 24)
        .constrained(maxWidth: sheetMaxWidth)
        .center()
        .card(elevation: 0);
  }
}

class GxuNetworkStatusBanner extends StatelessWidget {
  final String errorText;
  final bool isPasswordError;

  const GxuNetworkStatusBanner({
    super.key,
    required this.errorText,
    required this.isPasswordError,
  });

  @override
  Widget build(BuildContext context) {
    final titleKey = isPasswordError
        ? "school_net.gxu.cache_need_password"
        : "school_net.gxu.cache_refresh_failed";
    final background = isPasswordError ? Colors.amber[50] : Colors.red[50];
    final border = isPasswordError ? Colors.amber[200]! : Colors.red[200]!;
    final foreground = isPasswordError ? Colors.amber[900] : Colors.red[900];
    return [
          Icon(
            isPasswordError ? Icons.info_outline : Icons.warning_amber_rounded,
            color: foreground,
          ).padding(right: 10),
          Expanded(
            child: [
              Text(
                FlutterI18n.translate(context, titleKey),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (!isPasswordError)
                Text(
                  errorText,
                  style: TextStyle(color: foreground, height: 1.35),
                ).padding(top: 4),
            ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
          ),
        ]
        .toRow(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(all: 14)
        .decorated(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        );
  }
}

class GxuNetworkSummaryCard extends StatelessWidget {
  final GxuNetworkUsage usage;

  const GxuNetworkSummaryCard({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exactRefresh = FlutterI18n.translate(
      context,
      "school_net.gxu.refreshed_at",
      translationParams: {"time": formatGxuRefreshExact(usage.refreshedAt)},
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: [
        Text(
          FlutterI18n.translate(context, "school_net.gxu.used"),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formatGxuTrafficInGb(usage.usedTraffic),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryChip(
              icon: Icons.history,
              label: FlutterI18n.translate(
                context,
                "homepage.school_net.cache_age",
                translationParams: {
                  "age": formatGxuRefreshAge(context, usage.refreshedAt),
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          exactRefresh,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
    );
  }
}

class GxuNetworkActionButtons extends StatelessWidget {
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onChangePassword;

  const GxuNetworkActionButtons({
    super.key,
    required this.refreshing,
    required this.onRefresh,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: refreshing ? null : onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(FlutterI18n.translate(context, "school_net.refresh")),
        ),
        OutlinedButton.icon(
          onPressed: onChangePassword,
          icon: const Icon(Icons.password),
          label: Text(
            FlutterI18n.translate(
              context,
              "setting.change_schoolnet_password_title",
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ].toRow(mainAxisSize: MainAxisSize.min),
    );
  }
}
