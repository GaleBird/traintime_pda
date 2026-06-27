import 'dart:convert';
import 'dart:math';

typedef GxuCourseEvaluationCommentPicker = String Function();

const gxuCourseEvaluationCommentOptions = <String>[
  '老师授课认真负责，课程内容清晰，课堂组织有序，学习收获较大。',
  '老师备课充分，讲解条理清楚，重点突出，对课程学习帮助很大。',
  '老师教学态度认真，课堂节奏合理，能够结合案例帮助理解知识点。',
  '老师讲授内容充实，互动反馈及时，课程安排清晰，学习体验较好。',
  '老师责任心强，讲解耐心细致，课程目标明确，整体收获明显。',
  '老师课堂组织规范，知识点讲解清楚，作业与课程内容衔接较好。',
  '老师授课逻辑清晰，能够启发思考，课程内容具有较好的实践价值。',
  '老师教学准备充分，答疑耐心，课程内容安排合理，对专业学习有帮助。',
];

String pickRandomGxuCourseEvaluationComment([Random? random]) {
  final options = gxuCourseEvaluationCommentOptions;
  if (options.isEmpty) {
    throw StateError('GXU course evaluation comment options are empty.');
  }
  return options[(random ?? Random()).nextInt(options.length)];
}

class GxuCourseEvaluationCourse {
  final String coursePlanId;
  final String courseName;
  final bool needsEvaluation;

  const GxuCourseEvaluationCourse({
    required this.coursePlanId,
    required this.courseName,
    required this.needsEvaluation,
  });

  factory GxuCourseEvaluationCourse.fromRemoteMap(Map<String, dynamic> json) {
    final templateId = _stringOf(json['jxzlpjtxid']);
    final requiredFlag = _stringOf(json['sfjxzlpj']);
    final completedFlag = _stringOf(json['jxzlpjsfwc']);
    return GxuCourseEvaluationCourse(
      coursePlanId: _stringOf(json['jxjhxxid']),
      courseName: _stringOf(json['kcmc']),
      needsEvaluation:
          requiredFlag != 'N' && templateId.isNotEmpty && completedFlag != 'Y',
    );
  }
}

class GxuCourseEvaluationSubmission {
  final String coursePlanId;
  final List<GxuCourseEvaluationObjectiveAnswer> objectiveAnswers;
  final List<GxuCourseEvaluationSubjectiveAnswer> subjectiveAnswers;

  const GxuCourseEvaluationSubmission({
    required this.coursePlanId,
    required this.objectiveAnswers,
    required this.subjectiveAnswers,
  });

  factory GxuCourseEvaluationSubmission.fromDetail({
    required String coursePlanId,
    required Map<String, dynamic> detail,
    String? comment,
    GxuCourseEvaluationCommentPicker? commentPicker,
  }) {
    final data = _detailData(detail);
    final evaluatedTargetIds = _stringSetOf(data['ypjsList']);
    final targets = _targetsOf(data);
    final questions = _questionsOf(data);
    final resolvedCommentPicker = _resolveCommentPicker(
      comment: comment,
      commentPicker: commentPicker,
    );
    final objectiveAnswers = <GxuCourseEvaluationObjectiveAnswer>[];
    final subjectiveAnswers = <GxuCourseEvaluationSubjectiveAnswer>[];
    for (final target in targets) {
      if (evaluatedTargetIds.contains(target.id)) {
        continue;
      }
      _appendAnswers(
        target: target,
        questions: questions,
        commentPicker: resolvedCommentPicker,
        objectiveAnswers: objectiveAnswers,
        subjectiveAnswers: subjectiveAnswers,
      );
    }
    return GxuCourseEvaluationSubmission(
      coursePlanId: coursePlanId,
      objectiveAnswers: List.unmodifiable(objectiveAnswers),
      subjectiveAnswers: List.unmodifiable(subjectiveAnswers),
    );
  }

  bool get isEmpty => objectiveAnswers.isEmpty && subjectiveAnswers.isEmpty;

  Map<String, dynamic> toRequestData() {
    return {
      'jxjhxxid': coursePlanId,
      'kgtjg': jsonEncode(
        objectiveAnswers.map((item) => item.toJson()).toList(),
      ),
      'zgtjg': jsonEncode(
        subjectiveAnswers.map((item) => item.toJson()).toList(),
      ),
      'sm': '',
    };
  }
}

class GxuCourseEvaluationObjectiveAnswer {
  final String jszgh;
  final String jsxm;
  final String jxzlpjtmxxid;
  final String tmbh;
  final String jxzlpjkgtxxxxid;
  final String xxbh;
  final String fs;

  const GxuCourseEvaluationObjectiveAnswer({
    required this.jszgh,
    required this.jsxm,
    required this.jxzlpjtmxxid,
    required this.tmbh,
    required this.jxzlpjkgtxxxxid,
    required this.xxbh,
    required this.fs,
  });

  Map<String, dynamic> toJson() {
    return {
      'jszgh': jszgh,
      'jsxm': jsxm,
      'jxzlpjtmxxid': jxzlpjtmxxid,
      'tmbh': tmbh,
      'jxzlpjkgtxxxxid': jxzlpjkgtxxxxid,
      'xxbh': xxbh,
      'fs': fs,
    };
  }
}

class GxuCourseEvaluationSubjectiveAnswer {
  final String jszgh;
  final String jsxm;
  final String jxzlpjtmxxid;
  final String tmbh;
  final String tmda;

  const GxuCourseEvaluationSubjectiveAnswer({
    required this.jszgh,
    required this.jsxm,
    required this.jxzlpjtmxxid,
    required this.tmbh,
    required this.tmda,
  });

  Map<String, dynamic> toJson() {
    return {
      'jszgh': jszgh,
      'jsxm': jsxm,
      'jxzlpjtmxxid': jxzlpjtmxxid,
      'tmbh': tmbh,
      'tmda': tmda,
    };
  }
}

class _EvaluationTarget {
  final String id;
  final String name;

  const _EvaluationTarget({required this.id, required this.name});
}

void _appendAnswers({
  required _EvaluationTarget target,
  required List<Map<String, dynamic>> questions,
  required GxuCourseEvaluationCommentPicker commentPicker,
  required List<GxuCourseEvaluationObjectiveAnswer> objectiveAnswers,
  required List<GxuCourseEvaluationSubjectiveAnswer> subjectiveAnswers,
}) {
  for (final question in questions) {
    if (_stringOf(question['sfzgt']) == 'Y') {
      subjectiveAnswers.add(_subjectiveAnswer(target, question, commentPicker));
      continue;
    }
    objectiveAnswers.add(_objectiveAnswer(target, question));
  }
}

GxuCourseEvaluationSubjectiveAnswer _subjectiveAnswer(
  _EvaluationTarget target,
  Map<String, dynamic> question,
  GxuCourseEvaluationCommentPicker commentPicker,
) {
  return GxuCourseEvaluationSubjectiveAnswer(
    jszgh: target.id,
    jsxm: target.name,
    jxzlpjtmxxid: _stringOf(question['jxzlpjtmxxid']),
    tmbh: _stringOf(question['tmbh']),
    tmda: _validatedComment(commentPicker()),
  );
}

GxuCourseEvaluationCommentPicker _resolveCommentPicker({
  required String? comment,
  required GxuCourseEvaluationCommentPicker? commentPicker,
}) {
  if (comment != null && commentPicker != null) {
    throw ArgumentError('comment and commentPicker cannot both be provided.');
  }
  if (comment != null) {
    return () => _validatedComment(comment);
  }
  if (commentPicker != null) {
    return () => _validatedComment(commentPicker());
  }
  return pickRandomGxuCourseEvaluationComment;
}

String _validatedComment(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    throw const FormatException('GXU course evaluation comment is empty.');
  }
  return text;
}

GxuCourseEvaluationObjectiveAnswer _objectiveAnswer(
  _EvaluationTarget target,
  Map<String, dynamic> question,
) {
  if (_stringOf(question['sffzxx']) == 'Y') {
    return _scoredObjectiveAnswer(target, question);
  }
  final option = _bestOptionOf(question);
  return GxuCourseEvaluationObjectiveAnswer(
    jszgh: target.id,
    jsxm: target.name,
    jxzlpjtmxxid: _stringOf(question['jxzlpjtmxxid']),
    tmbh: _stringOf(question['tmbh']),
    jxzlpjkgtxxxxid: _stringOf(option['jxzlpjkgtxxxxid']),
    xxbh: _stringOf(option['xxbh']),
    fs: _scoreString(option['fs']),
  );
}

GxuCourseEvaluationObjectiveAnswer _scoredObjectiveAnswer(
  _EvaluationTarget target,
  Map<String, dynamic> question,
) {
  return GxuCourseEvaluationObjectiveAnswer(
    jszgh: target.id,
    jsxm: target.name,
    jxzlpjtmxxid: _stringOf(question['jxzlpjtmxxid']),
    tmbh: _stringOf(question['tmbh']),
    jxzlpjkgtxxxxid: '',
    xxbh: '',
    fs: _scoreString(question['fs']),
  );
}

Map<String, dynamic> _bestOptionOf(Map<String, dynamic> question) {
  final options = _listOf(question['kgtxxList']).map(_mapOf).toList();
  if (options.isEmpty) {
    throw const FormatException('GXU course evaluation option list is empty.');
  }
  options.sort(
    (left, right) =>
        _requiredScore(right['fs']).compareTo(_requiredScore(left['fs'])),
  );
  return options.first;
}

Map<String, dynamic> _detailData(Map<String, dynamic> detail) {
  final nested = detail['data'];
  if (nested is Map) {
    return _mapOf(nested);
  }
  return detail;
}

List<_EvaluationTarget> _targetsOf(Map<String, dynamic> detail) {
  if (_stringOf(detail['pjtxlbdm']) == '03') {
    return [
      _EvaluationTarget(
        id: _stringOf(detail['kch']),
        name: _stringOf(detail['kcmc']),
      ),
    ];
  }
  final targets = _listOf(detail['jsxxList']).map(_teacherTargetOf).toList();
  if (targets.isEmpty) {
    throw const FormatException('GXU course evaluation teacher list is empty.');
  }
  return targets;
}

_EvaluationTarget _teacherTargetOf(dynamic value) {
  final map = _mapOf(value);
  return _EvaluationTarget(
    id: _stringOf(map['jszgh']),
    name: _stringOf(map['jsxm']),
  );
}

List<Map<String, dynamic>> _questionsOf(Map<String, dynamic> detail) {
  final questions = <Map<String, dynamic>>[];
  for (final category in _listOf(detail['tmlbList']).map(_mapOf)) {
    questions.addAll(_listOf(category['tmxxList']).map(_mapOf));
  }
  if (questions.isEmpty) {
    throw const FormatException(
      'GXU course evaluation question list is empty.',
    );
  }
  return questions;
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

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const FormatException('GXU course evaluation payload is not a map.');
}

Set<String> _stringSetOf(dynamic value) {
  return _listOf(
    value,
  ).expand(_evaluatedTargetIdsOf).where((item) => item.isNotEmpty).toSet();
}

Iterable<String> _evaluatedTargetIdsOf(dynamic value) {
  if (value is! Map) {
    final text = _stringOf(value);
    return text.isEmpty ? const [] : [text];
  }
  final map = _mapOf(value);
  for (final key in ['jszgh', 'kch', 'id', 'pjdxid']) {
    final id = _stringOf(map[key]);
    if (id.isNotEmpty) {
      return [id];
    }
  }
  throw const FormatException(
    'GXU course evaluation evaluated target item is invalid.',
  );
}

String _stringOf(dynamic value) => value?.toString().trim() ?? '';

String _scoreString(dynamic value) {
  final raw = _stringOf(value);
  final parsed = _requiredScore(raw);
  if (parsed % 1 == 0) {
    return parsed.toInt().toString();
  }
  return parsed.toString();
}

num _requiredScore(dynamic value) {
  final raw = _stringOf(value);
  final parsed = num.tryParse(raw);
  if (parsed == null) {
    throw FormatException('GXU course evaluation score is invalid: $raw');
  }
  return parsed;
}
