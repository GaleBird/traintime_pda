// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/setting/notification_page/notification_page.dart';
import 'package:watermeter/page/setting/setting_window/section_title.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingNotificationCard extends StatelessWidget {
  const SettingNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.notification_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.course_reminder_setting"),
            ),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.course_reminder_description",
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => context.push(const NotificationSettingsPage()),
          ),
        ],
      ),
    ).padding(bottom: 16);
  }
}
