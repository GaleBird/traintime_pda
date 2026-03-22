// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/page/public_widget/captcha_input_dialog.dart';
import 'package:watermeter/page/public_widget/info_card.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/page/setting/dialogs/schoolnet_password_dialog.dart';
import 'package:watermeter/page/schoolnet/gxu_network_panels.dart';
import 'package:watermeter/repository/gxu_ids/gxu_schoolnet_credentials.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_session.dart';
import 'package:watermeter/repository/network_session.dart';

class GxuNetworkInfo extends StatelessWidget {
  const GxuNetworkInfo({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final usage = gxuNetworkInfo.value;
    if (usage == null) {
      return _buildEmptyBody(context);
    }
    return _buildContent(context, usage);
  });

  Widget _buildEmptyBody(BuildContext context) {
    if (gxuNetworkStatus.value == SessionState.fetching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (isGxuSchoolnetCredentialError(gxuNetworkError.value)) {
      return ReloadWidget(
        errorStatus: _resolveMessage(context, gxuNetworkError.value),
        buttonName: FlutterI18n.translate(
          context,
          "setting.change_schoolnet_password_title",
        ),
        function: () => _showPasswordDialog(context),
      );
    }
    if (gxuNetworkStatus.value == SessionState.error) {
      return ReloadWidget(
        errorStatus: _resolveMessage(context, gxuNetworkError.value),
        function: () => _refresh(context),
      );
    }
    return GxuNetworkNoCacheCard(onRefresh: () => _refresh(context));
  }

  Widget _buildContent(BuildContext context, GxuNetworkUsage usage) {
    return [
          if (gxuNetworkRefreshing.value)
            const LinearProgressIndicator()
                .clipRRect(all: 99)
                .padding(vertical: 2, horizontal: 4)
                .constrained(maxWidth: sheetMaxWidth)
                .center(),
          if (gxuNetworkError.value.isNotEmpty)
            GxuNetworkStatusBanner(
                  errorText: _resolveMessage(context, gxuNetworkError.value),
                  isCredentialError: isGxuSchoolnetCredentialError(
                    gxuNetworkError.value,
                  ),
                )
                .padding(vertical: 4, horizontal: 4)
                .width(double.infinity)
                .constrained(maxWidth: sheetMaxWidth)
                .center(),
          GxuNetworkSummaryCard(usage: usage)
              .padding(vertical: 2, horizontal: 4)
              .constrained(maxWidth: sheetMaxWidth)
              .center(),
          _buildOverviewCard(context, usage)
              .padding(vertical: 2, horizontal: 4)
              .constrained(maxWidth: sheetMaxWidth)
              .center(),
          _buildTrafficCard(context, usage)
              .padding(vertical: 2, horizontal: 4)
              .constrained(maxWidth: sheetMaxWidth)
              .center(),
          GxuNetworkActionButtons(
                refreshing: gxuNetworkRefreshing.value,
                onRefresh: () => _refresh(context),
                onChangePassword: () => _showPasswordDialog(context),
              )
              .padding(horizontal: 4, vertical: 6)
              .width(double.infinity)
              .constrained(maxWidth: sheetMaxWidth)
              .center(),
          const GxuNetworkNoticeCard()
              .padding(horizontal: 4, vertical: 2)
              .width(double.infinity)
              .constrained(maxWidth: sheetMaxWidth)
              .center(),
        ]
        .toColumn(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
        )
        .scrollable(padding: const EdgeInsets.all(12));
  }

  Widget _buildOverviewCard(BuildContext context, GxuNetworkUsage usage) {
    return InfoCard(
      iconData: Icons.info,
      title: FlutterI18n.translate(context, "school_net.gxu.overview"),
      dense: true,
      children: [
        InfoItem(
          icon: Icons.person,
          label: FlutterI18n.translate(context, "school_net.gxu.account"),
          value: usage.account,
          dense: true,
        ),
        InfoItem(
          icon: Icons.event,
          label: FlutterI18n.translate(context, "school_net.gxu.settlement"),
          value: usage.settlementDate,
          valueColor: Colors.blue,
          dense: true,
        ),
        InfoItem(
          icon: Icons.shield_outlined,
          label: FlutterI18n.translate(context, "school_net.gxu.protection"),
          value: usage.protection,
          dense: true,
        ),
        InfoItem(
          icon: Icons.account_balance_wallet,
          label: FlutterI18n.translate(context, "school_net.gxu.balance"),
          value: usage.balance,
          valueColor: Colors.green,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildTrafficCard(BuildContext context, GxuNetworkUsage usage) {
    return InfoCard(
      iconData: Icons.data_usage,
      title: FlutterI18n.translate(context, "school_net.gxu.traffic"),
      dense: true,
      children: [
        InfoItem(
          icon: Icons.trending_up,
          label: FlutterI18n.translate(context, "school_net.gxu.used"),
          value: usage.usedTraffic,
          valueColor: Colors.redAccent,
          dense: true,
        ),
        InfoItem(
          icon: Icons.card_giftcard,
          label: FlutterI18n.translate(context, "school_net.gxu.free"),
          value: usage.freeTraffic,
          valueColor: Colors.blue,
          dense: true,
        ),
        InfoItem(
          icon: Icons.check_circle_outline,
          label: FlutterI18n.translate(context, "school_net.gxu.available"),
          value: usage.availableTraffic,
          valueColor: Colors.green,
          dense: true,
        ),
      ],
    );
  }

  Future<void> _refresh(BuildContext context) {
    return updateGxuNetworkUsage(
      captchaFunction: (image) => showDialog<String>(
        context: context,
        builder: (context) => CaptchaInputDialog(image: image),
      ).then((value) => value ?? ""),
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const SchoolNetPasswordDialog(),
    );
    if (!context.mounted) {
      return;
    }
    if (hasGxuSchoolnetCredentials()) {
      await _refresh(context);
    }
  }

  String _resolveMessage(BuildContext context, String value) {
    if (value.startsWith("school_net.") || value.startsWith("homepage.")) {
      return FlutterI18n.translate(context, value);
    }
    return value;
  }
}
