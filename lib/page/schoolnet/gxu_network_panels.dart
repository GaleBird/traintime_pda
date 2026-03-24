// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/page/schoolnet/gxu_network_action_button.dart';
import 'package:watermeter/page/schoolnet/gxu_network_formatter.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';

const gxuNetworkPortalUrl = "http://self.gxu.edu.cn";

class GxuNetworkNoCacheCard extends StatelessWidget {
  const GxuNetworkNoCacheCard({super.key});

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
  final bool isCredentialError;

  const GxuNetworkStatusBanner({
    super.key,
    required this.errorText,
    required this.isCredentialError,
  });

  @override
  Widget build(BuildContext context) {
    final titleKey = isCredentialError
        ? "school_net.gxu.cache_need_credentials"
        : "school_net.gxu.cache_refresh_failed";
    final background = isCredentialError ? Colors.amber[50] : Colors.red[50];
    final border = isCredentialError ? Colors.amber[200]! : Colors.red[200]!;
    final foreground = isCredentialError ? Colors.amber[900] : Colors.red[900];
    return [
          Icon(
            isCredentialError
                ? Icons.info_outline
                : Icons.warning_amber_rounded,
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
              if (!isCredentialError)
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
  final String hintText;
  final VoidCallback onRefresh;
  final VoidCallback onChangePassword;
  final VoidCallback onOpenPortal;

  const GxuNetworkActionButtons({
    super.key,
    required this.refreshing,
    required this.hintText,
    required this.onRefresh,
    required this.onChangePassword,
    required this.onOpenPortal,
  });

  @override
  Widget build(BuildContext context) {
    return [
      Row(
        children: [
          Expanded(
            child: GxuNetworkActionButton(
              icon: Icons.refresh,
              label: FlutterI18n.translate(context, "school_net.refresh"),
              onPressed: refreshing ? null : onRefresh,
              filled: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GxuNetworkActionButton(
              icon: Icons.badge_outlined,
              label: FlutterI18n.translate(
                context,
                "school_net.gxu.account_short",
              ),
              onPressed: onChangePassword,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GxuNetworkActionButton(
              icon: Icons.open_in_new,
              label: FlutterI18n.translate(
                context,
                "school_net.gxu.portal_short",
              ),
              onPressed: onOpenPortal,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        hintText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    ].toColumn(crossAxisAlignment: CrossAxisAlignment.stretch);
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
