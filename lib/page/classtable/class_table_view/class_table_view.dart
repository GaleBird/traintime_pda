// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/model/time_list.dart';
import 'package:watermeter/page/classtable/class_table_view/class_card.dart';
import 'package:watermeter/page/classtable/class_table_view/class_table_break_decoration.dart';
import 'package:watermeter/page/classtable/class_table_view/class_table_continuous_index_rows.dart';
import 'package:watermeter/page/classtable/class_table_view/class_organized_data.dart';
import 'package:watermeter/page/classtable/class_table_view/classtable_date_row.dart';
import 'package:watermeter/page/classtable/classtable_constant.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class ClassTableView extends StatefulWidget {
  final int index;
  final BoxConstraints constraint;

  const ClassTableView({
    super.key,
    required this.constraint,
    required this.index,
  });

  @override
  State<ClassTableView> createState() => _ClassTableViewState();
}

/// Block layout: periods + 午休/晚休 separators.
class _ClassTableViewState extends State<ClassTableView> {
  late ClassTableWidgetState classTableState;
  late BoxConstraints size;
  static const int _segmentedTotalBlocks = 61;
  static const int _phoneSegmentedScaleBlocks = 48;

  static const double _periodSpanBlocks = 5;
  static const double _breakSpanBlocks = 3;

  static const double _periodIndexFontSize = 11;
  static const double _periodTimeFontSize = 8;
  static const double _breakLabelFontSize = 12;
  static const double _periodCellVerticalPadding = 2;
  static const double _rowDividerWidth = 0.5;

  int get _totalBlocks {
    if (useContinuousClassLayout) return timeList.length ~/ 2;
    if (isGxuMode) return _segmentedTotalBlocks;
    return isPhone(context)
        ? _phoneSegmentedScaleBlocks
        : _segmentedTotalBlocks;
  }

  double blockheight(double count) =>
      count * (widget.constraint.minHeight - midRowHeight) / _totalBlocks;

  double get blockwidth => (size.maxWidth - leftRow) / 7;

  Widget _indexCellFrame({required double height, required Widget child}) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.22);
    return Container(
      width: leftRow,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor, width: _rowDividerWidth),
        ),
      ),
      child: child,
    );
  }

  Widget _breakIndexCell({required double height, required String i18nKey}) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.22);
    final scheme = Theme.of(context).colorScheme;
    final palette = ClassTableBreakDecoration.palette(scheme, i18nKey);

    return Container(
      width: leftRow,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.backgroundColor.withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(color: dividerColor, width: _rowDividerWidth),
        ),
      ),
      child: Text(
        FlutterI18n.translate(context, i18nKey),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _breakLabelFontSize,
          fontWeight: FontWeight.w800,
          color: palette.foregroundColor,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _periodIndexCell({required double height, required int indexOfChar}) {
    final start = timeList[indexOfChar * 2];
    final stop = timeList[indexOfChar * 2 + 1];
    final period = indexOfChar + 1;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return _indexCellFrame(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: _periodCellVerticalPadding,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontSize: _periodIndexFontSize, color: onSurface),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                start,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: _periodTimeFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                period.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                stop,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _periodTimeFontSize,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> classSubRow(bool isRest) {
    if (isRest) {
      List<Widget> thisRow = [];
      for (var index = 1; index <= 7; ++index) {
        List<ClassOrgainzedData> arrangedEvents = classTableState
            .getArrangement(weekIndex: widget.index, dayIndex: index);

        for (var i in arrangedEvents) {
          thisRow.add(
            Positioned(
              top: blockheight(i.start),
              height: blockheight(i.stop - i.start),
              left: leftRow + blockwidth * (index - 1),
              width: blockwidth,
              child: ClassCard(detail: i),
            ),
          );
        }
      }

      if (thisRow.isEmpty &&
          !preference.getBool(preference.Preference.decorated)) {
        thisRow.add(
          Center(
            child: Column(
              children: [
                SizedBox(height: blockheight(8)),
                Image.asset("assets/art/pda_classtable_empty.png", scale: 2),
                const SizedBox(height: 20),
                ...FlutterI18n.translate(
                  context,
                  "classtable.no_class",
                ).split("\n").map((e) => Text(e)),
              ],
            ),
          ).padding(left: leftRow),
        );
      }

      return thisRow;
    } else {
      if (useContinuousClassLayout) {
        return buildContinuousClassTableIndexRows(
          context,
          leftRowWidth: leftRow,
          blockHeight: blockheight,
        );
      }

      return List.generate(13, (index) {
        double height = blockheight(
          index != 4 && index != 9 ? _periodSpanBlocks : _breakSpanBlocks,
        );

        late int indexOfChar;
        if ([0, 1, 2, 3].contains(index)) {
          indexOfChar = index;
        } else if (index == 4) {
          indexOfChar = -1; // noon break
        } else if ([5, 6, 7, 8].contains(index)) {
          indexOfChar = index - 1;
        } else if (index == 9) {
          indexOfChar = -2; // supper break
        } else {
          //if ([10, 11, 12].contains(index))
          indexOfChar = isGxuMode ? index : index - 2;
        }

        if (indexOfChar == -1) {
          return _breakIndexCell(
            height: height,
            i18nKey: "classtable.noon_break",
          );
        }
        if (indexOfChar == -2) {
          return _breakIndexCell(
            height: height,
            i18nKey: "classtable.supper_break",
          );
        }
        return _periodIndexCell(height: height, indexOfChar: indexOfChar);
      });
    }
  }

  void _reload() {
    if (mounted) {
      setState(() {});
    }
  }

  void updateSize() => size = ClassTableState.of(context)!.constraints;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    classTableState = ClassTableState.of(context)!.controllers;
    classTableState.addListener(_reload);
    updateSize();
  }

  @override
  void dispose() {
    classTableState.removeListener(_reload);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClassTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateSize();
  }

  @override
  Widget build(BuildContext context) {
    final table =
        [
          classSubRow(false)
              .toColumn()
              .decorated(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.75),
              )
              .constrained(width: leftRow)
              .positioned(left: 0),
          ...ClassTableBreakDecoration.stripes(
            enabled: !useContinuousClassLayout,
            left: leftRow,
            width: size.maxWidth - leftRow,
            blockHeight: blockheight,
            periodSpanBlocks: _periodSpanBlocks,
            breakSpanBlocks: _breakSpanBlocks,
            scheme: Theme.of(context).colorScheme,
          ),
          ...classSubRow(true),
        ].toStack().constrained(
          height: blockheight(_segmentedTotalBlocks.toDouble()),
          width: size.maxWidth,
        );

    return [
      ClassTableDateRow(
        firstDay: classTableState.startDay
            .add(Duration(days: 7 * classTableState.offset))
            .add(Duration(days: 7 * widget.index)),
      ),
      (isGxuMode ? table : table.scrollable()).expanded(),
    ].toColumn();
  }
}
