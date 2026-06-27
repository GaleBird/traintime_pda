import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_course_evaluation_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_score_session.dart';

void main() {
  test('throws evaluation-required without running auto evaluator', () async {
    final remote = _FakeScoreRemoteSource(checkResults: [false]);
    final evaluator = _FakeAutoEvaluator();
    final cache = _FakeScoreCache();

    expect(
      () => GxuScoreSession(
        remoteSource: remote,
        autoEvaluator: evaluator,
        cache: cache,
      ).getScoreSheet(force: true),
      throwsA(isA<GxuScoreEvaluationRequiredException>()),
    );
    expect(evaluator.callCount, 0);
    expect(remote.previewCount, 0);
  });

  test(
    'auto evaluation is explicit and reloads score after confirmation path',
    () async {
      final remote = _FakeScoreRemoteSource(checkResults: [true]);
      final evaluator = _FakeAutoEvaluator();
      final cache = _FakeScoreCache();

      final sheet = await GxuScoreSession(
        remoteSource: remote,
        autoEvaluator: evaluator,
        cache: cache,
      ).autoEvaluateAndGetScoreSheet();

      expect(evaluator.callCount, 1);
      expect(remote.prepareCount, 1);
      expect(remote.checkCount, 1);
      expect(remote.previewCount, 1);
      expect(sheet.profile.studentId, 'S001');
      expect(cache.dumpedSheet, same(sheet));
    },
  );

  test(
    'does not auto evaluate when score sheet is already printable',
    () async {
      final remote = _FakeScoreRemoteSource(checkResults: [true]);
      final evaluator = _FakeAutoEvaluator();
      final cache = _FakeScoreCache();

      await GxuScoreSession(
        remoteSource: remote,
        autoEvaluator: evaluator,
        cache: cache,
      ).getScoreSheet(force: true);

      expect(evaluator.callCount, 0);
      expect(remote.checkCount, 1);
    },
  );

  test(
    'explicit auto evaluation runs even when score sheet is printable',
    () async {
      final remote = _FakeScoreRemoteSource(checkResults: [true]);
      final evaluator = _FakeAutoEvaluator();
      final cache = _FakeScoreCache();

      final sheet = await GxuScoreSession(
        remoteSource: remote,
        autoEvaluator: evaluator,
        cache: cache,
      ).autoEvaluateAndGetScoreSheet();

      expect(evaluator.callCount, 1);
      expect(remote.prepareCount, 1);
      expect(remote.checkCount, 1);
      expect(remote.previewCount, 1);
      expect(sheet.profile.studentId, 'S001');
    },
  );

  test('explicit auto evaluation runs before score module warm-up', () async {
    final events = <String>[];
    final remote = _FakeScoreRemoteSource(checkResults: [true], events: events);
    final evaluator = _FakeAutoEvaluator(events: events);
    final cache = _FakeScoreCache();

    await GxuScoreSession(
      remoteSource: remote,
      autoEvaluator: evaluator,
      cache: cache,
    ).autoEvaluateAndGetScoreSheet();

    expect(events, ['evaluate', 'check', 'prepare', 'preview']);
  });

  test(
    'explicit auto evaluation returns evaluation report with refreshed score',
    () async {
      final remote = _FakeScoreRemoteSource(checkResults: [true]);
      const report = GxuCourseEvaluationReport(
        submittedCourseCount: 2,
        skippedCourseCount: 1,
      );
      final evaluator = _FakeAutoEvaluator(report: report);
      final cache = _FakeScoreCache();

      final result = await GxuScoreSession(
        remoteSource: remote,
        autoEvaluator: evaluator,
        cache: cache,
      ).autoEvaluateAndFetchScoreSheet();

      expect(result.report, same(report));
      expect(result.sheet.profile.studentId, 'S001');
      expect(cache.dumpedSheet, same(result.sheet));
    },
  );

  test('reports evaluation status before score refresh starts', () async {
    final events = <String>[];
    const report = GxuCourseEvaluationReport(
      submittedCourseCount: 0,
      skippedCourseCount: 0,
    );
    final remote = _FakeScoreRemoteSource(checkResults: [true], events: events);
    final evaluator = _FakeAutoEvaluator(events: events, report: report);
    final cache = _FakeScoreCache();

    await GxuScoreSession(
      remoteSource: remote,
      autoEvaluator: evaluator,
      cache: cache,
    ).autoEvaluateAndFetchScoreSheet(
      onEvaluationReport: (report) =>
          events.add('report:${report.submittedCourseCount}'),
    );

    expect(events, ['evaluate', 'report:0', 'check', 'prepare', 'preview']);
  });

  test(
    'explicit auto evaluation can refresh score when warm-up fails after unlock',
    () async {
      final events = <String>[];
      final remote = _FakeScoreRemoteSource(
        checkResults: [true],
        events: events,
        prepareError: const LoginFailedException(msg: '广西大学成绩模块初始化失败：0'),
      );
      final evaluator = _FakeAutoEvaluator(events: events);
      final cache = _FakeScoreCache();

      final result = await GxuScoreSession(
        remoteSource: remote,
        autoEvaluator: evaluator,
        cache: cache,
      ).autoEvaluateAndFetchScoreSheet();

      expect(events, ['evaluate', 'check', 'prepare', 'preview']);
      expect(result.sheet.profile.studentId, 'S001');
      expect(result.refreshNote, contains('成绩模块初始化失败'));
      expect(cache.dumpedSheet, same(result.sheet));
    },
  );

  test(
    'preserves evaluation report when score refresh fails after auto evaluation',
    () async {
      const report = GxuCourseEvaluationReport(
        submittedCourseCount: 1,
        skippedCourseCount: 0,
      );
      final remote = _FakeScoreRemoteSource(
        checkResults: [true],
        prepareError: const LoginFailedException(msg: '广西大学成绩模块初始化失败：0'),
        previewError: const LoginFailedException(msg: '成绩单预览接口返回异常'),
      );
      final evaluator = _FakeAutoEvaluator(report: report);
      final cache = _FakeScoreCache();

      await expectLater(
        () => GxuScoreSession(
          remoteSource: remote,
          autoEvaluator: evaluator,
          cache: cache,
        ).autoEvaluateAndFetchScoreSheet(),
        throwsA(
          isA<GxuScoreAutoEvaluationRefreshException>()
              .having((error) => error.report, 'report', same(report))
              .having(
                (error) => error.msg,
                'msg',
                contains('课程评价流程已完成，但成绩刷新失败'),
              ),
        ),
      );
      expect(evaluator.callCount, 1);
      expect(cache.dumpedSheet, isNull);
    },
  );

  test(
    'throws evaluation-required when explicit auto evaluation does not unlock',
    () async {
      final remote = _FakeScoreRemoteSource(checkResults: [false]);
      final evaluator = _FakeAutoEvaluator();
      final cache = _FakeScoreCache();

      await expectLater(
        () => GxuScoreSession(
          remoteSource: remote,
          autoEvaluator: evaluator,
          cache: cache,
        ).autoEvaluateAndGetScoreSheet(),
        throwsA(isA<GxuScoreEvaluationRequiredException>()),
      );
      expect(evaluator.callCount, 1);
      expect(remote.previewCount, 0);
    },
  );
}

class _FakeScoreRemoteSource implements GxuScoreRemoteSource {
  final List<bool> checkResults;
  final List<String>? events;
  final Object? prepareError;
  final Object? previewError;
  int prepareCount = 0;
  int checkCount = 0;
  int previewCount = 0;

  _FakeScoreRemoteSource({
    required this.checkResults,
    this.events,
    this.prepareError,
    this.previewError,
  });

  @override
  Future<void> prepareScoreModule() async {
    events?.add('prepare');
    prepareCount++;
    final error = prepareError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<bool> checkPrintableScoreSheet() async {
    events?.add('check');
    return checkResults[checkCount++];
  }

  @override
  Future<Map<String, dynamic>> fetchScorePreview() async {
    events?.add('preview');
    previewCount++;
    final error = previewError;
    if (error != null) {
      throw error;
    }
    return {
      'textMap': {'xh': 'S001'},
      'tableList': [],
    };
  }
}

class _FakeAutoEvaluator implements GxuAutoCourseEvaluator {
  final List<String>? events;
  final GxuCourseEvaluationReport report;
  int callCount = 0;

  _FakeAutoEvaluator({
    this.events,
    this.report = const GxuCourseEvaluationReport(
      submittedCourseCount: 1,
      skippedCourseCount: 0,
    ),
  });

  @override
  Future<GxuCourseEvaluationReport> autoEvaluateRequiredCourses() async {
    events?.add('evaluate');
    callCount++;
    return report;
  }
}

class _FakeScoreCache implements GxuScoreCache {
  GxuScoreSheet? dumpedSheet;

  @override
  GxuScoreSheet? load() => null;

  @override
  bool isFresh() => false;

  @override
  void dump(GxuScoreSheet sheet) {
    dumpedSheet = sheet;
  }
}
