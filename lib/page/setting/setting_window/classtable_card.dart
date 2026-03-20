// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:watermeter/controller/classtable_controller.dart';
import 'package:watermeter/page/homepage/refresh.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/setting/dialogs/change_swift_dialog.dart';
import 'package:watermeter/page/setting/dialogs/semester_switch_dialog.dart';
import 'package:watermeter/page/setting/setting_window/section_title.dart';
import 'package:watermeter/repository/classtable_storage.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/pick_file.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:styled_widget/styled_widget.dart';

class SettingClasstableCard extends StatefulWidget {
  const SettingClasstableCard({super.key});

  @override
  State<SettingClasstableCard> createState() => _SettingClasstableCardState();
}

class _SettingClasstableCardState extends State<SettingClasstableCard> {
  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.classtable_setting"),
      ),
      remaining: const [],
      bottomRow: Column(
        children: [
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.background")),
            trailing: Switch(
              value: preference.getBool(preference.Preference.decorated),
              onChanged: _toggleBackground,
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.choose_background"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _pickBackground(context),
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.class_refresh"),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => _showForceRefreshDialog(context),
          ),
          const Divider(),
          ListTile(
            title: Text(FlutterI18n.translate(context, "setting.class_swift")),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.class_swift_description",
                translationParams: {
                  "swift": preference
                      .getInt(preference.Preference.swift)
                      .toString(),
                },
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () =>
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => ChangeSwiftDialog(),
                ).then((_) {
                  Get.put(ClassTableController()).update();
                  updateCurrentData();
                  if (mounted) setState(() {});
                }),
          ),
          const Divider(),
          ListTile(
            title: Text(
              FlutterI18n.translate(context, "setting.semester_change"),
            ),
            subtitle: Text(
              FlutterI18n.translate(
                context,
                "setting.semester_change_description",
                translationParams: {
                  "semester": preference.getString(
                    preference.Preference.currentSemester,
                  ),
                },
              ),
            ),
            trailing: const Icon(Icons.navigate_next),
            onTap: () =>
                showDialog<bool>(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => SemesterSwitchDialog(),
                ).then((value) {
                  if (value != true) return;
                  Get.put(
                    ClassTableController(),
                  ).updateClassTable(isForce: true);
                  if (mounted) setState(() {});
                }),
          ),
        ],
      ),
    ).padding(bottom: 16);
  }

  void _toggleBackground(bool value) {
    if (value && !preference.getBool(preference.Preference.decoration)) {
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "setting.no_background"),
      );
      return;
    }
    preference.setBool(preference.Preference.decorated, value);
    setState(() {});
  }

  Future<void> _pickBackground(BuildContext context) async {
    FilePickerResult? result;
    try {
      result = await pickFile(type: FileType.image);
    } on MissingStoragePermissionException {
      if (!context.mounted) return;
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "setting.no_permission"),
      );
    }
    if (!context.mounted) return;

    if (result == null) {
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "setting.failure_setting"),
      );
      return;
    }

    File(
      result.files.single.path!,
    ).copySync("${supportPath.path}/${ClasstableStorage.decorationName}");
    await preference.setBool(preference.Preference.decoration, true);
    if (!context.mounted) return;
    showToast(
      context: context,
      msg: FlutterI18n.translate(context, "setting.successful_setting"),
    );
    setState(() {});
  }

  void _showForceRefreshDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          FlutterI18n.translate(context, "setting.class_refresh_title"),
        ),
        content: Text(
          FlutterI18n.translate(context, "setting.class_refresh_content"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(FlutterI18n.translate(context, "cancel")),
          ),
          TextButton(
            onPressed: () {
              Get.put(ClassTableController()).updateClassTable(isForce: true);
              Navigator.pop(context);
            },
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }
}
