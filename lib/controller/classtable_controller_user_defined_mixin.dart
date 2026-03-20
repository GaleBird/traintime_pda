part of 'classtable_controller.dart';

extension ClassTableControllerUserDefined on ClassTableController {
  void refreshUserDefinedClass() {
    userDefinedFile = File(
      "${supportPath.path}/${ClasstableStorage.userDefinedClassName}",
    );
    final userDefinedFileExists = userDefinedFile.existsSync();
    if (!userDefinedFileExists) {
      userDefinedFile.writeAsStringSync(
        jsonEncode(UserDefinedClassData.empty()),
      );
    }
    userDefinedClassData = UserDefinedClassData.fromJson(
      jsonDecode(userDefinedFile.readAsStringSync()),
    );
  }

  Future<void> addUserDefinedClass(
    ClassDetail classDetail,
    TimeArrangement timeArrangement,
  ) async {
    userDefinedClassData.userDefinedDetail.add(classDetail);
    timeArrangement.index = userDefinedClassData.userDefinedDetail.length - 1;
    userDefinedClassData.timeArrangement.add(timeArrangement);
    userDefinedFile.writeAsStringSync(
      jsonEncode(userDefinedClassData.toJson()),
    );
    await updateClassTable(isUserDefinedChanged: true);
  }

  Future<void> editUserDefinedClass(
    TimeArrangement originalTimeArrangement,
    ClassDetail classDetail,
    TimeArrangement timeArrangement,
  ) async {
    if (originalTimeArrangement.source != Source.user ||
        originalTimeArrangement.index != timeArrangement.index) {
      return;
    }

    final timeArrangementIndex = userDefinedClassData.timeArrangement.indexOf(
      originalTimeArrangement,
    );
    userDefinedClassData.timeArrangement[timeArrangementIndex].weekList =
        timeArrangement.weekList;
    userDefinedClassData.timeArrangement[timeArrangementIndex].teacher =
        timeArrangement.teacher;
    userDefinedClassData.timeArrangement[timeArrangementIndex].day =
        timeArrangement.day;
    userDefinedClassData.timeArrangement[timeArrangementIndex].start =
        timeArrangement.start;
    userDefinedClassData.timeArrangement[timeArrangementIndex].stop =
        timeArrangement.stop;
    userDefinedClassData.timeArrangement[timeArrangementIndex].classroom =
        timeArrangement.classroom;

    final classDetailIndex = originalTimeArrangement.index;
    userDefinedClassData.userDefinedDetail[classDetailIndex].name =
        classDetail.name;
    userDefinedClassData.userDefinedDetail[classDetailIndex].code =
        classDetail.code;
    userDefinedClassData.userDefinedDetail[classDetailIndex].number =
        classDetail.number;

    userDefinedFile.writeAsStringSync(
      jsonEncode(userDefinedClassData.toJson()),
    );
    await updateClassTable(isUserDefinedChanged: true);
  }

  Future<void> deleteUserDefinedClass(TimeArrangement timeArrangement) async {
    if (timeArrangement.source != Source.user) return;
    final indexToDelete = timeArrangement.index;
    userDefinedClassData.timeArrangement.remove(timeArrangement);
    userDefinedClassData.userDefinedDetail.removeAt(indexToDelete);

    for (final arrangement in userDefinedClassData.timeArrangement) {
      if (arrangement.index > indexToDelete) {
        arrangement.index -= 1;
      }
    }

    userDefinedFile.writeAsStringSync(
      jsonEncode(userDefinedClassData.toJson()),
    );
    await updateClassTable(isUserDefinedChanged: true);
  }
}
