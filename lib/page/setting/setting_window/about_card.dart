// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/setting/about_page/about_page.dart';
import 'package:watermeter/page/setting/dialogs/update_dialog.dart';
import 'package:watermeter/page/setting/setting_window/section_title.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/pda_service_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class SettingAboutCard extends StatelessWidget {
  const SettingAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.about"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.about_this_program"),
            ),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.version",
                translationParams: {
                  "version":
                      "${preference.packageInfo.version}+${preference.packageInfo.buildNumber}",
                },
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => context.pushReplacement(const AboutPage()),
          ),
          const Divider(),
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.check_update")),
            subtitle: Obx(
              () => Text(
                FlutterI18n.translate(
                  context,
                  "setting.latest_version",
                  translationParams: {
                    "latest":
                        updateMessage.value?.code ??
                        FlutterI18n.translate(context, "setting.waiting"),
                  },
                ),
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _onCheckUpdate(context),
          ),
        ],
      ),
    );
  }

  void _onCheckUpdate(BuildContext context) {
    showToast(
      context: context,
      msg: FlutterI18n.translate(context, "setting.fetching_update"),
    );

    checkUpdate().then(
      (value) async {
        if (!context.mounted) return;
        if (value == UpdateCheckResult.available &&
            updateMessage.value != null) {
          await _showUpdateDialog(context);
          return;
        }
        _showUpdateResult(context, value);
      },
      onError: (e, s) {
        log.warning("[setting][checkUpdate] failed", e, s);
        if (!context.mounted) return;
        showToast(
          context: context,
          msg: FlutterI18n.translate(context, "setting.fetch_failed"),
        );
      },
    );
  }

  Future<void> _showUpdateDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) =>
          Obx(() => UpdateDialog(updateMessage: updateMessage.value!)),
    );
  }

  void _showUpdateResult(BuildContext context, UpdateCheckResult result) {
    final key = switch (result) {
      UpdateCheckResult.latest => "setting.current_stable",
      UpdateCheckResult.localAhead => "setting.current_testing",
      UpdateCheckResult.noRelease => "setting.no_published_release",
      UpdateCheckResult.failed => "setting.fetch_failed",
      UpdateCheckResult.available => "setting.current_stable",
    };
    showToast(context: context, msg: FlutterI18n.translate(context, key));
  }
}
