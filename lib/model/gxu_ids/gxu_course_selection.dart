import 'package:watermeter/model/gxu_ids/gxu_course_type.dart';

class GxuCourseSelectionSheet {
  final Map<String, String> semesterLabels;
  final List<GxuCourseSelectionEntry> entries;

  const GxuCourseSelectionSheet({
    required this.semesterLabels,
    required this.entries,
  });

  factory GxuCourseSelectionSheet.fromJson(Map<String, dynamic> json) {
    final semesterLabels = _stringMapOf(json["semesterLabels"]);
    final entries = _listOf(
      json["entries"],
    ).map((item) => GxuCourseSelectionEntry.fromJson(_mapOf(item))).toList();
    return GxuCourseSelectionSheet(
      semesterLabels: semesterLabels,
      entries: entries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "semesterLabels": semesterLabels,
      "entries": entries.map((item) => item.toJson()).toList(),
    };
  }
}

class GxuCourseSelectionEntry {
  static final RegExp _teacherSeparatorPattern = RegExp(r'[、,，;；/\n]+');

  final String semesterCode;
  final String semesterName;
  final String courseCode;
  final String courseName;
  final String classNumber;
  final String className;
  final String teacher;
  final String courseType;
  final String englishCourseType;
  final String credit;
  final String scheduleText;
  final String status;

  const GxuCourseSelectionEntry({
    required this.semesterCode,
    required this.semesterName,
    required this.courseCode,
    required this.courseName,
    required this.classNumber,
    required this.className,
    required this.teacher,
    required this.courseType,
    required this.englishCourseType,
    required this.credit,
    required this.scheduleText,
    required this.status,
  });

  factory GxuCourseSelectionEntry.fromRemoteMap(Map<String, dynamic> json) {
    return GxuCourseSelectionEntry(
      semesterCode: _stringOf(json["xqdm"]),
      semesterName: _stringOf(json["xqmc"]),
      courseCode: _stringOf(json["kch"]),
      courseName: _stringOf(json["kcmc"]),
      classNumber: _stringOf(json["jxbh"]),
      className: _stringOf(json["kcbjmc"]),
      teacher: _stringOf(json["rkjs"]),
      courseType: _stringOf(json["kcxzmc"]),
      englishCourseType: _stringOf(json["kcxzywmc"]),
      credit: _stringOf(json["xf"]),
      scheduleText: _stringOf(json["sksjdd"]),
      status: _stringOf(json["xkztmc"]),
    );
  }

  factory GxuCourseSelectionEntry.fromJson(Map<String, dynamic> json) {
    return GxuCourseSelectionEntry(
      semesterCode: _stringOf(json["semesterCode"]),
      semesterName: _stringOf(json["semesterName"]),
      courseCode: _stringOf(json["courseCode"]),
      courseName: _stringOf(json["courseName"]),
      classNumber: _stringOf(json["classNumber"]),
      className: _stringOf(json["className"]),
      teacher: _stringOf(json["teacher"]),
      courseType: _stringOf(json["courseType"]),
      englishCourseType: _stringOf(json["englishCourseType"]),
      credit: _stringOf(json["credit"]),
      scheduleText: _stringOf(json["scheduleText"]),
      status: _stringOf(json["status"]),
    );
  }

  bool get isDegreeCourse => gxuIsDegreeCourse(
    courseType: courseType,
    englishCourseType: englishCourseType,
  );

  double? get creditValue => double.tryParse(credit);

  String get primaryTeacher {
    final normalized = teacher.trim();
    if (normalized.isEmpty) {
      return "";
    }
    final teachers = normalized
        .split(_teacherSeparatorPattern)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (teachers.isEmpty) {
      return normalized;
    }
    return teachers.first;
  }

  GxuCourseSelectionEntry copyWith({String? semesterName}) {
    return GxuCourseSelectionEntry(
      semesterCode: semesterCode,
      semesterName: semesterName ?? this.semesterName,
      courseCode: courseCode,
      courseName: courseName,
      classNumber: classNumber,
      className: className,
      teacher: teacher,
      courseType: courseType,
      englishCourseType: englishCourseType,
      credit: credit,
      scheduleText: scheduleText,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "semesterCode": semesterCode,
      "semesterName": semesterName,
      "courseCode": courseCode,
      "courseName": courseName,
      "classNumber": classNumber,
      "className": className,
      "teacher": teacher,
      "courseType": courseType,
      "englishCourseType": englishCourseType,
      "credit": credit,
      "scheduleText": scheduleText,
      "status": status,
    };
  }
}

String _stringOf(dynamic value) {
  return value?.toString() ?? "";
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const FormatException("广西大学选课缓存已损坏。");
}

List<dynamic> _listOf(dynamic value) {
  if (value is List) {
    return value;
  }
  throw const FormatException("广西大学选课缓存已损坏。");
}

Map<String, String> _stringMapOf(dynamic value) {
  if (value is Map<String, String>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ""),
    );
  }
  throw const FormatException("广西大学选课缓存已损坏。");
}
