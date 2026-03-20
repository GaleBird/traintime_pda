import 'package:flutter/material.dart';
import 'package:watermeter/page/classtable/class_table_view/class_table_view.dart';
import 'package:watermeter/page/classtable/widgets/no_glow_scroll_behavior.dart';

class ClasstableWeekPager extends StatelessWidget {
  final PageController pageController;
  final int semesterLength;
  final ValueChanged<int> onPageChanged;

  const ClasstableWeekPager({
    super.key,
    required this.pageController,
    required this.semesterLength,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const NoGlowScrollBehavior(),
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: semesterLength,
        itemBuilder: (context, index) => LayoutBuilder(
          builder: (context, constraint) => RepaintBoundary(
            child: ClassTableView(constraint: constraint, index: index),
          ),
        ),
      ),
    );
  }
}
