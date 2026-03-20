import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_course_selection.dart';
import 'package:watermeter/page/score/gxu_course_selection_state.dart';

void main() {
  test('course selection summary splits degree and non-degree courses', () {
    final entries = [
      _entry(courseType: "学位课", credit: "3"),
      _entry(courseType: "学位课", credit: "2"),
      _entry(courseType: "非学位课", credit: "1.5"),
      _entry(courseType: "公共选修", credit: "1"),
    ];

    final summary = GxuCourseSelectionSummary.fromEntries(entries);

    expect(summary.courseCount, 4);
    expect(summary.degreeCourseCount, 2);
    expect(summary.nonDegreeCourseCount, 2);
    expect(summary.degreeCredits, 5);
    expect(summary.nonDegreeCredits, 2.5);
    expect(summary.totalCredits, 7.5);
  });

  test('course selection entry keeps only the first teacher for display', () {
    final entry = _entry(
      courseType: "学位课",
      credit: "3",
      teacher: "张老师、李老师; 王老师",
    );

    expect(entry.primaryTeacher, "张老师");
  });
}

GxuCourseSelectionEntry _entry({
  required String courseType,
  required String credit,
  String teacher = "老师",
}) {
  return GxuCourseSelectionEntry(
    semesterCode: "2025-2026-1",
    semesterName: "2025秋",
    courseCode: "CODE",
    courseName: "课程",
    classNumber: "001",
    className: "教学班",
    teacher: teacher,
    courseType: courseType,
    englishCourseType: "",
    credit: credit,
    scheduleText: "",
    status: "已选",
  );
}
