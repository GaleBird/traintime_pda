import 'package:flutter/material.dart';
import 'package:watermeter/page/homepage/small_function_card.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/score/gxu_course_selection.dart';

class GxuCourseSelectionCard extends StatelessWidget {
  const GxuCourseSelectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SmallFunctionCard(
      onPressed: () =>
          context.pushReplacement(const GxuCourseSelectionWindow()),
      icon: Icons.playlist_add_check_circle_rounded,
      nameKey: "homepage.toolbox.course_selection",
    );
  }
}
