// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/setting/dialogs/schoolnet_password_dialog.dart';
import 'package:watermeter/page/setting/setting_window/section_title.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingAccountCard extends StatelessWidget {
  const SettingAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.account_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(
              FlutterI18n.translate(
                context,
                "setting.schoolnet_password_setting",
              ),
            ),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.schoolnet_password_description",
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) => const SchoolNetPasswordDialog(),
            ),
          ),
        ],
      ),
    ).padding(bottom: 16);
  }
}
