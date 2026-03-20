import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/xidian_ids/classtable.dart';
import 'package:watermeter/page/classtable/class_add/class_add_window.dart';
import 'package:watermeter/page/classtable/class_page/class_change_list.dart';
import 'package:watermeter/page/classtable/class_page/classtable_ical_export.dart';
import 'package:watermeter/page/classtable/class_page/not_arranged_class_list.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';
import 'package:watermeter/page/public_widget/toast.dart';

enum ClasstableMenuAction {
  notArranged,
  classChanged,
  addClass,
  generateIcal,
  outputToSystem,
  refreshClasstable,
}

class ClasstableActionsMenu extends StatelessWidget {
  final ClassTableWidgetState classTableState;

  const ClasstableActionsMenu({super.key, required this.classTableState});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ClasstableMenuAction>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: _menuItems,
      onSelected: (action) => _onSelected(context, action),
    );
  }

  List<PopupMenuEntry<ClasstableMenuAction>> _menuItems(
    BuildContext context,
  ) => [
    PopupMenuItem<ClasstableMenuAction>(
      value: ClasstableMenuAction.notArranged,
      child: Text(
        FlutterI18n.translate(context, "classtable.popup_menu.not_arranged"),
      ),
    ),
    PopupMenuItem<ClasstableMenuAction>(
      value: ClasstableMenuAction.classChanged,
      child: Text(
        FlutterI18n.translate(context, "classtable.popup_menu.class_changed"),
      ),
    ),
    PopupMenuItem<ClasstableMenuAction>(
      value: ClasstableMenuAction.addClass,
      child: Text(
        FlutterI18n.translate(context, "classtable.popup_menu.add_class"),
      ),
    ),
    PopupMenuItem<ClasstableMenuAction>(
      value: ClasstableMenuAction.generateIcal,
      child: Text(
        FlutterI18n.translate(context, "classtable.popup_menu.generate_ical"),
      ),
    ),
    PopupMenuItem<ClasstableMenuAction>(
      value: ClasstableMenuAction.outputToSystem,
      child: Text(
        FlutterI18n.translate(
          context,
          "classtable.popup_menu.output_to_system",
        ),
      ),
    ),
    PopupMenuItem<ClasstableMenuAction>(
      value: ClasstableMenuAction.refreshClasstable,
      child: Text(
        FlutterI18n.translate(
          context,
          "classtable.popup_menu.refresh_classtable",
        ),
      ),
    ),
  ];

  Future<void> _onSelected(
    BuildContext context,
    ClasstableMenuAction action,
  ) async {
    switch (action) {
      case ClasstableMenuAction.notArranged:
        return _openNotArranged(context);
      case ClasstableMenuAction.classChanged:
        return _openClassChanged(context);
      case ClasstableMenuAction.addClass:
        return _addUserDefinedClass(context);
      case ClasstableMenuAction.generateIcal:
        return _generateIcal(context);
      case ClasstableMenuAction.outputToSystem:
        return _outputToSystemCalendar(context);
      case ClasstableMenuAction.refreshClasstable:
        return _refreshClasstable(context);
    }
  }

  Future<void> _openNotArranged(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            NotArrangedClassList(notArranged: classTableState.notArranged),
      ),
    );
  }

  Future<void> _openClassChanged(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            ClassChangeList(classChanges: classTableState.classChange),
      ),
    );
  }

  Future<void> _addUserDefinedClass(BuildContext context) async {
    final semesterLength = classTableState.semesterLength;
    final data = await Navigator.of(context)
        .push<(ClassDetail, TimeArrangement)>(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                ClassAddWindow(semesterLength: semesterLength),
          ),
        );
    if (!context.mounted || data == null) return;
    await classTableState.addUserDefinedClass(data.$1, data.$2);
  }

  Future<void> _generateIcal(BuildContext context) async {
    await exportClasstableIcal(
      context: context,
      classTableState: classTableState,
    );
  }

  Future<void> _outputToSystemCalendar(BuildContext context) async {
    final result = await classTableState.outputToCalendar(() async {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            FlutterI18n.translate(
              context,
              "classtable.output_to_system.request_all_title",
            ),
          ),
          content: Text(
            FlutterI18n.translate(
              context,
              "classtable.output_to_system.request_all",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(FlutterI18n.translate(context, "confirm")),
            ),
          ],
        ),
      );
    });

    if (!context.mounted) return;
    showToast(
      context: context,
      msg: FlutterI18n.translate(
        context,
        result
            ? "classtable.output_to_system.success"
            : "classtable.output_to_system.failure",
      ),
    );
  }

  Future<void> _refreshClasstable(BuildContext context) async {
    final isAccepted =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              FlutterI18n.translate(context, "setting.class_refresh_title"),
            ),
            content: Text(
              FlutterI18n.translate(context, "setting.class_refresh_content"),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: Text(FlutterI18n.translate(context, "cancel")),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(FlutterI18n.translate(context, "confirm")),
              ),
            ],
          ),
        ) ??
        false;

    if (!context.mounted || !isAccepted) return;

    await classTableState.updateClasstable(context);
    if (!context.mounted) return;

    showToast(
      context: context,
      msg: FlutterI18n.translate(
        context,
        "classtable.refresh_classtable.success",
      ),
    );
  }
}
