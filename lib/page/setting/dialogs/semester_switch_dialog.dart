import 'package:flutter/widgets.dart';
import 'package:watermeter/page/setting/dialogs/gxu_semester_switch_dialog.dart';
import 'package:watermeter/page/setting/dialogs/legacy_semester_switch_dialog.dart';
import 'package:watermeter/repository/preference.dart' as pref;

class SemesterSwitchDialog extends StatelessWidget {
  const SemesterSwitchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    if (pref.getBool(pref.Preference.isGxuMode)) {
      return const GxuSemesterSwitchDialog();
    }
    return const LegacySemesterSwitchDialog();
  }
}
