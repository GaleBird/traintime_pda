// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:restart_app/restart_app.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/setting/setting_window/about_card.dart';
import 'package:watermeter/page/setting/setting_window/account_card.dart';
import 'package:watermeter/page/setting/setting_window/classtable_card.dart';
import 'package:watermeter/page/setting/setting_window/core_card.dart';
import 'package:watermeter/page/setting/setting_window/notification_card.dart';
import 'package:watermeter/page/setting/setting_window/ui_card.dart';
import 'package:watermeter/repository/app_brand.dart';
import 'package:watermeter/repository/fork_info.dart';

class SettingWindow extends StatelessWidget {
  const SettingWindow({super.key});

  void _restart(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      Restart.restartApp();
      return;
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "setting.need_close_dialog.title"),
        ),
        content: Text(
          FlutterI18n.translate(context, "setting.need_close_dialog.content"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingHeader(),
          const SizedBox(height: 20),
          const SettingAboutCard().padding(bottom: 16),
          const SettingUiCard(),
          const SettingAccountCard(),
          if (Platform.isAndroid || Platform.isIOS)
            const SettingNotificationCard(),
          const SettingClasstableCard(),
          SettingCoreCard(restartApp: () => _restart(context)),
        ],
      ).constrained(maxWidth: 600).center().safeArea(top: true),
    );
  }
}

class _SettingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: AppBrand.appName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text:
                '\n${FlutterI18n.translate(context, "setting.header_subtitle", translationParams: {"maintainer": ForkInfo.maintainer})}',
          ),
        ],
      ),
    ).padding(horizontal: 8.0);
  }
}
