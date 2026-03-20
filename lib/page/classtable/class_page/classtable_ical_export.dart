import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';
import 'package:watermeter/page/public_widget/toast.dart';

Future<void> exportClasstableIcal({
  required BuildContext context,
  required ClassTableWidgetState classTableState,
}) async {
  try {
    await _showExportIntroDialog(context);
    if (!context.mounted) return;

    final fileName = _buildIcsFileName(
      semesterCode: classTableState.semesterCode,
      now: DateTime.now(),
    );

    await _exportIcs(context, fileName, classTableState.iCalenderStr);
    if (!context.mounted) return;

    showToast(
      context: context,
      msg: FlutterI18n.translate(
        context,
        "classtable.partner_classtable.save_dialog.success_message",
      ),
    );
  } on FileSystemException {
    if (!context.mounted) return;
    showToast(
      context: context,
      msg: FlutterI18n.translate(
        context,
        "classtable.partner_classtable.save_dialog.failure_message",
      ),
    );
  }
}

Future<void> _showExportIntroDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        FlutterI18n.translate(
          context,
          "classtable.partner_classtable.share_dialog.title",
        ),
      ),
      content: Text(
        FlutterI18n.translate(
          context,
          "classtable.partner_classtable.share_dialog.content",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(FlutterI18n.translate(context, "confirm")),
        ),
      ],
    ),
  );
}

String _buildIcsFileName({
  required String semesterCode,
  required DateTime now,
}) {
  return "classtable-${DateFormat("yyyyMMddTHHmmss").format(now)}-$semesterCode.ics";
}

Future<void> _exportIcs(
  BuildContext context,
  String fileName,
  String ics,
) async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return _exportIcsToDesktop(context, fileName, ics);
  }
  return _shareIcsWithMobile(context, fileName, ics);
}

Future<void> _exportIcsToDesktop(
  BuildContext context,
  String fileName,
  String ics,
) async {
  final resultFilePath = await FilePicker.platform.saveFile(
    dialogTitle: FlutterI18n.translate(
      context,
      "classtable.partner_classtable.save_dialog.title",
    ),
    fileName: fileName,
    allowedExtensions: ["ics"],
    lockParentWindow: true,
  );
  if (resultFilePath == null) return;

  final file = File(resultFilePath);
  if (!(await file.exists())) {
    await file.create();
  }
  await file.writeAsString(ics);
}

Future<void> _shareIcsWithMobile(
  BuildContext context,
  String fileName,
  String ics,
) async {
  final box = context.findRenderObject() as RenderBox?;
  final shareOrigin = box!.localToGlobal(Offset.zero) & box.size;

  final tempPath = (await getTemporaryDirectory()).path;
  final file = File("$tempPath/$fileName");
  if (!(await file.exists())) {
    await file.create();
  }

  await file.writeAsString(ics);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile("$tempPath/$fileName")],
      sharePositionOrigin: shareOrigin,
    ),
  );
  await file.delete();
}
