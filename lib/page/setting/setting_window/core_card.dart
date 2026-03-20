// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:watermeter/controller/theme_controller.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/setting/notification_page/notification_debug_page.dart';
import 'package:watermeter/page/setting/setting_window/cache_ops.dart';
import 'package:watermeter/page/setting/setting_window/section_title.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:styled_widget/styled_widget.dart';

class SettingCoreCard extends StatelessWidget {
  final VoidCallback restartApp;

  const SettingCoreCard({super.key, required this.restartApp});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.core_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.check_logger")),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => context.push(TalkerScreen(talker: log)),
          ),
          const Divider(),
          if (Theme.of(context).platform == TargetPlatform.android ||
              Theme.of(context).platform == TargetPlatform.iOS)
            ListTile(
              title: Text(
                FlutterI18n.translate(
                  context,
                  "setting.notification_debug_page",
                ),
              ),
              trailing: const Icon(Icons.navigate_next),
              onTap: () => context.push(NotificationDebugPage()),
            ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.clear_and_restart"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _showClearCacheDialog(context),
          ),
          const Divider(),
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.logout")),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    ).padding(bottom: 16);
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(
            context,
            "setting.clear_and_restart_dialog.title",
          ),
        ),
        content: Text(
          FlutterI18n.translate(
            context,
            "setting.clear_and_restart_dialog.content",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(FlutterI18n.translate(context, "cancel")),
          ),
          TextButton(
            onPressed: () async {
              final pd = ProgressDialog(context: context);
              pd.show(
                msg: FlutterI18n.translate(
                  context,
                  "setting.clear_and_restart_dialog.cleaning",
                ),
              );
              await clearAllCookies();
              removeCacheFiles();
              if (!context.mounted) return;
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.clear_and_restart_dialog.clear",
                ),
              );
              restartApp();
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "setting.logout_dialog.title"),
        ),
        content: Text(
          FlutterI18n.translate(context, "setting.logout_dialog.content"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(FlutterI18n.translate(context, "cancel")),
          ),
          TextButton(
            onPressed: () async {
              final pd = ProgressDialog(context: context);
              pd.show(
                msg: FlutterI18n.translate(
                  context,
                  "setting.logout_dialog.logging_out",
                ),
              );
              await clearAllCookies();
              removeAllFiles();
              await preference.prefrenceClear();
              Get.put(ThemeController()).updateTheme();
              if (!context.mounted) return;
              if (pd.isOpen()) pd.close();
              restartApp();
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }
}
