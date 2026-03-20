// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:watermeter/model/pda_service/message.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateMessage updateMessage;
  const UpdateDialog({super.key, required this.updateMessage});

  @override
  Widget build(BuildContext context) {
    final buffer = StringBuffer(
      FlutterI18n.translate(
        context,
        "setting.update_dialog.new_content",
        translationParams: {"code": updateMessage.code},
      ),
    );
    for (int i = 0; i < updateMessage.update.length; ++i) {
      buffer.writeln("${i + 1}.${updateMessage.update[i]}");
    }
    return AlertDialog(
      title: Text(
        FlutterI18n.translate(context, "setting.update_dialog.new_version"),
      ),
      content: Text(buffer.toString().trimRight()),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          FlutterI18n.translate(context, "setting.update_dialog.not_now"),
        ),
      ),
    ];
    if (Platform.isIOS && updateMessage.ioslink != updateMessage.github) {
      actions.add(
        TextButton(
          onPressed: () => launchUrlString(updateMessage.ioslink),
          child: Text(
            FlutterI18n.translate(context, "setting.update_dialog.app_store"),
          ),
        ),
      );
    }
    if (Platform.isAndroid && updateMessage.fdroid != updateMessage.github) {
      actions.add(
        TextButton(
          onPressed: () => launchUrlString(updateMessage.fdroid),
          child: Text(
            FlutterI18n.translate(
              context,
              "setting.update_dialog.download_apk",
            ),
          ),
        ),
      );
    }
    actions.add(
      TextButton(
        onPressed: () => launchUrlString(updateMessage.github),
        child: Text(
          FlutterI18n.translate(
            context,
            "setting.update_dialog.github_release",
          ),
        ),
      ),
    );
    return actions;
  }
}
