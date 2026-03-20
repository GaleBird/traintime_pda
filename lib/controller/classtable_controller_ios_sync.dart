// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:watermeter/bridge/save_to_groupid.g.dart';
import 'package:watermeter/model/xidian_ids/classtable.dart';
import 'package:watermeter/repository/logger.dart';

Future<void> syncClasstableToIosWidgets({
  required ClassTableData classTableData,
  required String appId,
  required int weekSwift,
}) async {
  final api = SaveToGroupIdSwiftApi();
  await _saveFile(
    api,
    fileName: 'ClassTable.json',
    appId: appId,
    data: jsonEncode(classTableData.toJson()),
  );
  await _saveFile(
    api,
    fileName: 'WeekSwift.txt',
    appId: appId,
    data: weekSwift.toString(),
  );
  HomeWidget.updateWidget(
    iOSName: 'ClasstableWidget',
    qualifiedAndroidName:
        'io.github.benderblog.traintime_pda.widget.classtable.ClassTableWidgetProvider',
  );
}

Future<void> _saveFile(
  SaveToGroupIdSwiftApi api, {
  required String fileName,
  required String appId,
  required String data,
}) async {
  try {
    final ok = await api.saveToGroupId(
      FileToGroupID(appid: appId, fileName: fileName, data: data),
    );
    log.info('[ClassTableController][syncIosWidgets] $fileName saved: $ok.');
  } catch (e, s) {
    log.handle(e, s);
  }
}
