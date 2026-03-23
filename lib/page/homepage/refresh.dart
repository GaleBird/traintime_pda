// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Refresh formula for homepage.

import 'package:get/get.dart';
import 'package:watermeter/controller/classtable_controller.dart';
import 'package:watermeter/model/home_arrangement.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/notification/course_reminder_service.dart';

const _gxuTomorrowCutoffMinutes = 22 * 60 + 5;

DateTime updateTime = DateTime.now();

RxInt remaining = 0.obs;
RxBool isTomorrow = false.obs;
Rxn<HomeArrangement> next = Rxn<HomeArrangement>();
Rxn<HomeArrangement> current = Rxn<HomeArrangement>();
RxList<HomeArrangement> arrangement = <HomeArrangement>[].obs;
Rx<ArrangementState> arrangementState = ArrangementState.none.obs;

enum ArrangementState { fetching, fetched, error, none }

Future<void> update({bool isForceClassTableRefresh = false}) async {
  await _updateHomepage(isForceClassTableRefresh: isForceClassTableRefresh);
}

Future<void> _updateHomepage({required bool isForceClassTableRefresh}) async {
  final controller = Get.put(ClassTableController());
  await controller.updateClassTable(isForce: isForceClassTableRefresh);
  updateCurrentData();
  await _ensureNotifications();
}

Future<void> _ensureNotifications() async {
  if (CourseReminderService().isInitialized) {
    CourseReminderService().validateAndUpdateNotifications();
    return;
  }

  await CourseReminderService().initialize();
  CourseReminderService().validateAndUpdateNotifications();
}

void updateCurrentData() {
  _updateGxuCurrentData();
}

void _updateGxuCurrentData() {
  log.info(
    "[updateCurrentData]"
    "Updating current data. ${arrangementState.value}",
  );
  final classTableController = Get.put(ClassTableController());
  if (arrangementState.value == ArrangementState.fetching) {
    return;
  }
  if (classTableController.state == ClassTableState.fetching) {
    return;
  }

  arrangementState.value = ArrangementState.fetching;
  if (classTableController.state == ClassTableState.error) {
    arrangementState.value = ArrangementState.error;
    return;
  }

  updateTime = DateTime.now();
  final targetDay = _isGxuTomorrow(updateTime)
      ? updateTime.add(const Duration(days: 1))
      : updateTime;
  isTomorrow.value = targetDay.day != updateTime.day;

  final toAdd = <HomeArrangement>[];
  if (classTableController.state == ClassTableState.fetched) {
    toAdd.addAll(classTableController.getArrangementOfDay(targetDay));
  }
  if (!isTomorrow.value) {
    toAdd.removeWhere((element) => !updateTime.isBefore(element.endTime));
  }

  toAdd.sort((a, b) => a.startTime.difference(b.startTime).inMicroseconds);
  arrangement
    ..clear()
    ..addAll(toAdd);
  _updateGxuCurrentAndNext();
  arrangementState.value = ArrangementState.fetched;
}

void _updateGxuCurrentAndNext() {
  if (isTomorrow.isTrue) {
    current.value = null;
    next.value = arrangement.isEmpty ? null : arrangement.first;
    remaining.value = arrangement.length > 1 ? arrangement.length - 1 : 0;
    return;
  }

  final iterator = arrangement.iterator;
  while (iterator.moveNext()) {
    if (_shouldShowGxuArrangement(iterator.current)) {
      break;
    }
  }

  try {
    current.value = iterator.current;
  } on TypeError {
    current.value = null;
  }

  if (current.value == null) {
    next.value = arrangement.isEmpty ? null : arrangement.first;
  } else if (iterator.moveNext()) {
    next.value = iterator.current;
  } else {
    next.value = null;
  }

  var len = arrangement.length;
  if (current.value != null) len -= 1;
  if (next.value != null) len -= 1;
  remaining.value = len;
  log.info(
    "[updateCurrentData]current: ${current.value?.name}, "
    "next: ${next.value?.name}, remaining: ${remaining.value}",
  );
}

bool _shouldShowGxuArrangement(HomeArrangement arrangement) {
  if (updateTime.microsecondsSinceEpoch >=
          arrangement.startTime.microsecondsSinceEpoch &&
      updateTime.microsecondsSinceEpoch <=
          arrangement.endTime.microsecondsSinceEpoch) {
    return true;
  }

  var inAdvance = 30;
  final currentTime = updateTime.hour * 60 + updateTime.minute;
  if (currentTime < 8.5 * 60 ||
      (currentTime < 14 * 60 && currentTime >= 12 * 60) ||
      (currentTime < 19 * 60 && currentTime >= 18 * 60)) {
    inAdvance = 60;
  }
  final diffMinutes = arrangement.startTime.difference(updateTime).inMinutes;
  return diffMinutes >= 0 && diffMinutes < inAdvance;
}

bool _isGxuTomorrow(DateTime time) {
  return time.hour * 60 + time.minute > _gxuTomorrowCutoffMinutes;
}
