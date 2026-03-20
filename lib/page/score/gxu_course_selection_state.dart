import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/score/score_statics.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_selection.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_selection_session.dart';
import 'package:watermeter/repository/logger.dart';

enum GxuCourseCategoryFilter { all, degree, nonDegree }

class GxuCourseSelectionSummary {
  final int courseCount;
  final int degreeCourseCount;
  final int nonDegreeCourseCount;
  final double totalCredits;
  final double degreeCredits;
  final double nonDegreeCredits;

  const GxuCourseSelectionSummary({
    required this.courseCount,
    required this.degreeCourseCount,
    required this.nonDegreeCourseCount,
    required this.totalCredits,
    required this.degreeCredits,
    required this.nonDegreeCredits,
  });

  factory GxuCourseSelectionSummary.fromEntries(
    List<GxuCourseSelectionEntry> entries,
  ) {
    var degreeCourseCount = 0;
    var degreeCredits = 0.0;
    var nonDegreeCredits = 0.0;
    for (final entry in entries) {
      final credit = entry.creditValue ?? 0.0;
      if (entry.isDegreeCourse) {
        degreeCourseCount++;
        degreeCredits += credit;
      } else {
        nonDegreeCredits += credit;
      }
    }
    return GxuCourseSelectionSummary(
      courseCount: entries.length,
      degreeCourseCount: degreeCourseCount,
      nonDegreeCourseCount: entries.length - degreeCourseCount,
      totalCredits: degreeCredits + nonDegreeCredits,
      degreeCredits: degreeCredits,
      nonDegreeCredits: nonDegreeCredits,
    );
  }
}

class GxuCourseSelectionState extends ChangeNotifier {
  bool _disposed = false;
  ScoreFetchState state = ScoreFetchState.fetching;
  GxuCourseSelectionSheet? sheet;
  String? error;
  String _search = "";
  String _selectedSemesterCode = "";
  GxuCourseCategoryFilter _categoryFilter = GxuCourseCategoryFilter.all;

  GxuCourseSelectionState(BuildContext context) {
    refreshingState(context);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> refreshingState(
    BuildContext context, {
    bool isForce = false,
  }) async {
    state = ScoreFetchState.fetching;
    error = null;
    sheet = null;
    _search = "";
    _selectedSemesterCode = "";
    _categoryFilter = GxuCourseCategoryFilter.all;
    notifyListeners();
    try {
      sheet = await GxuCourseSelectionSession().getCourseSelectionSheet(
        force: isForce,
      );
      state = ScoreFetchState.ok;
    } catch (e, s) {
      log.error(
        "[GxuCourseSelectionState] Error on fetching course info.",
        e,
        s,
      );
      state = ScoreFetchState.error;
      error = e.toString();
    } finally {
      if (context.mounted &&
          GxuCourseSelectionSession.isCourseSelectionCacheUsed) {
        showToast(
          context: context,
          msg: FlutterI18n.translate(
            context,
            "score.course_selection.cache_message",
          ),
        );
      }
      notifyListeners();
    }
  }

  String get search => _search;

  String get selectedSemesterCode => _selectedSemesterCode;

  GxuCourseCategoryFilter get categoryFilter => _categoryFilter;

  List<String> get semesterCodes {
    final codes = {
      for (final entry in sheet?.entries ?? const <GxuCourseSelectionEntry>[])
        entry.semesterCode,
    }.toList();
    codes.sort((left, right) => right.compareTo(left));
    return codes;
  }

  String semesterLabelOf(String code) {
    final label = sheet?.semesterLabels[code];
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return code.trim().isEmpty ? "-" : code;
  }

  List<GxuCourseSelectionEntry> get filteredEntries {
    final keyword = _search.trim().toLowerCase();
    return (sheet?.entries ?? const <GxuCourseSelectionEntry>[])
        .where(_matchSemester)
        .where(_matchCategory)
        .where((entry) => _matchKeyword(entry, keyword))
        .toList();
  }

  Map<String, List<GxuCourseSelectionEntry>> get groupedEntries {
    final grouped = <String, List<GxuCourseSelectionEntry>>{};
    for (final entry in filteredEntries) {
      grouped.putIfAbsent(entry.semesterCode, () => []).add(entry);
    }
    final sortedCodes = grouped.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return {for (final code in sortedCodes) code: grouped[code]!};
  }

  GxuCourseSelectionSummary get summary {
    return GxuCourseSelectionSummary.fromEntries(filteredEntries);
  }

  GxuCourseSelectionSummary summaryOf(String semesterCode) {
    return GxuCourseSelectionSummary.fromEntries(
      groupedEntries[semesterCode] ?? const <GxuCourseSelectionEntry>[],
    );
  }

  bool _matchSemester(GxuCourseSelectionEntry entry) {
    return _selectedSemesterCode.isEmpty ||
        entry.semesterCode == _selectedSemesterCode;
  }

  bool _matchCategory(GxuCourseSelectionEntry entry) {
    return switch (_categoryFilter) {
      GxuCourseCategoryFilter.all => true,
      GxuCourseCategoryFilter.degree => entry.isDegreeCourse,
      GxuCourseCategoryFilter.nonDegree => !entry.isDegreeCourse,
    };
  }

  bool _matchKeyword(GxuCourseSelectionEntry entry, String keyword) {
    if (keyword.isEmpty) {
      return true;
    }
    final haystack = [
      entry.courseName,
      entry.courseCode,
      entry.courseType,
      entry.classNumber,
      entry.className,
      entry.teacher,
      entry.scheduleText,
      entry.status,
      semesterLabelOf(entry.semesterCode),
    ].join(" ").toLowerCase();
    return haystack.contains(keyword);
  }

  set search(String value) {
    _search = value;
    notifyListeners();
  }

  set selectedSemesterCode(String value) {
    _selectedSemesterCode = value;
    notifyListeners();
  }

  set categoryFilter(GxuCourseCategoryFilter value) {
    _categoryFilter = value;
    notifyListeners();
  }
}
