import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/repository/auth_exceptions.dart';

class GxuEmptyClassroomParser {
  static const _emptyDetailPlaceholders = {"0", "0.0"};

  GxuEmptyClassroomQueryForm parseQueryPage(String html) {
    final document = parse(html);
    final toolbar = document.querySelector(".cxkxjs .toolbar");
    if (toolbar == null) {
      throw const LoginFailedException(msg: "广西大学空教室页缺少筛选工具栏。");
    }
    final fields = _parseToolbarFields(toolbar);
    _ensureRequiredSelect(fields.selectFields);
    _ensureQueryRangeSelectOptions(fields.selectFields);
    return GxuEmptyClassroomQueryForm(
      viewType: GxuEmptyClassroomViewType.period,
      selectFields: fields.selectFields,
      textFields: fields.textFields,
      classroomCatalog: const [],
    );
  }

  List<GxuEmptyClassroomCatalogRoom> parseClassroomCatalog(dynamic payload) {
    final list = _extractDataList(payload, scene: "空教室教室目录");
    final rooms = [
      for (final item in list) GxuEmptyClassroomCatalogRoom.fromJson(item),
    ].where((room) => room.id.isNotEmpty && room.name.isNotEmpty).toList();
    if (rooms.isEmpty) {
      throw const LoginFailedException(msg: "广西大学空教室教室目录为空。");
    }
    return rooms;
  }

  GxuEmptyClassroomResult parseResultPayload(dynamic payload) {
    final list = _extractDataList(payload, scene: "空教室查询结果");
    return GxuEmptyClassroomResult(
      rooms: [
        for (final item in list) GxuEmptyClassroomRemoteRoom.fromJson(item),
      ],
      fetchedAt: DateTime.now(),
    );
  }

  String parseDetailPayload(dynamic payload) {
    final body = _mapOf(payload, scene: "空教室占用详情");
    final data = _mapOf(body["data"], scene: "空教室占用详情");
    final lines = <String>[];
    _appendLine(lines, "排课信息", data["jk"]);
    _appendLine(lines, "排考信息", data["ks"]);
    _appendLine(lines, "借用信息", data["jy"]);
    _appendLine(lines, "调课信息", data["tk"]);
    _appendLine(lines, "其它信息", data["qt"]);
    if (lines.isEmpty) {
      return "未查询到占用详情";
    }
    return lines.join("\n");
  }

  _ToolbarFields _parseToolbarFields(Element toolbar) {
    final selectFields = <GxuEmptyClassroomSelectField>[];
    final textFields = <GxuEmptyClassroomTextField>[];
    for (final group in toolbar.querySelectorAll(".form-group")) {
      final label = _labelOf(group);
      for (final select in group.querySelectorAll("select[name]")) {
        selectFields.add(_parseSelectField(select, label));
      }
      for (final input in group.querySelectorAll("input[name]")) {
        textFields.add(_parseTextField(input, label));
      }
    }
    if (selectFields.isEmpty) {
      throw const LoginFailedException(msg: "广西大学空教室页缺少筛选下拉项。");
    }
    return _ToolbarFields(selectFields: selectFields, textFields: textFields);
  }

  String _labelOf(Element group) {
    final label = group.querySelector(".sameRow-label");
    return _normalizeText(label?.text ?? "");
  }

  GxuEmptyClassroomSelectField _parseSelectField(Element select, String label) {
    final name = select.attributes["name"]?.trim() ?? "";
    if (name.isEmpty) {
      throw const LoginFailedException(msg: "广西大学空教室页存在缺少 name 的筛选项。");
    }
    return GxuEmptyClassroomSelectField(
      name: name,
      label: label.isEmpty ? name : label.replaceAll(RegExp(r"[:：]"), ""),
      options: [
        for (final option in select.querySelectorAll("option"))
          GxuEmptyClassroomOption(
            value: option.attributes["value"]?.trim() ?? "",
            label: _normalizeText(option.text),
          ),
      ],
      selectedValues: _selectedValuesOf(select),
      isMulti: select.attributes.containsKey("multiple"),
    );
  }

  GxuEmptyClassroomTextField _parseTextField(Element input, String label) {
    final name = input.attributes["name"]?.trim() ?? "";
    if (name.isEmpty) {
      throw const LoginFailedException(msg: "广西大学空教室页存在缺少 name 的输入项。");
    }
    return GxuEmptyClassroomTextField(
      name: name,
      label: label.isEmpty ? name : label.replaceAll(RegExp(r"[:：]"), ""),
      value: input.attributes["value"]?.trim() ?? "",
      isNumeric: true,
    );
  }

  List<String> _selectedValuesOf(Element select) {
    final values = <String>[];
    for (final option in select.querySelectorAll("option")) {
      if (option.attributes.containsKey("selected")) {
        values.add(option.attributes["value"]?.trim() ?? "");
      }
    }
    if (values.isNotEmpty) {
      return values;
    }
    if (select.attributes.containsKey("multiple")) {
      return const <String>[];
    }
    final firstOption = select.querySelector("option");
    if (firstOption == null) {
      return const <String>[];
    }
    return [firstOption.attributes["value"]?.trim() ?? ""];
  }

  void _ensureRequiredSelect(List<GxuEmptyClassroomSelectField> fields) {
    const requiredNames = [
      "xqdm",
      "kszc",
      "jszc",
      "ksxq",
      "jsxq",
      "ksjc",
      "jsjc",
      "jxlh",
      "jsxxid",
      "zyqk",
      "zylx",
    ];
    final names = fields.map((field) => field.name).toSet();
    for (final name in requiredNames) {
      if (!names.contains(name)) {
        throw LoginFailedException(msg: "广西大学空教室页缺少筛选项：$name。");
      }
    }
  }

  void _ensureQueryRangeSelectOptions(
    List<GxuEmptyClassroomSelectField> fields,
  ) {
    const rangeSelectNames = [
      "xqdm",
      "kszc",
      "jszc",
      "ksxq",
      "jsxq",
      "ksjc",
      "jsjc",
    ];
    final fieldByName = {for (final field in fields) field.name: field};
    for (final name in rangeSelectNames) {
      final field = fieldByName[name];
      if (field == null) {
        throw LoginFailedException(msg: "广西大学空教室页缺少筛选项：$name。");
      }
      final hasUsableOption = field.options.any(
        (option) => option.value.trim().isNotEmpty,
      );
      if (!hasUsableOption) {
        throw LoginFailedException(msg: "广西大学空教室页筛选项缺少可用选项：$name。");
      }
    }
  }

  List<Map<String, dynamic>> _extractDataList(
    dynamic payload, {
    required String scene,
  }) {
    final body = _mapOf(payload, scene: scene);
    final data = body["data"];
    if (data is! List) {
      throw LoginFailedException(msg: "广西大学$scene接口返回的 data 不是列表。");
    }
    return [for (final item in data) _mapOf(item, scene: scene)];
  }

  Map<String, dynamic> _mapOf(dynamic value, {required String scene}) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw LoginFailedException(msg: "广西大学$scene接口返回异常。");
  }

  void _appendLine(List<String> lines, String label, dynamic value) {
    final text = _normalizeText(value?.toString() ?? "");
    if (text.isEmpty || _emptyDetailPlaceholders.contains(text)) {
      return;
    }
    lines.add("$label：$text");
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r"\s+"), " ").trim();
  }
}

class _ToolbarFields {
  final List<GxuEmptyClassroomSelectField> selectFields;
  final List<GxuEmptyClassroomTextField> textFields;

  const _ToolbarFields({required this.selectFields, required this.textFields});
}
