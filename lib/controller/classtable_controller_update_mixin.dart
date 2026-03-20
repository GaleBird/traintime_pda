part of 'classtable_controller.dart';

class _ClassTableCacheSnapshot {
  final bool fileExists;
  final bool cacheModeMatched;
  final bool notNeedRefresh;
  final bool isEmptyCache;

  const _ClassTableCacheSnapshot({
    required this.fileExists,
    required this.cacheModeMatched,
    required this.notNeedRefresh,
    required this.isEmptyCache,
  });
}

extension ClassTableControllerUpdate on ClassTableController {
  bool _isCacheModeMatched() {
    final cacheMode = preference.getString(
      preference.Preference.classTableCacheMode,
    );
    return cacheMode == _currentCacheMode;
  }

  void _loadCachedClassTable() {
    classTableData = ClassTableData.fromJson(
      jsonDecode(classTableFile.readAsStringSync()),
    );
    _attachUserDefined(classTableData);
  }

  Future<void> _saveRemoteClassTable(ClassTableData data) async {
    classTableFile.writeAsStringSync(jsonEncode(data.toJson()));
    await preference.setString(
      preference.Preference.classTableCacheMode,
      _currentCacheMode,
    );
  }

  void _attachUserDefined(ClassTableData data) {
    data.userDefinedDetail = userDefinedClassData.userDefinedDetail;
    data.timeArrangement.addAll(userDefinedClassData.timeArrangement);
  }

  bool _isCurrentCacheEmpty() {
    return classTableData.classDetail.isEmpty ||
        classTableData.timeArrangement.isEmpty;
  }

  _ClassTableCacheSnapshot _prepareCache({required bool isForce}) {
    final fileExists = classTableFile.existsSync();
    final cacheModeMatched = fileExists && _isCacheModeMatched();
    final notNeedRefresh =
        cacheModeMatched &&
        !isForce &&
        DateTime.now().difference(classTableFile.lastModifiedSync()).inDays <=
            2;

    var emptyCache = false;
    if (cacheModeMatched) {
      _loadCachedClassTable();
      emptyCache = _isCurrentCacheEmpty();
    }

    log.info(
      "[ClassTableController][updateClassTable]"
      "Cache file exist: $fileExists.\n"
      "Is cache mode matched: $cacheModeMatched\n"
      "Is not need refresh cache: $notNeedRefresh\n"
      "Is cache empty: $emptyCache",
    );

    return _ClassTableCacheSnapshot(
      fileExists: fileExists,
      cacheModeMatched: cacheModeMatched,
      notNeedRefresh: notNeedRefresh,
      isEmptyCache: emptyCache,
    );
  }

  bool _shouldFetchRemote({
    required _ClassTableCacheSnapshot cache,
    required bool isUserDefinedChanged,
  }) {
    if (!cache.cacheModeMatched) return true;
    if (cache.isEmptyCache) return true;
    if (isUserDefinedChanged) return false;
    return !cache.notNeedRefresh;
  }

  Future<void> _refreshFromRemote({required bool canFallbackToCache}) async {
    try {
      final remote = await GxuClasstableSession().getClassTable();
      await _saveRemoteClassTable(remote);
      _attachUserDefined(remote);
      classTableData = remote;
    } catch (e, s) {
      log.handle(e, s);
      if (canFallbackToCache) {
        error = e.toString();
        _loadCachedClassTable();
        return;
      }
      rethrow;
    }
  }

  Future<void> _syncToIosWidgetsIfNeeded() async {
    if (!Platform.isIOS) return;
    await syncClasstableToIosWidgets(
      classTableData: classTableData,
      appId: preference.appId,
      weekSwift: preference.getInt(preference.Preference.swift),
    );
  }

  void _beginUpdate() {
    state = ClassTableState.fetching;
    error = null;
    update();
  }

  void _completeUpdate() {
    state = ClassTableState.fetched;
    update();
  }

  void _failUpdate(Object errorValue, StackTrace stackTrace) {
    log.warning(errorValue, stackTrace);
    state = ClassTableState.error;
    error = errorValue.toString();
    update();
  }

  Future<void> updateClassTable({
    bool isForce = false,
    bool isUserDefinedChanged = false,
  }) async {
    _beginUpdate();
    try {
      log.info(
        "[ClassTableController][updateClassTable] "
        "Start fetching the classtable.",
      );

      refreshUserDefinedClass();
      final cache = _prepareCache(isForce: isForce);
      final shouldFetch = _shouldFetchRemote(
        cache: cache,
        isUserDefinedChanged: isUserDefinedChanged,
      );

      if (shouldFetch) {
        await _refreshFromRemote(canFallbackToCache: cache.cacheModeMatched);
      }

      await _syncToIosWidgetsIfNeeded();
      _completeUpdate();
    } catch (e, s) {
      _failUpdate(e, s);
    }
  }
}
