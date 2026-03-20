bool gxuIsDegreeCourse({
  required String courseType,
  required String englishCourseType,
}) {
  final normalizedType = courseType.replaceAll(RegExp(r"\s+"), "");
  if (normalizedType.isNotEmpty) {
    if (normalizedType.contains("非学位")) {
      return false;
    }
    if (normalizedType.contains("学位")) {
      return true;
    }
  }
  return englishCourseType.toUpperCase() == "D";
}
