// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:watermeter/controller/theme_controller.dart';
import 'package:watermeter/page/homepage/info_widget/classtable_card.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/setting/dialogs/change_color_dialog.dart';
import 'package:watermeter/page/setting/dialogs/change_localization_dialog.dart';
import 'package:watermeter/page/setting/setting_window/section_title.dart';
import 'package:watermeter/repository/localization.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/themes/color_seed.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingUiCard extends StatelessWidget {
  const SettingUiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: buildSettingSectionTitle(
        FlutterI18n.translate(context, "setting.ui_setting"),
      ),
      remaining: const [],
      bottomRow: const Column(
        children: [
          _ColorSettingTile(),
          Divider(),
          _BrightnessSettingTile(),
          Divider(),
          _SimplifyTimelineSettingTile(),
          Divider(),
          _LocalizationSettingTile(),
        ],
      ),
    ).padding(bottom: 16);
  }
}

class _ColorSettingTile extends StatelessWidget {
  const _ColorSettingTile();

  @override
  Widget build(BuildContext context) {
    final currentSeedIndex = preference.getInt(preference.Preference.color);
    final currentSeedLabel = ColorSeed.values[currentSeedIndex].label;

    return ListTile(
      title: Text(FlutterI18n.translate(context, "setting.color_setting")),
      subtitle: Text(
        FlutterI18n.translate(
          context,
          "setting.change_color_dialog.$currentSeedLabel",
        ),
      ),
      trailing: const Icon(Icons.navigate_next),
      onTap: () => showDialog(
        context: context,
        builder: (context) => const ChangeColorDialog(),
      ),
    );
  }
}

class _BrightnessSettingTile extends StatelessWidget {
  const _BrightnessSettingTile();

  @override
  Widget build(BuildContext context) {
    final demoBlueModeName = [
      FlutterI18n.translate(
        context,
        "setting.change_brightness_dialog.follow_setting",
      ),
      FlutterI18n.translate(
        context,
        "setting.change_brightness_dialog.day_mode",
      ),
      FlutterI18n.translate(
        context,
        "setting.change_brightness_dialog.night_mode",
      ),
    ];
    final currentModeIndex = preference.getInt(
      preference.Preference.brightness,
    );

    return ListTile(
      title: Text(FlutterI18n.translate(context, "setting.brightness_setting")),
      subtitle: Text(demoBlueModeName[currentModeIndex]),
      trailing: ToggleButtons(
        isSelected: List<bool>.generate(
          3,
          (index) => index == currentModeIndex,
        ),
        onPressed: (int value) {
          preference.setInt(preference.Preference.brightness, value).then((_) {
            Get.put(ThemeController()).updateTheme();
          });
        },
        children: const [
          Icon(Icons.phone_android_rounded),
          Icon(Icons.light_mode_rounded),
          Icon(Icons.dark_mode_rounded),
        ],
      ),
    );
  }
}

class _SimplifyTimelineSettingTile extends StatefulWidget {
  const _SimplifyTimelineSettingTile();

  @override
  State<_SimplifyTimelineSettingTile> createState() =>
      _SimplifyTimelineSettingTileState();
}

class _SimplifyTimelineSettingTileState
    extends State<_SimplifyTimelineSettingTile> {
  bool simplifiedTimeline = preference.getBool(
    preference.Preference.simplifiedClassTimeline,
  );

  Future<void> _toggleSimplifiedTimeline(bool value) async {
    setState(() => simplifiedTimeline = value);
    await preference.setBool(
      preference.Preference.simplifiedClassTimeline,
      value,
    );
    ClassTableCard.reloadSettingsFromPref();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(FlutterI18n.translate(context, "setting.simplify_timeline")),
      subtitle: Text(
        FlutterI18n.translate(context, "setting.simplify_timeline_description"),
      ),
      trailing: Switch(
        value: simplifiedTimeline,
        onChanged: (value) => unawaited(_toggleSimplifiedTimeline(value)),
      ),
    );
  }
}

class _LocalizationSettingTile extends StatelessWidget {
  const _LocalizationSettingTile();

  @override
  Widget build(BuildContext context) {
    final currentLocalization = Localization.values.firstWhere(
      (value) =>
          value.string ==
          preference.getString(preference.Preference.localization),
    );

    return ListTile(
      title: Text(
        FlutterI18n.translate(context, "setting.localization_dialog.title"),
      ),
      subtitle: Text(
        FlutterI18n.translate(context, currentLocalization.toShow),
      ),
      trailing: const Icon(Icons.navigate_next),
      onTap: () => showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => const ChangeLanguageDialog(),
      ),
    );
  }
}
