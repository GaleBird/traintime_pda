import 'package:watermeter/model/xidian_ids/classtable.dart';

class GxuClasstableParser {
  ClassTableData parse({
    required String semesterCode,
    required String termStartDay,
    required List<Map<String, dynamic>> rawCourses,
  }) {
    final courses = rawCourses
        .map(GxuCourseRecord.fromJson)
        .where((item) => item.semesterCode == semesterCode)
        .toList();
    final parsedSegments = courses.expand(_parseCourseSegments).toList();
    final semesterLength = _resolveSemesterLength(parsedSegments);
    return _buildClassTable(
      semesterCode: semesterCode,
      termStartDay: termStartDay,
      semesterLength: semesterLength,
      courses: courses,
      parsedSegments: parsedSegments,
    );
  }

  Iterable<_GxuCourseSegment> _parseCourseSegments(GxuCourseRecord course) {
    if (course.scheduleText.isEmpty) {
      return const [];
    }
    return course.scheduleText
        .split(RegExp(r"[;；]+"))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => _parseSegment(course, item))
        .whereType<_GxuCourseSegment>();
  }

  _GxuCourseSegment? _parseSegment(GxuCourseRecord course, String text) {
    final match = RegExp(
      r"^第(?<weeks>[^周]+)周\s+星期(?<day>[一二三四五六日天])\s+第(?<start>\d+)(?:-(?<stop>\d+))?节\s+(?<room>\S+)(?:\s+(?<teacher>\S+))?$",
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    final weeks = _expandWeeks(match.namedGroup("weeks") ?? "");
    if (weeks.isEmpty) {
      return null;
    }
    final start = int.parse(match.namedGroup("start") ?? "1");
    final stop = int.parse(
      match.namedGroup("stop") ?? match.namedGroup("start")!,
    );
    return _GxuCourseSegment(
      courseKey: course.key,
      weeks: weeks,
      day: _parseWeekday(match.namedGroup("day") ?? ""),
      start: start,
      stop: stop,
      classroom: match.namedGroup("room") ?? "",
      teacher: match.namedGroup("teacher") ?? course.teacher,
    );
  }

  List<int> _expandWeeks(String text) {
    final normalized = text
        .replaceAll("、", ",")
        .replaceAll("，", ",")
        .replaceAll(" ", "");
    final weeks = <int>{};
    for (final rawPart in normalized.split(",")) {
      if (rawPart.isEmpty) continue;
      final odd = rawPart.contains("单");
      final even = rawPart.contains("双");
      final part = rawPart.replaceAll(RegExp(r"[单双]"), "");
      final bounds = part.split("-");
      final start = int.tryParse(bounds.first) ?? 0;
      final stop = int.tryParse(bounds.last) ?? start;
      for (var week = start; week <= stop; week++) {
        if (odd && week.isEven) continue;
        if (even && week.isOdd) continue;
        weeks.add(week);
      }
    }
    return weeks.toList()..sort();
  }

  int _parseWeekday(String text) {
    const weekdayMap = {
      "一": 1,
      "二": 2,
      "三": 3,
      "四": 4,
      "五": 5,
      "六": 6,
      "日": 7,
      "天": 7,
    };
    return weekdayMap[text] ?? 1;
  }

  int _resolveSemesterLength(List<_GxuCourseSegment> segments) {
    var maxWeek = 1;
    for (final item in segments) {
      if (item.weeks.isNotEmpty && item.weeks.last > maxWeek) {
        maxWeek = item.weeks.last;
      }
    }
    return maxWeek;
  }

  ClassTableData _buildClassTable({
    required String semesterCode,
    required String termStartDay,
    required int semesterLength,
    required List<GxuCourseRecord> courses,
    required List<_GxuCourseSegment> parsedSegments,
  }) {
    final table = ClassTableData(
      semesterCode: semesterCode,
      termStartDay: termStartDay,
      semesterLength: semesterLength,
    );
    final detailIndex = <String, int>{};
    final courseMap = {for (final item in courses) item.key: item};

    for (final course in courses) {
      detailIndex[course.key] = table.classDetail.length;
      table.classDetail.add(
        ClassDetail(
          name: course.courseName,
          code: course.courseCode,
          number: course.classNumber,
        ),
      );
    }
    _appendArrangements(
      table: table,
      detailIndex: detailIndex,
      parsedSegments: parsedSegments,
      semesterLength: semesterLength,
    );
    _appendNotArranged(table, courses, parsedSegments, courseMap);
    return table;
  }

  void _appendArrangements({
    required ClassTableData table,
    required Map<String, int> detailIndex,
    required List<_GxuCourseSegment> parsedSegments,
    required int semesterLength,
  }) {
    final grouped = <String, List<_GxuCourseSegment>>{};
    for (final item in parsedSegments) {
      grouped.putIfAbsent(item.mergeKey, () => []).add(item);
    }
    for (final items in grouped.values) {
      items.sort((a, b) => a.start.compareTo(b.start));
      var current = items.first;
      for (var i = 1; i < items.length; i++) {
        final next = items[i];
        if (next.start == current.stop + 1) {
          current = current.copyWith(stop: next.stop);
          continue;
        }
        table.timeArrangement.add(
          _toTimeArrangement(current, detailIndex, semesterLength),
        );
        current = next;
      }
      table.timeArrangement.add(
        _toTimeArrangement(current, detailIndex, semesterLength),
      );
    }
  }

  TimeArrangement _toTimeArrangement(
    _GxuCourseSegment item,
    Map<String, int> detailIndex,
    int semesterLength,
  ) {
    return TimeArrangement(
      source: Source.school,
      index: detailIndex[item.courseKey] ?? 0,
      weekList: List<bool>.generate(
        semesterLength,
        (index) => item.weeks.contains(index + 1),
      ),
      teacher: item.teacher,
      day: item.day,
      start: item.start,
      stop: item.stop,
      classroom: item.classroom,
    );
  }

  void _appendNotArranged(
    ClassTableData table,
    List<GxuCourseRecord> courses,
    List<_GxuCourseSegment> parsedSegments,
    Map<String, GxuCourseRecord> courseMap,
  ) {
    final arrangedKeys = parsedSegments.map((item) => item.courseKey).toSet();
    for (final key in courseMap.keys) {
      if (arrangedKeys.contains(key)) continue;
      final course = courseMap[key]!;
      table.notArranged.add(
        NotArrangementClassDetail(
          name: course.courseName,
          code: course.courseCode,
          number: course.classNumber,
          teacher: course.teacher,
        ),
      );
    }
  }
}

class GxuCourseRecord {
  final String semesterCode;
  final String courseCode;
  final String courseName;
  final String classNumber;
  final String className;
  final String teacher;
  final String scheduleText;

  const GxuCourseRecord({
    required this.semesterCode,
    required this.courseCode,
    required this.courseName,
    required this.classNumber,
    required this.className,
    required this.teacher,
    required this.scheduleText,
  });

  String get key => "$courseCode|$classNumber";

  factory GxuCourseRecord.fromJson(Map<String, dynamic> json) {
    return GxuCourseRecord(
      semesterCode: json["xqdm"]?.toString() ?? "",
      courseCode: json["kch"]?.toString() ?? "",
      courseName: json["kcmc"]?.toString() ?? "",
      classNumber: json["jxbh"]?.toString() ?? "",
      className: json["kcbjmc"]?.toString() ?? "",
      teacher: json["rkjs"]?.toString() ?? "",
      scheduleText: json["sksjdd"]?.toString() ?? "",
    );
  }
}

class _GxuCourseSegment {
  final String courseKey;
  final List<int> weeks;
  final int day;
  final int start;
  final int stop;
  final String classroom;
  final String teacher;

  const _GxuCourseSegment({
    required this.courseKey,
    required this.weeks,
    required this.day,
    required this.start,
    required this.stop,
    required this.classroom,
    required this.teacher,
  });

  String get mergeKey =>
      "$courseKey|$day|$classroom|$teacher|${weeks.join(",")}";

  _GxuCourseSegment copyWith({int? stop}) {
    return _GxuCourseSegment(
      courseKey: courseKey,
      weeks: weeks,
      day: day,
      start: start,
      stop: stop ?? this.stop,
      classroom: classroom,
      teacher: teacher,
    );
  }
}
