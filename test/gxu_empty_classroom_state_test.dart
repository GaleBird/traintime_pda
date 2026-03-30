import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';
import 'package:watermeter/repository/gxu_ids/gxu_empty_classroom_session.dart';
import 'package:watermeter/repository/network_session.dart' as network_session;
import 'package:watermeter/repository/preference.dart' as preference;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempSupportDir;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    preference.prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    tempSupportDir = await Directory.systemTemp.createTemp(
      'gxu_empty_classroom_state_test',
    );
    network_session.supportPath = tempSupportDir;
  });

  tearDown(() async {
    if (tempSupportDir.existsSync()) {
      await tempSupportDir.delete(recursive: true);
    }
  });

  group('GxuEmptyClassroomState', () {
    test(
      'clears stale result and local search when query condition changes',
      () async {
        final state = GxuEmptyClassroomState(
          session: _FakeEmptyClassroomSession(
            form: _buildForm(),
            onSearch: (_) async => _buildResult(),
          ),
        );

        await state.initialize();
        await state.refreshResults();
        state.searchKeyword = 'A101';
        state.updateSelect('jxlh', ['二教']);

        expect(state.result, isNull);
        expect(state.resultState, network_session.SessionState.none);
        expect(state.filteredRows, isEmpty);
        expect(state.searchKeyword, isEmpty);
        expect(state.canRefresh, isFalse);
      },
    );

    test(
      'does not invalidate result for equivalent empty select values',
      () async {
        final state = GxuEmptyClassroomState(
          session: _FakeEmptyClassroomSession(
            form: _buildForm(),
            onSearch: (_) async => _buildResult(),
          ),
        );

        await state.initialize();
        await state.refreshResults();
        state.searchKeyword = 'A101';

        state.updateSelect('jxlh', []);

        expect(state.result, isNotNull);
        expect(state.resultState, network_session.SessionState.fetched);
        expect(state.searchKeyword, 'A101');
        expect(state.filteredRows, isNotEmpty);
        expect(state.canRefresh, isTrue);
      },
    );

    test(
      'does not invalidate result for reordered multi select values',
      () async {
        final state = GxuEmptyClassroomState(
          session: _FakeEmptyClassroomSession(
            form: _buildForm().updateSelect('jsxxid', [
              'room-a101',
              'room-b201',
            ]),
            onSearch: (_) async => _buildResult(),
          ),
        );

        await state.initialize();
        await state.refreshResults();
        state.searchKeyword = 'A101';

        state.updateSelect('jsxxid', ['room-b201', 'room-a101']);

        expect(state.result, isNotNull);
        expect(state.resultState, network_session.SessionState.fetched);
        expect(state.searchKeyword, 'A101');
        expect(state.filteredRows, isNotEmpty);
        expect(state.canRefresh, isTrue);
      },
    );

    test('ignores in-flight result after query condition changes', () async {
      final completer = Completer<GxuEmptyClassroomResult>();
      final state = GxuEmptyClassroomState(
        session: _FakeEmptyClassroomSession(
          form: _buildForm(),
          onSearch: (_) => completer.future,
        ),
      );

      await state.initialize();
      final pendingRefresh = state.refreshResults();
      expect(state.resultState, network_session.SessionState.fetching);

      state.updateSelect('jxlh', ['二教']);
      completer.complete(_buildResult());
      await pendingRefresh;

      expect(state.result, isNull);
      expect(state.resultState, network_session.SessionState.none);
      expect(state.filteredRows, isEmpty);
    });

    test('drops previous result when refresh fails', () async {
      var searchCount = 0;
      final state = GxuEmptyClassroomState(
        session: _FakeEmptyClassroomSession(
          form: _buildForm(),
          onSearch: (_) async {
            searchCount++;
            if (searchCount == 1) {
              return _buildResult();
            }
            throw StateError('refresh boom');
          },
        ),
      );

      await state.initialize();
      await state.refreshResults();
      expect(state.result, isNotNull);

      await state.refreshResults();

      expect(state.result, isNull);
      expect(state.filteredRows, isEmpty);
      expect(state.resultState, network_session.SessionState.error);
      expect(state.resultError, contains('refresh boom'));
      expect(state.canRefresh, isFalse);
    });

    test('rejects invalid seat range before querying', () async {
      var searched = false;
      final state = GxuEmptyClassroomState(
        session: _FakeEmptyClassroomSession(
          form: _buildForm().updateText('zws', '80').updateText('jszws', '60'),
          onSearch: (_) async {
            searched = true;
            return _buildResult();
          },
        ),
      );

      await state.initialize();
      await state.refreshResults();

      expect(searched, isFalse);
      expect(state.result, isNull);
      expect(state.resultState, network_session.SessionState.error);
      expect(state.resultError, contains('座位数范围'));
    });

    test(
      'recovers from corrupted query preference during initialize',
      () async {
        await preference.setString(
          preference.Preference.gxuEmptyClassroomQuery,
          '{"viewType":',
        );
        final state = GxuEmptyClassroomState(
          session: _FakeEmptyClassroomSession(
            form: _buildForm(),
            onSearch: (_) async => _buildResult(),
          ),
        );

        await state.initialize();

        expect(state.pageState, network_session.SessionState.fetched);
        expect(state.pageError, isNull);
        expect(state.form, isNotNull);
        expect(state.resultState, network_session.SessionState.none);
      },
    );
  });
}

class _FakeEmptyClassroomSession extends GxuEmptyClassroomSession {
  final GxuEmptyClassroomQueryForm form;
  final Future<GxuEmptyClassroomResult> Function(
    GxuEmptyClassroomQueryForm form,
  )
  onSearch;

  _FakeEmptyClassroomSession({required this.form, required this.onSearch});

  @override
  Future<GxuEmptyClassroomQueryForm> loadQueryForm() async => form;

  @override
  Future<GxuEmptyClassroomResult> search(GxuEmptyClassroomQueryForm form) {
    return onSearch(form);
  }
}

GxuEmptyClassroomQueryForm _buildForm() {
  const catalog = [
    GxuEmptyClassroomCatalogRoom(
      id: 'room-a101',
      name: 'A101',
      building: '一教',
      campusCode: '1',
      campusName: '主校区',
      availableSeats: '60',
      examSeats: '30',
      statusCode: '1',
      statusLabel: '可以使用',
    ),
    GxuEmptyClassroomCatalogRoom(
      id: 'room-b201',
      name: 'B201',
      building: '二教',
      campusCode: '1',
      campusName: '主校区',
      availableSeats: '80',
      examSeats: '40',
      statusCode: '1',
      statusLabel: '可以使用',
    ),
  ];

  return GxuEmptyClassroomQueryForm(
    viewType: GxuEmptyClassroomViewType.period,
    selectFields: const [
      GxuEmptyClassroomSelectField(
        name: 'xqdm',
        label: '学期',
        options: [
          GxuEmptyClassroomOption(value: '2025-2026-2', label: '2026年春季'),
        ],
        selectedValues: ['2025-2026-2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'kszc',
        label: '开始周次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1周'),
          GxuEmptyClassroomOption(value: '2', label: '第2周'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jszc',
        label: '结束周次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1周'),
          GxuEmptyClassroomOption(value: '2', label: '第2周'),
        ],
        selectedValues: ['2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'ksxq',
        label: '开始星期',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '星期一'),
          GxuEmptyClassroomOption(value: '2', label: '星期二'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsxq',
        label: '结束星期',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '星期一'),
          GxuEmptyClassroomOption(value: '2', label: '星期二'),
        ],
        selectedValues: ['2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'ksjc',
        label: '开始节次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1节'),
          GxuEmptyClassroomOption(value: '2', label: '第2节'),
        ],
        selectedValues: ['1'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsjc',
        label: '结束节次',
        options: [
          GxuEmptyClassroomOption(value: '1', label: '第1节'),
          GxuEmptyClassroomOption(value: '2', label: '第2节'),
        ],
        selectedValues: ['2'],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jxlh',
        label: '教学楼',
        options: [],
        selectedValues: [''],
      ),
      GxuEmptyClassroomSelectField(
        name: 'jsxxid',
        label: '教室',
        options: [],
        selectedValues: [],
        isMulti: true,
      ),
      GxuEmptyClassroomSelectField(
        name: 'zyqk',
        label: '占用情况',
        options: [
          GxuEmptyClassroomOption(value: '', label: '请选择'),
          GxuEmptyClassroomOption(value: '00', label: '借用'),
        ],
        selectedValues: [''],
        isMulti: true,
      ),
      GxuEmptyClassroomSelectField(
        name: 'zylx',
        label: '占用类型',
        options: [
          GxuEmptyClassroomOption(value: '', label: '请选择'),
          GxuEmptyClassroomOption(value: '1', label: '研究生占用'),
        ],
        selectedValues: [''],
      ),
    ],
    textFields: const [
      GxuEmptyClassroomTextField(name: 'zws', label: '最少座位数', value: ''),
      GxuEmptyClassroomTextField(name: 'jszws', label: '最多座位数', value: ''),
    ],
    classroomCatalog: catalog,
  ).copyWith();
}

GxuEmptyClassroomResult _buildResult() {
  return GxuEmptyClassroomResult(
    rooms: const [
      GxuEmptyClassroomRemoteRoom(
        roomId: 'room-a101',
        roomName: 'A101',
        statusCode: '1',
        availableSeats: '60',
        examSeats: '30',
        undergraduateUnavailable: false,
        schedule: {'jc2': '排课 1'},
        exam: {},
        borrow: {},
        adjust: {},
        other: {},
      ),
      GxuEmptyClassroomRemoteRoom(
        roomId: 'room-b201',
        roomName: 'B201',
        statusCode: '1',
        availableSeats: '80',
        examSeats: '40',
        undergraduateUnavailable: false,
        schedule: {},
        exam: {},
        borrow: {},
        adjust: {},
        other: {},
      ),
    ],
    fetchedAt: DateTime(2026, 3, 27, 18, 30),
  );
}
