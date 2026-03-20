import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart' as i18n;
import 'package:watermeter/page/public_widget/wheel_choser.dart';
import 'package:watermeter/repository/preference.dart' as pref;

class LegacySemesterSwitchDialog extends StatefulWidget {
  const LegacySemesterSwitchDialog({super.key});

  @override
  State<LegacySemesterSwitchDialog> createState() =>
      _LegacySemesterSwitchDialogState();
}

class _LegacySemesterSwitchDialogState
    extends State<LegacySemesterSwitchDialog> {
  late int selectedYear;
  late int selectedSemester;
  late int lastSelectedYear;
  late int lastSelectedSemester;
  late List<int> years;
  late List<WheelChooseOptions<int>> yearOptions;
  late List<WheelChooseOptions<int>> semesterOptions;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    selectedYear = currentYear;
    lastSelectedYear = currentYear;
    years = List.generate(currentYear - 2015, (index) => 2016 + index);
    final semesterCode = pref.getString(pref.Preference.currentSemester);
    if (semesterCode.length == 5) {
      selectedYear = int.tryParse(semesterCode.substring(0, 4)) ?? currentYear;
      lastSelectedYear = selectedYear;
      selectedSemester = int.tryParse(semesterCode.substring(4)) ?? 1;
      lastSelectedSemester = selectedSemester;
      return;
    }
    if (semesterCode.length == 11) {
      final splitCode = semesterCode.split("-");
      selectedYear = int.tryParse(splitCode.first) ?? currentYear;
      lastSelectedYear = selectedYear;
      selectedSemester = int.tryParse(splitCode.last) ?? 1;
      lastSelectedSemester = selectedSemester;
      return;
    }
    selectedSemester = 1;
    lastSelectedSemester = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    yearOptions = years
        .map(
          (year) => WheelChooseOptions(
            data: year,
            hint: i18n.FlutterI18n.translate(
              context,
              'classtable.semester_switcher.year',
              translationParams: {'year': '$year'},
            ),
          ),
        )
        .toList();
    semesterOptions = [
      WheelChooseOptions(
        data: 1,
        hint: i18n.FlutterI18n.translate(
          context,
          'classtable.semester_switcher.first_academic_year',
        ),
      ),
      WheelChooseOptions(
        data: 2,
        hint: i18n.FlutterI18n.translate(
          context,
          'classtable.semester_switcher.second_academic_year',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: i18n.I18nText('classtable.semester_switcher.choose_semester'),
      content: SizedBox(
        height: 150,
        width: double.maxFinite,
        child: Row(
          children: [
            Expanded(
              child: WheelChoose<int>(
                defaultPage: !years.contains(selectedYear)
                    ? years.length - 1
                    : years.indexOf(selectedYear),
                options: yearOptions,
                changeBookIdCallBack: (res) {
                  setState(() => selectedYear = res);
                },
              ),
            ),
            Expanded(
              child: WheelChoose<int>(
                defaultPage: selectedSemester - 1,
                options: semesterOptions,
                changeBookIdCallBack: (res) {
                  setState(() => selectedSemester = res);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: i18n.I18nText('cancel'),
        ),
        TextButton(
          onPressed: _confirmSelection,
          child: i18n.I18nText('confirm'),
        ),
      ],
    );
  }

  Future<void> _confirmSelection() async {
    if (lastSelectedSemester == selectedSemester &&
        lastSelectedYear == selectedYear) {
      Navigator.of(context).pop(false);
      return;
    }
    await pref.setBool(pref.Preference.isUserDefinedSemester, true);
    var semester = selectedYear.toString();
    if (!pref.getBool(pref.Preference.role)) {
      semester += "-${selectedYear + 1}-";
    }
    semester += selectedSemester.toString();
    await pref.setString(pref.Preference.currentSemester, semester);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
