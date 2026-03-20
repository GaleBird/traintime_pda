import 'package:watermeter/model/gxu_ids/gxu_course_type.dart';

class GxuScoreSheet {
  final GxuScoreProfile profile;
  final List<GxuScoreEntry> entries;

  const GxuScoreSheet({required this.profile, required this.entries});

  factory GxuScoreSheet.fromPreviewJson(Map<String, dynamic> json) {
    final textMap = _mapOf(json["textMap"], "成绩基本信息缺失");
    final tableList = _listOf(json["tableList"]);
    final entries =
        tableList
            .map((item) => GxuScoreEntry.fromPreviewMap(_mapOf(item, "成绩记录异常")))
            .toList()
          ..sort(GxuScoreEntry.compareForDisplay);
    return GxuScoreSheet(
      profile: GxuScoreProfile.fromPreviewMap(textMap),
      entries: entries,
    );
  }

  factory GxuScoreSheet.fromJson(Map<String, dynamic> json) {
    final profile = GxuScoreProfile.fromJson(
      _mapOf(json["profile"], "缓存成绩档案损坏"),
    );
    final entries =
        _listOf(json["entries"])
            .map((item) => GxuScoreEntry.fromJson(_mapOf(item, "缓存成绩记录损坏")))
            .toList()
          ..sort(GxuScoreEntry.compareForDisplay);
    return GxuScoreSheet(profile: profile, entries: entries);
  }

  Map<String, dynamic> toJson() {
    return {
      "profile": profile.toJson(),
      "entries": entries.map((item) => item.toJson()).toList(),
    };
  }
}

class GxuScoreProfile {
  final String studentId;
  final String name;
  final String college;
  final String major;
  final String programLevel;
  final String studentType;
  final String weightedAverage;
  final String averageGpa;
  final String requiredCredits;
  final String earnedCredits;
  final String selectedCredits;
  final String degreeCredits;
  final String generatedAt;
  final String verificationCode;
  final String verificationSite;

  const GxuScoreProfile({
    required this.studentId,
    required this.name,
    required this.college,
    required this.major,
    required this.programLevel,
    required this.studentType,
    required this.weightedAverage,
    required this.averageGpa,
    required this.requiredCredits,
    required this.earnedCredits,
    required this.selectedCredits,
    required this.degreeCredits,
    required this.generatedAt,
    required this.verificationCode,
    required this.verificationSite,
  });

  factory GxuScoreProfile.fromPreviewMap(Map<String, dynamic> json) {
    return GxuScoreProfile(
      studentId: _stringOf(json["xh"]),
      name: _stringOf(json["xm"]),
      college: _stringOf(json["szyxsmc"]),
      major: _stringOf(json["bxzymc"]),
      programLevel: _stringOf(json["xslbmc"]),
      studentType: _stringOf(json["pyccmc"]),
      weightedAverage: _stringOf(json["jqpjcj"]),
      averageGpa: _stringOf(json["pjjd"]),
      requiredCredits: _stringOf(json["yxxf1"]),
      earnedCredits: _stringOf(json["yxxf2"]),
      selectedCredits: _stringOf(json["yxzxf"]),
      degreeCredits: _stringOf(json["xwkxf"]),
      generatedAt: _stringOf(json["date"]),
      verificationCode: _stringOf(json["jmzf"]),
      verificationSite: _stringOf(json["yzwz"]),
    );
  }

  factory GxuScoreProfile.fromJson(Map<String, dynamic> json) {
    return GxuScoreProfile(
      studentId: _stringOf(json["studentId"]),
      name: _stringOf(json["name"]),
      college: _stringOf(json["college"]),
      major: _stringOf(json["major"]),
      programLevel: _stringOf(json["programLevel"]),
      studentType: _stringOf(json["studentType"]),
      weightedAverage: _stringOf(json["weightedAverage"]),
      averageGpa: _stringOf(json["averageGpa"]),
      requiredCredits: _stringOf(json["requiredCredits"]),
      earnedCredits: _stringOf(json["earnedCredits"]),
      selectedCredits: _stringOf(json["selectedCredits"]),
      degreeCredits: _stringOf(json["degreeCredits"]),
      generatedAt: _stringOf(json["generatedAt"]),
      verificationCode: _stringOf(json["verificationCode"]),
      verificationSite: _stringOf(json["verificationSite"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "studentId": studentId,
      "name": name,
      "college": college,
      "major": major,
      "programLevel": programLevel,
      "studentType": studentType,
      "weightedAverage": weightedAverage,
      "averageGpa": averageGpa,
      "requiredCredits": requiredCredits,
      "earnedCredits": earnedCredits,
      "selectedCredits": selectedCredits,
      "degreeCredits": degreeCredits,
      "generatedAt": generatedAt,
      "verificationCode": verificationCode,
      "verificationSite": verificationSite,
    };
  }
}

class GxuScoreEntry {
  final int order;
  final String courseName;
  final String englishCourseName;
  final String courseCode;
  final String courseType;
  final String englishCourseType;
  final String examType;
  final String semesterCode;
  final String semesterName;
  final String credit;
  final String totalHours;
  final String score;
  final String englishScore;
  final String gpa;

  const GxuScoreEntry({
    required this.order,
    required this.courseName,
    required this.englishCourseName,
    required this.courseCode,
    required this.courseType,
    required this.englishCourseType,
    required this.examType,
    required this.semesterCode,
    required this.semesterName,
    required this.credit,
    required this.totalHours,
    required this.score,
    required this.englishScore,
    required this.gpa,
  });

  factory GxuScoreEntry.fromPreviewMap(Map<String, dynamic> json) {
    return GxuScoreEntry(
      order: _intOf(json["sort"]),
      courseName: _stringOf(json["kcmc"]),
      englishCourseName: _stringOf(json["kcywmc"]),
      courseCode: _stringOf(json["kch"]),
      courseType: _stringOf(json["kcxzmc"]),
      englishCourseType: _stringOf(json["kcxzywmc"]),
      examType: _stringOf(json["ksxzmc"]),
      semesterCode: _stringOf(json["xqdm"]),
      semesterName: _stringOf(json["xqmc"]),
      credit: _stringOf(json["xf"]),
      totalHours: _stringOf(json["zxs"]),
      score: _stringOf(json["zcj"]),
      englishScore: _stringOf(json["ywzcj"]),
      gpa: _stringOf(json["jd"]),
    );
  }

  factory GxuScoreEntry.fromJson(Map<String, dynamic> json) {
    return GxuScoreEntry(
      order: _intOf(json["order"]),
      courseName: _stringOf(json["courseName"]),
      englishCourseName: _stringOf(json["englishCourseName"]),
      courseCode: _stringOf(json["courseCode"]),
      courseType: _stringOf(json["courseType"]),
      englishCourseType: _stringOf(json["englishCourseType"]),
      examType: _stringOf(json["examType"]),
      semesterCode: _stringOf(json["semesterCode"]),
      semesterName: _stringOf(json["semesterName"]),
      credit: _stringOf(json["credit"]),
      totalHours: _stringOf(json["totalHours"]),
      score: _stringOf(json["score"]),
      englishScore: _stringOf(json["englishScore"]),
      gpa: _stringOf(json["gpa"]),
    );
  }

  bool get isDegreeCourse => gxuIsDegreeCourse(
    courseType: courseType,
    englishCourseType: englishCourseType,
  );

  double? get scoreValue => double.tryParse(score);
  double? get creditValue => double.tryParse(credit);
  double? get gpaValue => double.tryParse(gpa);
  String get selectionKey => "$semesterCode|$courseCode|$order|$courseName";

  Map<String, dynamic> toJson() {
    return {
      "order": order,
      "courseName": courseName,
      "englishCourseName": englishCourseName,
      "courseCode": courseCode,
      "courseType": courseType,
      "englishCourseType": englishCourseType,
      "examType": examType,
      "semesterCode": semesterCode,
      "semesterName": semesterName,
      "credit": credit,
      "totalHours": totalHours,
      "score": score,
      "englishScore": englishScore,
      "gpa": gpa,
    };
  }

  static int compareForDisplay(GxuScoreEntry left, GxuScoreEntry right) {
    final semesterDiff = right.semesterCode.compareTo(left.semesterCode);
    if (semesterDiff != 0) {
      return semesterDiff;
    }
    return left.order.compareTo(right.order);
  }
}

List<dynamic> _listOf(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is List) {
    return value.cast<dynamic>();
  }
  return const [];
}

Map<String, dynamic> _mapOf(dynamic value, String errorMessage) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw FormatException(errorMessage);
}

String _stringOf(dynamic value) => value?.toString().trim() ?? "";

int _intOf(dynamic value) => int.tryParse(_stringOf(value)) ?? 0;
