// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:watermeter/model/xidian_ids/classtable.dart';
import 'package:watermeter/model/xidian_ids/exam.dart';
import 'package:watermeter/model/xidian_ids/experiment.dart';
import 'package:watermeter/page/classtable/class_add/class_add_window.dart';
import 'package:watermeter/page/classtable/class_table_view/class_organized_data.dart';
import 'package:watermeter/page/classtable/class_table_view/class_card_layout.dart';
import 'package:watermeter/page/classtable/class_table_view/class_card_place_badge.dart';
import 'package:watermeter/page/classtable/arrangement_detail/arrangement_detail.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';
import 'package:watermeter/page/public_widget/both_side_sheet.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';

/// The card in [classSubRow], metioned in [ClassTableView].
class ClassCard extends StatelessWidget {
  final ClassOrgainzedData detail;

  List<dynamic> get data => detail.data;
  MaterialColor get color => detail.color;
  String get name => detail.name;
  String? get place => detail.place;
  String? get teacher => detail.teacher;
  const ClassCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final classTableState = ClassTableState.of(context)!.controllers;

    /// This is the result of the class info card.
    return Padding(
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        // Out
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // Border
          color: color.shade300.withValues(alpha: 0.8),
          padding: const EdgeInsets.all(2),
          child: Stack(
            children: [
              _InnerCard(
                color: color,
                content: _CardContent(
                  color: color,
                  name: name,
                  teacher: teacher,
                  place: place,
                ),
                onPressed: () => _showDetailSheet(context, classTableState),
              ),
              if (data.length > 1)
                ClipPath(
                  clipper: Triangle(),
                  child: Container(
                    color: color.shade300,
                  ).constrained(width: 8, height: 8),
                ).alignment(Alignment.topRight),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetailSheet(
    BuildContext context,
    ClassTableWidgetState classTableState,
  ) async {
    final controller = ClassTableState.of(context)!.controllers;

    /// The way to show the class info of the period.
    /// The last one indicate whether to delete this stuff.
    final toUse =
        await BothSideSheet.show<(ClassDetail, TimeArrangement, bool)>(
          title: FlutterI18n.translate(context, "classtable.class_card.title"),
          child: ArrangementDetail(
            information: List.generate(data.length, (index) {
              if (data.elementAt(index) is Subject ||
                  data.elementAt(index) is ExperimentData) {
                return data.elementAt(index);
              }
              final timeArrangement = data.elementAt(index) as TimeArrangement;
              return (
                classTableState.getClassDetail(
                  classTableState.timeArrangement.indexOf(timeArrangement),
                ),
                timeArrangement,
              );
            }),
            currentWeek: classTableState.currentWeek,
          ),
          context: context,
        );

    if (!context.mounted || toUse == null) {
      return;
    }

    if (toUse.$3) {
      await ClassTableState.of(
        context,
      )!.controllers.deleteUserDefinedClass(toUse.$2);
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassAddWindow(
          toChange: (toUse.$1, toUse.$2),
          semesterLength: controller.semesterLength,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    controller.editUserDefinedClass(result.$1, result.$2, result.$3);
  }
}

class _InnerCard extends StatelessWidget {
  final MaterialColor color;
  final Widget content;
  final VoidCallback onPressed;

  const _InnerCard({
    required this.color,
    required this.content,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        color: color.shade100.withValues(alpha: 0.7),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            overlayColor: Colors.transparent,
          ),
          onPressed: onPressed,
          child: content,
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  static const double _gap = 2;
  static const double _nameMinFontPhone = 8.4;
  static const double _nameMinFontTablet = 10.0;

  final MaterialColor color;
  final String name;
  final String? teacher;
  final String? place;

  const _CardContent({
    required this.color,
    required this.name,
    required this.teacher,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final placeLabel = _placeLabel(context);
    final teacherLabel = _primaryTeacher(teacher);
    final isPhoneLayout = isPhone(context);

    final infoStyle = TextStyle(
      color: color.shade900,
      fontSize: isPhoneLayout ? 9 : 11,
      height: 1.05,
    );
    final nameStyle = TextStyle(
      color: color.shade900,
      fontSize: isPhoneLayout ? 11 : 13,
      fontWeight: FontWeight.w700,
      height: 1.05,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = resolveClassCardLayout(
          isPhoneLayout: isPhoneLayout,
          height: constraints.maxHeight,
          hasTeacher: teacherLabel.trim().isNotEmpty,
        );
        final placeStyle = infoStyle.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        );

        return Padding(
          padding: layout.padding,
          child: [
            AutoSizeText(
              name,
              style: nameStyle,
              maxLines: layout.nameMaxLines,
              minFontSize: isPhoneLayout
                  ? _nameMinFontPhone
                  : _nameMinFontTablet,
              stepGranularity: 0.1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: _gap),
            Expanded(
              child: ClassCardPlaceBadge(
                color: color,
                isPhoneLayout: isPhoneLayout,
                value: placeLabel,
                maxLines: layout.placeMaxLines,
                minFontSize: layout.placeMinFontSize,
                style: placeStyle,
              ),
            ),
            if (layout.showTeacher) ...[
              const SizedBox(height: _gap),
              Text(
                teacherLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: infoStyle.copyWith(
                  color: color.shade900.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
        );
      },
    );
  }

  String _placeLabel(BuildContext context) {
    final value = place?.trim() ?? "";
    if (value.isNotEmpty) {
      return value;
    }
    return FlutterI18n.translate(
      context,
      "classtable.class_card.unknown_classroom",
    );
  }

  String _primaryTeacher(String? value) {
    final teacherValue = value?.trim() ?? "";
    if (teacherValue.isEmpty) {
      return "";
    }
    return teacherValue
        .split(RegExp(r'[、,，;；/\n]+'))
        .map((item) => item.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => teacherValue);
  }
}

class Triangle extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.addPolygon([
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
    ], true);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
