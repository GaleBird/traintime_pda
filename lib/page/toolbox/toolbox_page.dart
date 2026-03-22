// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:watermeter/model/toolbox_addresses.dart';
import 'package:watermeter/page/schoolnet/network_card_window.dart';
import 'package:watermeter/page/toolbox/unfinished_feature_page.dart';
import 'package:watermeter/page/toolbox/webview_list_tile.dart';

class ToolBoxPage extends StatelessWidget {
  const ToolBoxPage({super.key});

  List<WebViewAddresses> _buildGxuAddresses(BuildContext context) {
    return [
      WebViewAddresses(
        name: FlutterI18n.translate(context, "toolbox.network"),
        description: FlutterI18n.translate(
          context,
          "toolbox.network_fee_description",
        ),
        iconData: MingCuteIcons.mgc_wifi_line,
        pageBuilder: (context) => const NetworkCardWindow(),
      ),
      ..._buildUnfinishedAddresses(context),
    ];
  }

  List<WebViewAddresses> _buildUnfinishedAddresses(BuildContext context) {
    return [
      _buildUnfinishedAddress(
        context,
        nameKey: "toolbox.payment",
        descriptionKey: "toolbox.payment_description",
        iconData: MingCuteIcons.mgc_exchange_cny_line,
      ),
      _buildUnfinishedAddress(
        context,
        nameKey: "toolbox.drinkingwater",
        descriptionKey: "toolbox.drinkingwater_description",
        iconData: MingCuteIcons.mgc_drop_line,
        messageKey: "toolbox.unfinished_message_drinkingwater",
      ),
      _buildUnfinishedAddress(
        context,
        nameKey: "toolbox.repair",
        descriptionKey: "toolbox.repair_description",
        iconData: MingCuteIcons.mgc_tool_line,
        messageKey: "toolbox.unfinished_message_repair",
      ),
      _buildUnfinishedAddress(
        context,
        nameKey: "toolbox.reserve",
        descriptionKey: "toolbox.reserve_description",
        iconData: MingCuteIcons.mgc_building_4_line,
        messageKey: "toolbox.unfinished_message_reserve",
      ),
    ];
  }

  WebViewAddresses _buildUnfinishedAddress(
    BuildContext context, {
    required String nameKey,
    required String descriptionKey,
    required IconData iconData,
    String? messageKey,
  }) {
    final name = FlutterI18n.translate(context, nameKey);
    final message = messageKey == null
        ? null
        : FlutterI18n.translate(context, messageKey);
    return WebViewAddresses(
      name:
          "$name${FlutterI18n.translate(context, "toolbox.unfinished_suffix")}",
      description: FlutterI18n.translate(context, descriptionKey),
      iconData: iconData,
      pageBuilder: (context) =>
          UnfinishedFeaturePage(title: name, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildGxuAddresses(context);
    return Scaffold(
      appBar: AppBar(title: I18nText("toolbox.title")),
      body: ListView(
        children: items.map((item) => WebViewListTile(data: item)).toList(),
      ),
    );
  }
}
