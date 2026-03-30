import 'dart:convert';

enum GxuEmptyClassroomViewType { week, weekday, period }

extension GxuEmptyClassroomViewTypeX on GxuEmptyClassroomViewType {
  String get preferenceValue {
    switch (this) {
      case GxuEmptyClassroomViewType.week:
        return "week";
      case GxuEmptyClassroomViewType.weekday:
        return "weekday";
      case GxuEmptyClassroomViewType.period:
        return "period";
    }
  }

  int get remoteType {
    switch (this) {
      case GxuEmptyClassroomViewType.week:
        return 1;
      case GxuEmptyClassroomViewType.weekday:
        return 2;
      case GxuEmptyClassroomViewType.period:
        return 3;
    }
  }

  String get translationKey {
    switch (this) {
      case GxuEmptyClassroomViewType.week:
        return "empty_classroom.view_week";
      case GxuEmptyClassroomViewType.weekday:
        return "empty_classroom.view_weekday";
      case GxuEmptyClassroomViewType.period:
        return "empty_classroom.view_period";
    }
  }

  String keyOf(int number) {
    switch (this) {
      case GxuEmptyClassroomViewType.week:
        return "zc$number";
      case GxuEmptyClassroomViewType.weekday:
        return "xq$number";
      case GxuEmptyClassroomViewType.period:
        return "jc$number";
    }
  }

  String headerOf(int number) {
    switch (this) {
      case GxuEmptyClassroomViewType.week:
        return "第$number周";
      case GxuEmptyClassroomViewType.weekday:
        return _weekdayLabelOf(number);
      case GxuEmptyClassroomViewType.period:
        return "第$number节";
    }
  }
}

GxuEmptyClassroomViewType gxuEmptyClassroomViewTypeFromPreference(
  String? value,
) {
  switch (value?.trim()) {
    case "week":
      return GxuEmptyClassroomViewType.week;
    case "weekday":
      return GxuEmptyClassroomViewType.weekday;
    case "period":
    default:
      return GxuEmptyClassroomViewType.period;
  }
}

enum GxuEmptyClassroomCellState { available, occupied, unavailable, unknown }

final Expando<Map<GxuEmptyClassroomViewType, _GxuEmptyClassroomOccupancyIndex>>
_gxuEmptyClassroomOccupancyIndexCache =
    Expando<Map<GxuEmptyClassroomViewType, _GxuEmptyClassroomOccupancyIndex>>(
      'gxuEmptyClassroomOccupancyIndexCache',
    );

class GxuEmptyClassroomOption {
  final String value;
  final String label;

  const GxuEmptyClassroomOption({required this.value, required this.label});
}

class GxuEmptyClassroomSelectField {
  final String name;
  final String label;
  final List<GxuEmptyClassroomOption> options;
  final List<String> selectedValues;
  final bool isMulti;

  const GxuEmptyClassroomSelectField({
    required this.name,
    required this.label,
    required this.options,
    required this.selectedValues,
    this.isMulti = false,
  });

  String get selectedValue {
    if (selectedValues.isEmpty) {
      return "";
    }
    return selectedValues.first;
  }

  List<String> get selectedLabels {
    if (selectedValues.isEmpty || options.isEmpty) {
      return const [];
    }
    final selected = selectedValues.toSet();
    final labels = <String>[];
    for (final option in options) {
      if (selected.contains(option.value)) {
        labels.add(option.label);
      }
    }
    return labels;
  }

  String get displayText {
    if (selectedValues.isEmpty) {
      return "请选择";
    }
    final labels = selectedLabels;
    if (labels.isEmpty) {
      return "请选择";
    }
    return labels.join("、");
  }

  bool containsOption(String value) {
    return options.any((option) => option.value == value);
  }

  GxuEmptyClassroomSelectField copyWith({
    List<GxuEmptyClassroomOption>? options,
    List<String>? selectedValues,
  }) {
    return GxuEmptyClassroomSelectField(
      name: name,
      label: label,
      options: options ?? this.options,
      selectedValues: selectedValues ?? this.selectedValues,
      isMulti: isMulti,
    );
  }
}

class GxuEmptyClassroomTextField {
  final String name;
  final String label;
  final String value;
  final bool isNumeric;

  const GxuEmptyClassroomTextField({
    required this.name,
    required this.label,
    required this.value,
    this.isNumeric = false,
  });

  GxuEmptyClassroomTextField copyWith({String? value}) {
    return GxuEmptyClassroomTextField(
      name: name,
      label: label,
      value: value ?? this.value,
      isNumeric: isNumeric,
    );
  }
}

class GxuEmptyClassroomCatalogRoom {
  final String id;
  final String name;
  final String building;
  final String campusCode;
  final String campusName;
  final String availableSeats;
  final String examSeats;
  final String statusCode;
  final String statusLabel;

  const GxuEmptyClassroomCatalogRoom({
    required this.id,
    required this.name,
    required this.building,
    required this.campusCode,
    required this.campusName,
    required this.availableSeats,
    required this.examSeats,
    required this.statusCode,
    required this.statusLabel,
  });

  factory GxuEmptyClassroomCatalogRoom.fromJson(Map<String, dynamic> json) {
    return GxuEmptyClassroomCatalogRoom(
      id: _stringOf(json["jsxxid"]),
      name: _stringOf(json["jsmc"]),
      building: _stringOf(json["jxlh"]),
      campusCode: _stringOf(json["xxxqdm"]),
      campusName: _stringOf(json["xxxqmc"]),
      availableSeats: _seatTextOf(json["yxzws"]),
      examSeats: _seatTextOf(json["kszws"]),
      statusCode: _stringOf(json["jsztdm"]),
      statusLabel: _stringOf(json["jsztmc"]),
    );
  }

  String optionLabel({required bool includeBuilding}) {
    if (!includeBuilding || building.isEmpty) {
      return name;
    }
    return "$name · $building";
  }

  String get seatSummary {
    final fragments = <String>[];
    if (availableSeats.isNotEmpty) {
      fragments.add("可用座位 $availableSeats");
    }
    if (examSeats.isNotEmpty) {
      fragments.add("考试座位 $examSeats");
    }
    return fragments.join(" · ");
  }
}

class GxuEmptyClassroomQueryForm {
  static const _buildingFieldName = "jxlh";
  static const _classroomFieldName = "jsxxid";

  final GxuEmptyClassroomViewType viewType;
  final List<GxuEmptyClassroomSelectField> selectFields;
  final List<GxuEmptyClassroomTextField> textFields;
  final List<GxuEmptyClassroomCatalogRoom> classroomCatalog;

  const GxuEmptyClassroomQueryForm({
    required this.viewType,
    required this.selectFields,
    required this.textFields,
    required this.classroomCatalog,
  });

  GxuEmptyClassroomQueryForm copyWith({
    GxuEmptyClassroomViewType? viewType,
    List<GxuEmptyClassroomSelectField>? selectFields,
    List<GxuEmptyClassroomTextField>? textFields,
    List<GxuEmptyClassroomCatalogRoom>? classroomCatalog,
  }) {
    return GxuEmptyClassroomQueryForm(
      viewType: viewType ?? this.viewType,
      selectFields: selectFields ?? this.selectFields,
      textFields: textFields ?? this.textFields,
      classroomCatalog: classroomCatalog ?? this.classroomCatalog,
    )._synchronizeDependentFields();
  }

  GxuEmptyClassroomQueryForm withClassroomCatalog(
    List<GxuEmptyClassroomCatalogRoom> rooms,
  ) {
    return copyWith(classroomCatalog: rooms);
  }

  GxuEmptyClassroomQueryForm updateViewType(GxuEmptyClassroomViewType value) {
    return copyWith(viewType: value);
  }

  GxuEmptyClassroomQueryForm updateSelect(String name, List<String> values) {
    final normalizedValues = values.where((item) => item.trim().isNotEmpty);
    return copyWith(
      selectFields: [
        for (final field in selectFields)
          if (field.name == name)
            field.copyWith(selectedValues: normalizedValues.toList())
          else
            field,
      ],
    );
  }

  GxuEmptyClassroomQueryForm updateText(String name, String value) {
    return copyWith(
      textFields: [
        for (final field in textFields)
          if (field.name == name) field.copyWith(value: value) else field,
      ],
    );
  }

  GxuEmptyClassroomSelectField? selectField(String name) {
    for (final field in selectFields) {
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }

  GxuEmptyClassroomTextField? textField(String name) {
    for (final field in textFields) {
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }

  Map<String, String> toPayload() {
    return {
      "type": viewType.remoteType.toString(),
      for (final field in selectFields)
        field.name: field.isMulti
            ? field.selectedValues.join(",")
            : field.selectedValue,
      for (final field in textFields) field.name: field.value.trim(),
    };
  }

  Map<String, dynamic> toPreferenceJson() {
    return {
      "viewType": viewType.preferenceValue,
      "selects": {
        for (final field in selectFields) field.name: field.selectedValues,
      },
      "texts": {for (final field in textFields) field.name: field.value},
    };
  }

  GxuEmptyClassroomQueryForm restoreFromPreference(String rawPreference) {
    if (rawPreference.trim().isEmpty) {
      return _synchronizeDependentFields();
    }
    final decoded = jsonDecode(rawPreference);
    if (decoded is! Map) {
      return _synchronizeDependentFields();
    }
    final selectMap = _stringListMapOf(decoded["selects"]);
    final textMap = _stringMapOf(decoded["texts"]);
    return GxuEmptyClassroomQueryForm(
      viewType: gxuEmptyClassroomViewTypeFromPreference(
        decoded["viewType"]?.toString(),
      ),
      selectFields: [
        for (final field in selectFields)
          field.copyWith(
            selectedValues: _filterValidValues(
              field.options,
              selectMap[field.name] ?? field.selectedValues,
            ),
          ),
      ],
      textFields: [
        for (final field in textFields)
          field.copyWith(value: textMap[field.name] ?? field.value),
      ],
      classroomCatalog: classroomCatalog,
    )._synchronizeDependentFields();
  }

  GxuEmptyClassroomQueryForm _synchronizeDependentFields() {
    if (classroomCatalog.isEmpty) {
      return this;
    }
    final buildingOptions = _buildBuildingOptions();
    final selectedBuilding = _validatedSelectedValue(
      selectField(_buildingFieldName),
      buildingOptions,
    );
    final classroomOptions = _buildClassroomOptions(selectedBuilding);
    final selectedClassrooms = _validatedSelectedValues(
      selectField(_classroomFieldName),
      classroomOptions,
    );
    return GxuEmptyClassroomQueryForm(
      viewType: viewType,
      selectFields: [
        for (final field in selectFields)
          if (field.name == _buildingFieldName)
            field.copyWith(
              options: buildingOptions,
              selectedValues: [selectedBuilding],
            )
          else if (field.name == _classroomFieldName)
            field.copyWith(
              options: classroomOptions,
              selectedValues: selectedClassrooms,
            )
          else
            field,
      ],
      textFields: textFields,
      classroomCatalog: classroomCatalog,
    );
  }

  List<GxuEmptyClassroomOption> _buildBuildingOptions() {
    final labels = <String>{};
    for (final room in classroomCatalog) {
      final label = room.building.trim();
      if (label.isNotEmpty) {
        labels.add(label);
      }
    }
    final sorted = labels.toList()..sort();
    return [
      const GxuEmptyClassroomOption(value: "", label: "请选择"),
      for (final label in sorted)
        GxuEmptyClassroomOption(value: label, label: label),
    ];
  }

  List<GxuEmptyClassroomOption> _buildClassroomOptions(String building) {
    final includeBuilding = building.isEmpty;
    final options = <GxuEmptyClassroomOption>[
      const GxuEmptyClassroomOption(value: "", label: "请选择"),
    ];
    final rooms = <GxuEmptyClassroomCatalogRoom>[
      for (final room in classroomCatalog)
        if (building.isEmpty || room.building == building) room,
    ]..sort((left, right) => left.name.compareTo(right.name));
    for (final room in rooms) {
      options.add(
        GxuEmptyClassroomOption(
          value: room.id,
          label: room.optionLabel(includeBuilding: includeBuilding),
        ),
      );
    }
    return options;
  }
}

class GxuEmptyClassroomCell {
  final String header;
  final String value;
  final String roomId;
  final int slotNumber;
  final GxuEmptyClassroomViewType viewType;
  final GxuEmptyClassroomCellState state;
  final String? localDetailMessage;

  const GxuEmptyClassroomCell({
    required this.header,
    required this.value,
    required this.roomId,
    required this.slotNumber,
    required this.viewType,
    required this.state,
    required this.localDetailMessage,
  });

  bool get isAvailable => state == GxuEmptyClassroomCellState.available;

  bool get hasDetail =>
      state == GxuEmptyClassroomCellState.occupied ||
      state == GxuEmptyClassroomCellState.unavailable;

  bool get requiresRemoteDetail =>
      state == GxuEmptyClassroomCellState.occupied &&
      localDetailMessage == null;

  String get shortLabel {
    switch (state) {
      case GxuEmptyClassroomCellState.available:
        return "空闲";
      case GxuEmptyClassroomCellState.unavailable:
        return "不可用";
      case GxuEmptyClassroomCellState.unknown:
        return "--";
      case GxuEmptyClassroomCellState.occupied:
        return _shortOccupiedLabel(value);
    }
  }
}

class GxuEmptyClassroomRow {
  final String title;
  final String subtitle;
  final int totalCount;
  final int availableCount;
  final int occupiedCount;
  final String _searchText;
  final GxuEmptyClassroomRemoteRoom _room;
  final List<int> _range;
  final GxuEmptyClassroomViewType _viewType;
  List<GxuEmptyClassroomCell>? _cells;

  GxuEmptyClassroomRow({
    required this.title,
    required this.subtitle,
    required this.totalCount,
    required this.availableCount,
    required this.occupiedCount,
    required GxuEmptyClassroomRemoteRoom room,
    required List<int> range,
    required GxuEmptyClassroomViewType viewType,
    String extraSearchText = "",
  }) : _searchText = _normalizeText(
         "$title $subtitle $extraSearchText",
       ).toLowerCase(),
       _room = room,
       _range = range,
       _viewType = viewType;

  List<GxuEmptyClassroomCell> get cells {
    final cached = _cells;
    if (cached != null) {
      return cached;
    }
    final built = [
      for (final slot in _range)
        _room.buildCell(slotNumber: slot, viewType: _viewType),
    ];
    _cells = built;
    return built;
  }

  bool matchesKeyword(String keyword) {
    final normalized = _normalizeText(keyword).toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return _searchText.contains(normalized);
  }

  // Cells are built lazily for visible rows only; local search only uses
  // title/subtitle to avoid constructing thousands of status chips.
}

class _GxuEmptyClassroomRangeSummary {
  final int occupiedCount;
  final bool hasSchedule;
  final bool hasExam;
  final bool hasBorrow;
  final bool hasAdjust;
  final bool hasOther;

  const _GxuEmptyClassroomRangeSummary({
    this.occupiedCount = 0,
    this.hasSchedule = false,
    this.hasExam = false,
    this.hasBorrow = false,
    this.hasAdjust = false,
    this.hasOther = false,
  });

  String get extraSearchText {
    return [
      if (hasSchedule) "排课",
      if (hasExam) "考试",
      if (hasBorrow) "借用",
      if (hasAdjust) "调课",
      if (hasOther) "其它",
    ].join(" ");
  }
}

class _GxuEmptyClassroomOccupancyIndex {
  final List<int> occupiedPrefix;
  final List<int> schedulePrefix;
  final List<int> examPrefix;
  final List<int> borrowPrefix;
  final List<int> adjustPrefix;
  final List<int> otherPrefix;

  const _GxuEmptyClassroomOccupancyIndex({
    required this.occupiedPrefix,
    required this.schedulePrefix,
    required this.examPrefix,
    required this.borrowPrefix,
    required this.adjustPrefix,
    required this.otherPrefix,
  });

  int get maxSlot => occupiedPrefix.length - 1;

  factory _GxuEmptyClassroomOccupancyIndex.fromRoom({
    required GxuEmptyClassroomRemoteRoom room,
    required GxuEmptyClassroomViewType viewType,
    required int maxSlot,
  }) {
    final maxNumber = maxSlot < 1 ? 1 : maxSlot;
    final occupiedPrefix = List<int>.filled(maxNumber + 1, 0);
    final schedulePrefix = List<int>.filled(maxNumber + 1, 0);
    final examPrefix = List<int>.filled(maxNumber + 1, 0);
    final borrowPrefix = List<int>.filled(maxNumber + 1, 0);
    final adjustPrefix = List<int>.filled(maxNumber + 1, 0);
    final otherPrefix = List<int>.filled(maxNumber + 1, 0);
    for (var slot = 1; slot <= maxNumber; slot++) {
      final key = viewType.keyOf(slot);
      final scheduleOccupied = _isOccupiedValue(room.schedule[key]);
      final examOccupied = _isOccupiedValue(room.exam[key]);
      final borrowOccupied = _isOccupiedValue(room.borrow[key]);
      final adjustOccupied = _isOccupiedValue(room.adjust[key]);
      final otherOccupied = _isOccupiedValue(room.other[key]);
      occupiedPrefix[slot] =
          occupiedPrefix[slot - 1] +
          _toInt(
            scheduleOccupied ||
                examOccupied ||
                borrowOccupied ||
                adjustOccupied ||
                otherOccupied,
          );
      schedulePrefix[slot] =
          schedulePrefix[slot - 1] + _toInt(scheduleOccupied);
      examPrefix[slot] = examPrefix[slot - 1] + _toInt(examOccupied);
      borrowPrefix[slot] = borrowPrefix[slot - 1] + _toInt(borrowOccupied);
      adjustPrefix[slot] = adjustPrefix[slot - 1] + _toInt(adjustOccupied);
      otherPrefix[slot] = otherPrefix[slot - 1] + _toInt(otherOccupied);
    }
    return _GxuEmptyClassroomOccupancyIndex(
      occupiedPrefix: occupiedPrefix,
      schedulePrefix: schedulePrefix,
      examPrefix: examPrefix,
      borrowPrefix: borrowPrefix,
      adjustPrefix: adjustPrefix,
      otherPrefix: otherPrefix,
    );
  }

  _GxuEmptyClassroomRangeSummary summarizeRange(List<int> range) {
    if (range.isEmpty) {
      return const _GxuEmptyClassroomRangeSummary();
    }
    final start = range.first;
    final end = range.last;
    return _GxuEmptyClassroomRangeSummary(
      occupiedCount: _countInRange(occupiedPrefix, start, end),
      hasSchedule: _countInRange(schedulePrefix, start, end) > 0,
      hasExam: _countInRange(examPrefix, start, end) > 0,
      hasBorrow: _countInRange(borrowPrefix, start, end) > 0,
      hasAdjust: _countInRange(adjustPrefix, start, end) > 0,
      hasOther: _countInRange(otherPrefix, start, end) > 0,
    );
  }

  static int _toInt(bool value) {
    return value ? 1 : 0;
  }

  static int _countInRange(List<int> prefix, int start, int end) {
    if (prefix.isEmpty || start < 1 || end < start || end >= prefix.length) {
      return 0;
    }
    return prefix[end] - prefix[start - 1];
  }

  static bool _isOccupiedValue(String? rawValue) {
    final value = rawValue?.trim() ?? "";
    if (value.isEmpty || value == "0" || value == "0.0") {
      return false;
    }
    return true;
  }
}

class GxuEmptyClassroomRemoteRoom {
  final String roomId;
  final String roomName;
  final String statusCode;
  final String availableSeats;
  final String examSeats;
  final bool undergraduateUnavailable;
  final Map<String, String> schedule;
  final Map<String, String> exam;
  final Map<String, String> borrow;
  final Map<String, String> adjust;
  final Map<String, String> other;

  const GxuEmptyClassroomRemoteRoom({
    required this.roomId,
    required this.roomName,
    required this.statusCode,
    required this.availableSeats,
    required this.examSeats,
    required this.undergraduateUnavailable,
    required this.schedule,
    required this.exam,
    required this.borrow,
    required this.adjust,
    required this.other,
  });

  factory GxuEmptyClassroomRemoteRoom.fromJson(Map<String, dynamic> json) {
    return GxuEmptyClassroomRemoteRoom(
      roomId: _stringOf(json["jsxxid"]),
      roomName: _stringOf(json["jsmc"]),
      statusCode: _stringOf(json["jsztdm"]),
      availableSeats: _seatTextOf(json["yxzws"]),
      examSeats: _seatTextOf(json["kszws"]),
      undergraduateUnavailable: _boolOf(json["bkszbky"]),
      schedule: _stringMapOf(json["jk"]),
      exam: _stringMapOf(json["ks"]),
      borrow: _stringMapOf(json["jy"]),
      adjust: _stringMapOf(json["tk"]),
      other: _stringMapOf(json["qt"]),
    );
  }

  GxuEmptyClassroomCell buildCell({
    required int slotNumber,
    required GxuEmptyClassroomViewType viewType,
  }) {
    final key = viewType.keyOf(slotNumber);
    final unavailableMessage = _localUnavailableMessage();
    if (unavailableMessage != null) {
      return GxuEmptyClassroomCell(
        header: viewType.headerOf(slotNumber),
        value: unavailableMessage,
        roomId: roomId,
        slotNumber: slotNumber,
        viewType: viewType,
        state: GxuEmptyClassroomCellState.unavailable,
        localDetailMessage: unavailableMessage,
      );
    }
    final fragments = _buildOccupationFragments(key);
    if (fragments.isNotEmpty) {
      return GxuEmptyClassroomCell(
        header: viewType.headerOf(slotNumber),
        value: fragments.join("\n"),
        roomId: roomId,
        slotNumber: slotNumber,
        viewType: viewType,
        state: GxuEmptyClassroomCellState.occupied,
        localDetailMessage: null,
      );
    }
    return GxuEmptyClassroomCell(
      header: viewType.headerOf(slotNumber),
      value: "空闲",
      roomId: roomId,
      slotNumber: slotNumber,
      viewType: viewType,
      state: GxuEmptyClassroomCellState.available,
      localDetailMessage: null,
    );
  }

  List<String> _buildOccupationFragments(String key) {
    final fragments = <String>[];
    _addFragment(fragments, "排课", schedule[key]);
    _addFragment(fragments, "考试", exam[key]);
    _addFragment(fragments, "借用", borrow[key]);
    _addFragment(fragments, "调课", adjust[key]);
    _addFragment(fragments, "其它", other[key]);
    return fragments;
  }

  String? _localUnavailableMessage() {
    if (statusCode.isNotEmpty && statusCode != "1") {
      return "研究生不可用";
    }
    if (undergraduateUnavailable) {
      return "本科设置为不可用教室";
    }
    return null;
  }

  void _addFragment(List<String> target, String label, String? rawValue) {
    final value = rawValue?.trim() ?? "";
    if (value.isEmpty || value == "0" || value == "0.0") {
      return;
    }
    target.add("$label $value");
  }

  _GxuEmptyClassroomRangeSummary _summarizeRange({
    required List<int> range,
    required GxuEmptyClassroomViewType viewType,
  }) {
    if (range.isEmpty) {
      return const _GxuEmptyClassroomRangeSummary();
    }
    return _occupancyIndexOf(
      viewType,
      requiredMaxSlot: range.last,
    ).summarizeRange(range);
  }

  _GxuEmptyClassroomOccupancyIndex _occupancyIndexOf(
    GxuEmptyClassroomViewType viewType, {
    required int requiredMaxSlot,
  }) {
    final cache = _gxuEmptyClassroomOccupancyIndexCache[this];
    final cachedIndex = cache?[viewType];
    if (cachedIndex != null && cachedIndex.maxSlot >= requiredMaxSlot) {
      return cachedIndex;
    }
    final built = _GxuEmptyClassroomOccupancyIndex.fromRoom(
      room: this,
      viewType: viewType,
      maxSlot: requiredMaxSlot,
    );
    final nextCache =
        cache ??
        <GxuEmptyClassroomViewType, _GxuEmptyClassroomOccupancyIndex>{};
    nextCache[viewType] = built;
    _gxuEmptyClassroomOccupancyIndexCache[this] = nextCache;
    return built;
  }
}

class GxuEmptyClassroomResult {
  final List<GxuEmptyClassroomRemoteRoom> rooms;
  final DateTime fetchedAt;

  const GxuEmptyClassroomResult({required this.rooms, required this.fetchedAt});

  List<GxuEmptyClassroomRow> buildRows({
    required GxuEmptyClassroomQueryForm form,
  }) {
    final range = _rangeOf(form);
    final catalogById = <String, GxuEmptyClassroomCatalogRoom>{
      for (final room in form.classroomCatalog) room.id: room,
    };
    final rows = [
      for (final room in rooms)
        _buildRow(room, range, form.viewType, catalogById),
    ];
    rows.sort(_compareRows);
    return rows;
  }

  int get availableSlotCount {
    return rooms.fold(0, (sum, room) => sum + _availableSlotsOf(room));
  }

  GxuEmptyClassroomRow _buildRow(
    GxuEmptyClassroomRemoteRoom room,
    List<int> range,
    GxuEmptyClassroomViewType viewType,
    Map<String, GxuEmptyClassroomCatalogRoom> catalogById,
  ) {
    final catalog = catalogById[room.roomId];
    final subtitle = _subtitleOf(room, catalog);
    final totalCount = range.length;
    final unavailable = _isRoomUnavailable(room);
    final summary = unavailable
        ? const _GxuEmptyClassroomRangeSummary()
        : room._summarizeRange(range: range, viewType: viewType);
    return GxuEmptyClassroomRow(
      title: room.roomName,
      subtitle: subtitle,
      totalCount: totalCount,
      availableCount: unavailable ? 0 : (totalCount - summary.occupiedCount),
      occupiedCount: unavailable ? 0 : summary.occupiedCount,
      room: room,
      range: range,
      viewType: viewType,
      extraSearchText: summary.extraSearchText,
    );
  }

  String _subtitleOf(
    GxuEmptyClassroomRemoteRoom room,
    GxuEmptyClassroomCatalogRoom? catalog,
  ) {
    final fragments = <String>[];
    final building = catalog?.building.trim() ?? "";
    if (building.isNotEmpty) {
      fragments.add(building);
    }
    final seatSummary = _seatSummaryOf(room, catalog);
    if (seatSummary.isNotEmpty) {
      fragments.add(seatSummary);
    }
    if (room.statusCode.isNotEmpty && room.statusCode != "1") {
      fragments.add("研究生不可用");
    }
    return fragments.join(" · ");
  }

  String _seatSummaryOf(
    GxuEmptyClassroomRemoteRoom room,
    GxuEmptyClassroomCatalogRoom? catalog,
  ) {
    final availableSeats = room.availableSeats.isNotEmpty
        ? room.availableSeats
        : (catalog?.availableSeats ?? "");
    final examSeats = room.examSeats.isNotEmpty
        ? room.examSeats
        : (catalog?.examSeats ?? "");
    final fragments = <String>[];
    if (availableSeats.isNotEmpty) {
      fragments.add("可用座位 $availableSeats");
    }
    if (examSeats.isNotEmpty) {
      fragments.add("考试座位 $examSeats");
    }
    return fragments.join(" · ");
  }

  List<int> _rangeOf(GxuEmptyClassroomQueryForm form) {
    switch (form.viewType) {
      case GxuEmptyClassroomViewType.week:
        return _intRangeOf(form, "kszc", "jszc");
      case GxuEmptyClassroomViewType.weekday:
        return _intRangeOf(form, "ksxq", "jsxq");
      case GxuEmptyClassroomViewType.period:
        return _intRangeOf(form, "ksjc", "jsjc");
    }
  }

  List<int> _intRangeOf(
    GxuEmptyClassroomQueryForm form,
    String startName,
    String endName,
  ) {
    final start = int.tryParse(
      form.selectField(startName)?.selectedValue ?? "",
    );
    final end = int.tryParse(form.selectField(endName)?.selectedValue ?? "");
    if (start == null || end == null || start > end) {
      return const <int>[];
    }
    return [for (var value = start; value <= end; value++) value];
  }

  int _availableSlotsOf(GxuEmptyClassroomRemoteRoom room) {
    var sum = 0;
    for (final mode in GxuEmptyClassroomViewType.values) {
      for (var number = 1; number <= _maxNumberOf(mode); number++) {
        if (room.buildCell(slotNumber: number, viewType: mode).isAvailable) {
          sum++;
        }
      }
    }
    return sum;
  }

  int _compareRows(GxuEmptyClassroomRow left, GxuEmptyClassroomRow right) {
    final countCompare = right.availableCount.compareTo(left.availableCount);
    if (countCompare != 0) {
      return countCompare;
    }
    return left.title.compareTo(right.title);
  }

  int _maxNumberOfViewType(GxuEmptyClassroomViewType mode) {
    switch (mode) {
      case GxuEmptyClassroomViewType.week:
        return 20;
      case GxuEmptyClassroomViewType.weekday:
        return 7;
      case GxuEmptyClassroomViewType.period:
        return 13;
    }
  }

  int _maxNumberOf(GxuEmptyClassroomViewType mode) {
    return _maxNumberOfViewType(mode);
  }

  bool _isRoomUnavailable(GxuEmptyClassroomRemoteRoom room) {
    if (room.statusCode.isNotEmpty && room.statusCode != "1") {
      return true;
    }
    return room.undergraduateUnavailable;
  }
}

bool gxuLooksLikeBuildingField(GxuEmptyClassroomSelectField field) {
  final haystack = "${field.name} ${field.label}".toLowerCase();
  return haystack.contains("jxl") ||
      haystack.contains("jzw") ||
      haystack.contains("building") ||
      haystack.contains("教学楼") ||
      haystack.contains("楼宇");
}

String _weekdayLabelOf(int value) {
  const labels = <int, String>{
    1: "星期一",
    2: "星期二",
    3: "星期三",
    4: "星期四",
    5: "星期五",
    6: "星期六",
    7: "星期日",
  };
  return labels[value] ?? "星期$value";
}

List<String> _filterValidValues(
  List<GxuEmptyClassroomOption> options,
  List<String> values,
) {
  final optionValues = options.map((item) => item.value).toSet();
  final filtered = <String>[];
  for (final value in values) {
    if (optionValues.contains(value)) {
      filtered.add(value);
    }
  }
  return filtered;
}

String _validatedSelectedValue(
  GxuEmptyClassroomSelectField? field,
  List<GxuEmptyClassroomOption> options,
) {
  final selected = field?.selectedValue ?? "";
  if (_filterValidValues(options, [selected]).isEmpty) {
    return "";
  }
  return selected;
}

List<String> _validatedSelectedValues(
  GxuEmptyClassroomSelectField? field,
  List<GxuEmptyClassroomOption> options,
) {
  return _filterValidValues(options, field?.selectedValues ?? const <String>[]);
}

String _shortOccupiedLabel(String value) {
  final fragments = value.split("\n").where((item) => item.trim().isNotEmpty);
  final list = fragments.toList();
  if (list.isEmpty) {
    return "占用";
  }
  if (list.length == 1) {
    final label = list.first.split(" ").first.trim();
    if (label.length <= 4) {
      return label;
    }
  }
  return "占用";
}

String _seatTextOf(dynamic value) {
  final raw = _stringOf(value);
  if (raw.isEmpty) {
    return "";
  }
  if (raw.endsWith(".0")) {
    return raw.substring(0, raw.length - 2);
  }
  return raw;
}

bool _boolOf(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value == 1;
  }
  final text = _stringOf(value).toLowerCase();
  return text == "1" || text == "true";
}

String _stringOf(dynamic value) {
  if (value == null) {
    return "";
  }
  final text = value.toString().trim();
  if (text == "null") {
    return "";
  }
  return text;
}

Map<String, String> _stringMapOf(dynamic value) {
  if (value is Map<String, String>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(_stringOf(key), _stringOf(item)))
      ..removeWhere((key, item) => key.isEmpty || item.isEmpty);
  }
  return const <String, String>{};
}

Map<String, List<String>> _stringListMapOf(dynamic value) {
  if (value is! Map) {
    return const <String, List<String>>{};
  }
  final result = <String, List<String>>{};
  value.forEach((key, item) {
    if (item is List) {
      result[key.toString()] = [
        for (final entry in item)
          if (_stringOf(entry).isNotEmpty) _stringOf(entry),
      ];
      return;
    }
    final normalized = _stringOf(item);
    result[key.toString()] = normalized.isEmpty ? const [] : [normalized];
  });
  return result;
}

String _normalizeText(String value) {
  return value.replaceAll(RegExp(r"\s+"), " ").trim();
}
