// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0
// Copied from https://github.com/SimformSolutionsPvtLtd/flutter_calendar_view/blob/master/lib/src/event_arrangers/event_arrangers.dart; removed left/right, only use stack.
import 'package:flutter/material.dart';
import 'package:watermeter/model/time_list.dart';
import 'package:watermeter/model/xidian_ids/exam.dart';
import 'package:watermeter/model/xidian_ids/classtable.dart';
import 'package:watermeter/model/xidian_ids/experiment.dart';

class ClassOrgainzedData {
  final List<dynamic> data;
  final String? teacher;

  static const double _classBlockSpan = 5;
  static const double _breakBlockSpan = 3;
  static const double _totalBlockSpan = 61;
  static const double _supperBreakStartBlock = 43;
  static const double _supperBreakMidBlock =
      _supperBreakStartBlock + _breakBlockSpan / 2;
  static const double _supperBreakEndBlock =
      _supperBreakStartBlock + _breakBlockSpan;

  /// Block index uses `double` because segments are uneven (exam/experiment).
  /// Layout: morning (1-4) + noon break + afternoon (5-8) + supper break + evening (9-11) (61 parts).
  late final double start;
  late final double stop;

  final String name;
  final String? place;

  final MaterialColor color;

  /// Following is the begin/end for each blocks...
  static const _timeInBlock = [
    "08:30",
    "09:20",
    "10:25",
    "11:15",
    "12:00",
    "14:00",
    "14:50",
    "15:55",
    "16:45",
    "17:30",
    "19:00",
    "19:55",
    "20:35",
    "21:25",
  ];

  factory ClassOrgainzedData.fromTimeArrangement(
    TimeArrangement timeArrangement,
    MaterialColor color,
    String name,
  ) {
    if (useContinuousClassLayout) {
      return ClassOrgainzedData(
        data: [timeArrangement],
        start: (timeArrangement.start - 1).toDouble(),
        stop: timeArrangement.stop.toDouble(),
        color: color,
        name: name,
        place: timeArrangement.classroom,
      );
    }

    return ClassOrgainzedData(
      data: [timeArrangement],
      start: _transferIndexForTimeArrangement(
        timeArrangement.start - 1,
        isStart: true,
      ),
      stop: _transferIndexForTimeArrangement(
        timeArrangement.stop,
        isStart: false,
      ),
      color: color,
      name: name,
      place: timeArrangement.classroom,
      teacher: timeArrangement.teacher,
    );
  }

  static double _transferIndexForTimeArrangement(
    int index, {
    required bool isStart,
  }) {
    return isGxuMode
        ? _transferIndexForTimeArrangementGxu(index, isStart: isStart)
        : _transferIndexForTimeArrangementXidian(index, isStart: isStart);
  }

  static double _transferIndexForTimeArrangementXidian(
    int index, {
    required bool isStart,
  }) {
    if (index <= 4) {
      final base = index * _classBlockSpan;
      return isStart && index == 4 ? base + _breakBlockSpan : base;
    }
    if (index <= 8) {
      final base = index * _classBlockSpan + _breakBlockSpan;
      return isStart && index == 8 ? base + _breakBlockSpan : base;
    }
    return index * _classBlockSpan + _breakBlockSpan * 2;
  }

  static double _transferIndexForTimeArrangementGxu(
    int index, {
    required bool isStart,
  }) {
    if (isStart) {
      if (index == 8) return _supperBreakStartBlock;
      if (index == 9) return _supperBreakMidBlock;
      if (index >= 10) {
        return _transferIndexForTimeArrangementXidian(
          index - 2,
          isStart: isStart,
        );
      }
      return _transferIndexForTimeArrangementXidian(index, isStart: isStart);
    }

    if (index == 9) return _supperBreakMidBlock;
    if (index == 10) return _supperBreakEndBlock;
    if (index >= 11) {
      return _transferIndexForTimeArrangementXidian(
        index - 2,
        isStart: isStart,
      );
    }
    return _transferIndexForTimeArrangementXidian(index, isStart: isStart);
  }

  /// Ensure the [Subject.startTime] and [Subject.stopTime] is not NULL!
  factory ClassOrgainzedData.fromSubject(
    MaterialColor color,
    Subject subject,
  ) => ClassOrgainzedData._(
    data: [(subject)],
    start: subject.startTime!,
    stop: subject.stopTime!,
    color: color,
    name: "${subject.subject}${subject.type}",
    place:
        "${subject.place} "
        "${subject.seat == null ? "" : "${subject.seat}"}",
    teacher: null,
  );

  factory ClassOrgainzedData.fromExperiment(
    MaterialColor color,
    ExperimentData exp,
    DateTime start,
    DateTime stop,
  ) => ClassOrgainzedData._(
    data: [exp],
    start: start,
    stop: stop,
    color: color,
    name: exp.name,
    place: exp.classroom,
    teacher: exp.teacher,
  );

  ClassOrgainzedData({
    required this.data,
    required this.start,
    required this.stop,
    required this.name,
    required this.color,
    this.place,
    this.teacher,
  });

  static double _transferIndex(DateTime time) {
    if (useContinuousClassLayout) {
      return _transferContinuous(time);
    }
    return isGxuMode
        ? _transferSegmentedGxu(time)
        : _transferSegmentedXidian(time);
  }

  static double _transferSegmentedGxu(DateTime time) {
    final target = time.hour * 60 + time.minute;
    final segments = <(int start, int end, double base, double span)>[
      (_periodStartMinutes(1), _periodStartMinutes(2), 0, _classBlockSpan),
      (_periodStartMinutes(2), _periodStartMinutes(3), 5, _classBlockSpan),
      (_periodStartMinutes(3), _periodStartMinutes(4), 10, _classBlockSpan),
      (_periodStartMinutes(4), _periodEndMinutes(4), 15, _classBlockSpan),
      (_periodEndMinutes(4), _periodStartMinutes(5), 20, _breakBlockSpan),
      (_periodStartMinutes(5), _periodStartMinutes(6), 23, _classBlockSpan),
      (_periodStartMinutes(6), _periodStartMinutes(7), 28, _classBlockSpan),
      (_periodStartMinutes(7), _periodStartMinutes(8), 33, _classBlockSpan),
      (_periodStartMinutes(8), _periodEndMinutes(8), 38, _classBlockSpan),
      (_periodEndMinutes(8), _periodStartMinutes(11), 43, _breakBlockSpan),
      (_periodStartMinutes(11), _periodStartMinutes(12), 46, _classBlockSpan),
      (_periodStartMinutes(12), _periodStartMinutes(13), 51, _classBlockSpan),
      (_periodStartMinutes(13), _periodEndMinutes(13), 56, _classBlockSpan),
    ];

    if (target < segments.first.$1) return 0;
    if (target >= segments.last.$2) return _totalBlockSpan;

    for (final segment in segments) {
      if (target < segment.$1 || target >= segment.$2) continue;
      final spanMinutes = (segment.$2 - segment.$1).clamp(1, 9999);
      final ratio = (target - segment.$1) / spanMinutes;
      return segment.$3 + segment.$4 * ratio;
    }

    return _totalBlockSpan;
  }

  static double _transferSegmentedXidian(DateTime time) {
    final timeInMin = time.hour * 60 + time.minute;
    var previous = 0;

    for (final boundary in _timeInBlock) {
      final timeChosen = _toMinutes(boundary);
      if (previous == 0) {
        if (timeInMin < timeChosen) return 0;
        previous = timeChosen;
        continue;
      }
      if (timeInMin >= previous && timeInMin < timeChosen) {
        var basic = 0.0;
        var blocks = _classBlockSpan;
        final ratio = (timeInMin - previous) / (timeChosen - previous);
        if (previous < 12 * 60) {
          basic = (_timeInBlock.indexOf(boundary) - 1) * _classBlockSpan;
        } else if (previous < 14 * 60) {
          basic = 20;
          blocks = _breakBlockSpan;
        } else if (previous < 17.5 * 60) {
          basic = 23 + (_timeInBlock.indexOf(boundary) - 6) * _classBlockSpan;
        } else if (previous < 19 * 60) {
          basic = _supperBreakStartBlock;
          blocks = _breakBlockSpan;
        } else {
          basic =
              _supperBreakEndBlock +
              (_timeInBlock.indexOf(boundary) - 11) * _classBlockSpan;
        }
        return basic + blocks * ratio;
      }
      previous = timeChosen;
    }

    return _totalBlockSpan;
  }

  static int _periodStartMinutes(int period) =>
      _toMinutes(timeList[(period - 1) * 2]);

  static int _periodEndMinutes(int period) =>
      _toMinutes(timeList[(period - 1) * 2 + 1]);

  static double _transferContinuous(DateTime time) {
    final target = time.hour * 60 + time.minute;
    final periods = List.generate(timeList.length ~/ 2, (index) {
      final start = _toMinutes(timeList[index * 2]);
      final stop = _toMinutes(timeList[index * 2 + 1]);
      return (start, stop);
    });

    for (var index = 0; index < periods.length; index++) {
      final current = periods[index];
      if (target <= current.$1) {
        return index.toDouble();
      }
      if (target <= current.$2) {
        final span = (current.$2 - current.$1).clamp(1, 9999);
        return index + (target - current.$1) / span;
      }
    }

    return periods.length.toDouble();
  }

  static int _toMinutes(String text) {
    final split = text.split(":");
    return int.parse(split[0]) * 60 + int.parse(split[1]);
  }

  ClassOrgainzedData._({
    required this.data,
    required DateTime start,
    required DateTime stop,
    required this.color,
    required this.name,
    this.place,
    this.teacher,
  }) {
    this.start = _transferIndex(start);
    this.stop = _transferIndex(stop);
  }
}
