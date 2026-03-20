class GxuSemesterOption {
  final String code;
  final String label;
  final bool isSelected;

  const GxuSemesterOption({
    required this.code,
    required this.label,
    required this.isSelected,
  });
}

class GxuCoursePageResult {
  final List<Map<String, dynamic>> rows;
  final int totalPages;

  const GxuCoursePageResult({required this.rows, required this.totalPages});
}
