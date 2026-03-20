// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:watermeter/model/time_list.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:get/get.dart';
import 'package:watermeter/model/home_arrangement.dart';
import 'package:watermeter/controller/classtable_controller_ios_sync.dart';
import 'package:watermeter/repository/gxu_ids/gxu_classtable_session.dart';
import 'package:watermeter/repository/classtable_storage.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/model/xidian_ids/classtable.dart';

part 'classtable_controller_update_mixin.dart';
part 'classtable_controller_user_defined_mixin.dart';

enum ClassTableState { fetching, fetched, error, none }

const _gxuCacheMode = "gxu";

class ClassTableController extends GetxController {
  // Classtable state
  String? error;
  ClassTableState state = ClassTableState.none;

  // Classtable Data
  late File classTableFile;
  late File userDefinedFile;
  late ClassTableData classTableData;
  late UserDefinedClassData userDefinedClassData;

  // Get ClassDetail name info
  ClassDetail getClassDetail(TimeArrangement timeArrangementIndex) =>
      classTableData.getClassDetail(timeArrangementIndex);

  bool isTomorrow(DateTime updateTime) =>
      updateTime.hour * 60 + updateTime.minute > 21 * 60 + 25;

  String get _currentCacheMode => _gxuCacheMode;

  int getCurrentWeek(DateTime now) {
    // Get the current index.
    int delta = now.difference(startDay).inDays;
    if (delta < 0) delta = -7;
    return delta ~/ 7;
  }

  /// Get all of [updateTime]'s arrangement in classtable
  List<HomeArrangement> getArrangementOfDay(DateTime updateTime) {
    DateFormat formatter = DateFormat(HomeArrangement.format);
    int currentWeek = getCurrentWeek(updateTime);
    Set<HomeArrangement> getArrangement = {};
    if (currentWeek >= 0 && currentWeek < classTableData.semesterLength) {
      for (var i in classTableData.timeArrangement) {
        if (i.weekList.length > currentWeek &&
            i.weekList[currentWeek] &&
            i.day == updateTime.weekday) {
          getArrangement.add(
            HomeArrangement(
              name: getClassDetail(i).name,
              teacher: i.teacher,
              place: i.classroom,
              startTimeStr: formatter.format(
                DateTime(
                  updateTime.year,
                  updateTime.month,
                  updateTime.day,
                  int.parse(timeList[(i.start - 1) * 2].split(':')[0]),
                  int.parse(timeList[(i.start - 1) * 2].split(':')[1]),
                ),
              ),
              endTimeStr: formatter.format(
                DateTime(
                  updateTime.year,
                  updateTime.month,
                  updateTime.day,
                  int.parse(timeList[(i.stop - 1) * 2 + 1].split(':')[0]),
                  int.parse(timeList[(i.stop - 1) * 2 + 1].split(':')[1]),
                ),
              ),
            ),
          );
        }
      }
    }

    return getArrangement.toList();
  }

  @override
  void onInit() {
    super.onInit();
    log.info(
      "[ClassTableController][onInit] "
      "Init classtable file.",
    );
    classTableFile = File(
      "${supportPath.path}/${ClasstableStorage.schoolClassName}",
    );
    final classTableFileIsExist = classTableFile.existsSync();
    if (classTableFileIsExist && _isCacheModeMatched()) {
      log.info(
        "[ClassTableController][onInit] "
        "Init from cache.",
      );
      refreshUserDefinedClass();
      _loadCachedClassTable();
      state = ClassTableState.fetched;
    } else {
      log.info(
        "[ClassTableController][onInit] "
        "Init from empty.",
      );
      classTableData = ClassTableData();
    }
    if (state != ClassTableState.fetched) {
      log.info(
        "[ClassTableController][onInit] "
        "Init user defined file.",
      );
      refreshUserDefinedClass();
    }
  }

  @override
  void onReady() async {
    await updateClassTable();
  }

  /// The start day of the semester.
  DateTime get startDay => DateTime.parse(
    classTableData.termStartDay,
  ).add(Duration(days: 7 * preference.getInt(preference.Preference.swift)));

  Map<String, int> get numberOfClass {
    Map<String, int> toReturn = {};
    for (var i in classTableData.timeArrangement) {
      String nameOfClass = classTableData.getClassDetail(i).name;
      int numberOfClass = i.weekList.where((ok) => ok).length;
      if (toReturn[nameOfClass] == null) {
        toReturn[nameOfClass] = numberOfClass;
      } else {
        toReturn[nameOfClass] = toReturn[nameOfClass]! + numberOfClass;
      }
    }
    return toReturn;
  }
}
