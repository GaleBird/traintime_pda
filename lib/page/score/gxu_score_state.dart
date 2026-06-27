import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/score/gxu_auto_evaluation_result_dialog.dart';
import 'package:watermeter/page/score/score_statics.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_service_error_message.dart';
import 'package:watermeter/repository/logger.dart';

String describeGxuAutoEvaluationFeedback(
  GxuCourseEvaluationReport report, {
  String? refreshNote,
}) {
  final submitted = report.submittedCourseCount;
  final skipped = report.skippedCourseCount;
  final suffix = refreshNote ?? '';
  if (submitted > 0 && skipped > 0) {
    return '已完成 $submitted 门课程评价，$skipped 门课程无需重复提交，成绩已刷新。$suffix';
  }
  if (submitted > 0) {
    return '已完成 $submitted 门课程评价，成绩已刷新。$suffix';
  }
  if (skipped > 0) {
    return '未发现新的可提交评教，$skipped 门课程无需重复提交，成绩已刷新。$suffix';
  }
  return '已确认课程评价全部完成，本次没有提交新评价，成绩已刷新。$suffix';
}

String describeGxuAutoEvaluationProgress(GxuCourseEvaluationReport report) {
  final submitted = report.submittedCourseCount;
  final skipped = report.skippedCourseCount;
  if (submitted > 0 && skipped > 0) {
    return '已提交 $submitted 门课程评价，$skipped 门无需重复提交，正在刷新成绩。';
  }
  if (submitted > 0) {
    return '已提交 $submitted 门课程评价，正在刷新成绩。';
  }
  if (skipped > 0) {
    return '$skipped 门课程无需重复提交，正在刷新成绩。';
  }
  return '已确认课程评价全部完成，正在刷新成绩。';
}

class GxuScoreState extends ChangeNotifier {
  bool _disposed = false;
  ScoreFetchState state = ScoreFetchState.fetching;
  GxuScoreSheet? sheet;
  String? error;
  String? errorTitle;
  bool isEvaluationRequired = false;
  bool isAutoEvaluating = false;
  String? autoEvaluationProgress;
  String? autoEvaluationFeedback;
  String _search = "";
  String _selectedSemesterCode = "";
  bool _isSelectMode = false;
  final Map<String, bool> _selection = {};

  GxuScoreState(BuildContext context) {
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
    errorTitle = null;
    isEvaluationRequired = false;
    isAutoEvaluating = false;
    autoEvaluationProgress = null;
    autoEvaluationFeedback = null;
    sheet = null;
    _search = "";
    _selectedSemesterCode = "";
    _isSelectMode = false;
    _selection.clear();
    notifyListeners();
    try {
      sheet = await GxuScoreSession().getScoreSheet(force: isForce);
      _initSelectionState();
      state = ScoreFetchState.ok;
    } catch (e, s) {
      log.error("[GxuScoreState] Error on fetching score info.", e, s);
      state = ScoreFetchState.error;
      final message = describeGxuServiceError(e);
      errorTitle = message.title;
      error = message.description;
      isEvaluationRequired = e is GxuScoreEvaluationRequiredException;
    } finally {
      if (context.mounted && GxuScoreSession.isScoreListCacheUsed) {
        showToast(
          context: context,
          msg: FlutterI18n.translate(context, "score.cache_message"),
        );
      }
      notifyListeners();
    }
  }

  Future<void> autoEvaluateAndRefresh(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    state = ScoreFetchState.fetching;
    error = null;
    errorTitle = null;
    isEvaluationRequired = false;
    isAutoEvaluating = true;
    autoEvaluationProgress = '正在检查课程评价状态，不会重复提交已完成课程。';
    autoEvaluationFeedback = null;
    sheet = null;
    notifyListeners();
    try {
      final result = await GxuScoreSession().autoEvaluateAndFetchScoreSheet(
        onEvaluationReport: (report) {
          autoEvaluationProgress = describeGxuAutoEvaluationProgress(report);
          notifyListeners();
        },
      );
      sheet = result.sheet;
      _initSelectionState();
      state = ScoreFetchState.ok;
      autoEvaluationFeedback = describeGxuAutoEvaluationFeedback(
        result.report,
        refreshNote: result.refreshNote,
      );
      isAutoEvaluating = false;
      notifyListeners();
      if (navigator.mounted) {
        await showGxuAutoEvaluationResultDialog(
          navigator.context,
          message: autoEvaluationFeedback!,
        );
      }
    } catch (e, s) {
      log.error("[GxuScoreState] Error on auto evaluating scores.", e, s);
      state = ScoreFetchState.error;
      final message = describeGxuServiceError(e);
      errorTitle = message.title;
      error = message.description;
      isEvaluationRequired = e is GxuScoreEvaluationRequiredException;
    } finally {
      isAutoEvaluating = false;
      notifyListeners();
    }
  }

  String get search => _search;
  String get selectedSemesterCode => _selectedSemesterCode;
  GxuScoreProfile get profile => sheet!.profile;
  bool get isSelectMode => _isSelectMode;

  List<String> get semesterCodes {
    final codes = {
      for (final item in sheet?.entries ?? const <GxuScoreEntry>[])
        item.semesterCode,
    }.toList();
    codes.sort((left, right) => right.compareTo(left));
    return codes;
  }

  String semesterLabelOf(String code) {
    for (final item in sheet?.entries ?? const <GxuScoreEntry>[]) {
      if (item.semesterCode == code && item.semesterName.isNotEmpty) {
        return item.semesterName;
      }
    }
    return code;
  }

  List<GxuScoreEntry> get filteredEntries {
    final keyword = _search.trim().toLowerCase();
    return (sheet?.entries ?? const <GxuScoreEntry>[])
        .where((item) => _matchSemester(item))
        .where((item) => _matchKeyword(item, keyword))
        .toList();
  }

  List<GxuScoreEntry> get selectedEntries =>
      (sheet?.entries ?? const <GxuScoreEntry>[])
          .where(isEntrySelected)
          .toList();

  String bottomInfo(BuildContext context) => FlutterI18n.translate(
    context,
    "score.summary",
    translationParams: {
      "chosen": selectedEntries.length.toString(),
      "credit": evalCredit(false).toStringAsFixed(2),
      "avg": evalAvg(false).toStringAsFixed(2),
      "gpa": evalAvg(false, isGPA: true).toStringAsFixed(2),
    },
  );

  String dialogSummary(BuildContext context) => FlutterI18n.translate(
    context,
    "score.gxu_page.selection_summary",
    translationParams: {
      "chosen": selectedEntries.length.toString(),
      "credit": evalCredit(false).toStringAsFixed(2),
      "avg": evalAvg(false).toStringAsFixed(2),
      "gpa": evalAvg(false, isGPA: true).toStringAsFixed(2),
      "credit_all": evalCredit(true).toStringAsFixed(2),
      "avg_all": evalAvg(true).toStringAsFixed(2),
      "gpa_all": evalAvg(true, isGPA: true).toStringAsFixed(2),
    },
  );

  Map<String, List<GxuScoreEntry>> get groupedEntries {
    final grouped = <String, List<GxuScoreEntry>>{};
    for (final item in filteredEntries) {
      grouped.putIfAbsent(item.semesterCode, () => []).add(item);
    }
    final sortedCodes = grouped.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return {for (final code in sortedCodes) code: grouped[code]!};
  }

  bool isEntrySelected(GxuScoreEntry entry) {
    return _selection[entry.selectionKey] ?? true;
  }

  void toggleEntrySelection(GxuScoreEntry entry) {
    _selection[entry.selectionKey] = !isEntrySelected(entry);
    notifyListeners();
  }

  void setSelectMode(bool value) {
    _isSelectMode = value;
    notifyListeners();
  }

  void setVisibleSelectionState(ChoiceState state) {
    for (final entry in filteredEntries) {
      final key = entry.selectionKey;
      switch (state) {
        case ChoiceState.all:
        case ChoiceState.original:
          _selection[key] = true;
        case ChoiceState.none:
          _selection[key] = false;
      }
    }
    notifyListeners();
  }

  double evalCredit(bool isAll) {
    final entries = _entriesForCalculation(isAll);
    var totalCredit = 0.0;
    for (final entry in entries) {
      totalCredit += entry.creditValue ?? 0.0;
    }
    return totalCredit;
  }

  double evalAvg(bool isAll, {bool isGPA = false}) {
    final entries = _entriesForCalculation(isAll);
    var totalWeighted = 0.0;
    var totalCredit = 0.0;
    for (final entry in entries) {
      final credit = entry.creditValue;
      final value = isGPA ? entry.gpaValue : entry.scoreValue;
      if (credit == null || value == null) {
        continue;
      }
      totalWeighted += value * credit;
      totalCredit += credit;
    }
    return totalCredit == 0 ? 0.0 : totalWeighted / totalCredit;
  }

  bool _matchSemester(GxuScoreEntry item) {
    return _selectedSemesterCode.isEmpty ||
        item.semesterCode == _selectedSemesterCode;
  }

  bool _matchKeyword(GxuScoreEntry item, String keyword) {
    if (keyword.isEmpty) {
      return true;
    }
    final haystack = [
      item.courseName,
      item.englishCourseName,
      item.courseCode,
      item.semesterName,
    ].join(" ").toLowerCase();
    return haystack.contains(keyword);
  }

  List<GxuScoreEntry> _entriesForCalculation(bool isAll) {
    final source = isAll
        ? sheet?.entries ?? const <GxuScoreEntry>[]
        : selectedEntries;
    return source.where(_canCount).toList();
  }

  bool _canCount(GxuScoreEntry entry) {
    return entry.creditValue != null &&
        entry.creditValue! > 0 &&
        entry.scoreValue != null &&
        entry.gpaValue != null;
  }

  void _initSelectionState() {
    for (final entry in sheet?.entries ?? const <GxuScoreEntry>[]) {
      _selection[entry.selectionKey] = true;
    }
  }

  set search(String value) {
    _search = value;
    notifyListeners();
  }

  set selectedSemesterCode(String value) {
    _selectedSemesterCode = value;
    notifyListeners();
  }
}
