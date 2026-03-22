// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/classtable/class_page/classtable_actions_menu.dart';
import 'package:watermeter/page/classtable/class_page/classtable_week_pager.dart';
import 'package:watermeter/page/classtable/classtable_constant.dart';
import 'package:watermeter/page/classtable/classtable_responsive.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';
import 'package:watermeter/page/classtable/class_page/week_choice_view.dart';
import 'package:watermeter/page/classtable/class_page/week_navigation_utils.dart';
import 'package:watermeter/page/classtable/widgets/no_glow_scroll_behavior.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/xidian_ids/classtable_session.dart';

class ContentClassTablePage extends StatefulWidget {
  const ContentClassTablePage({super.key});

  @override
  State<StatefulWidget> createState() => _ContentClassTablePageState();
}

class _ContentClassTablePageState extends State<ContentClassTablePage> {
  static const EdgeInsets _topRowPadding = EdgeInsets.only(top: 2, bottom: 4);
  static const double _selectedWeekHighlightAlpha = 0.3;
  static const double _unselectedWeekHighlightAlpha = 0.0;
  static const BorderRadius _weekChoiceBorderRadius = BorderRadius.all(
    Radius.circular(12.0),
  );

  bool isTopRowLocked = false;

  late final PageController pageControl;
  late final ScrollController rowControl;

  late BoxDecoration decoration;
  late ClassTableWidgetState classTableState;
  late final ValueNotifier<double> _pageProgress;
  bool _isInited = false;

  bool _shouldAnimatePageControl(int targetWeek) {
    if (!pageControl.hasClients) return true;
    final current = pageControl.page;
    if (current == null) return true;
    return current.round() != targetWeek;
  }

  void _onPageControlScrolled() {
    if (!pageControl.hasClients) return;
    final page = pageControl.page;
    if (page == null) return;
    if ((page - _pageProgress.value).abs() < 0.0001) return;
    _pageProgress.value = page;
  }

  @override
  void dispose() {
    if (_isInited) {
      pageControl.removeListener(_onPageControlScrolled);
      _pageProgress.dispose();
      pageControl.dispose();
      rowControl.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    classTableState = ClassTableState.of(context)!.controllers;

    if (!_isInited) {
      pageControl = PageController(
        initialPage: classTableState.chosenWeek,
        keepPage: true,
      );

      rowControl = ScrollController(
        initialScrollOffset: _weekRowOffsetForIndex(
          index: classTableState.chosenWeek,
          viewportWidth: ClassTableState.of(context)!.constraints.minWidth,
        ),
      );

      _pageProgress = ValueNotifier<double>(
        classTableState.chosenWeek.toDouble(),
      );
      pageControl.addListener(_onPageControlScrolled);
      _isInited = true;
    }

    File image = File("${supportPath.path}/${ClassTableFile.decorationName}");
    decoration = BoxDecoration(
      image:
          (preference.getBool(preference.Preference.decorated) &&
              image.existsSync())
          ? DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.4
                  : 1.0,
            )
          : null,
    );
  }

  /// 周次切换栏。
  Widget _topView(
    ClassTableHeaderMetrics metrics, {
    required double viewportWidth,
  }) {
    return SizedBox(
      height: metrics.topViewHeight,
      child: Container(
        padding: _topRowPadding,
        color: Theme.of(context).colorScheme.surface,
        child: _weekChoiceRow(metrics, viewportWidth: viewportWidth),
      ),
    );
  }

  Widget _weekChoiceRow(
    ClassTableHeaderMetrics metrics, {
    required double viewportWidth,
  }) {
    return ScrollConfiguration(
      behavior: const NoGlowScrollBehavior(),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemExtent: classTableWeekRowItemExtent(),
        controller: rowControl,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: classTableState.semesterLength,
        itemBuilder: (context, index) => _weekChoiceItem(
          context,
          index,
          metrics,
          viewportWidth: viewportWidth,
        ),
      ),
    );
  }

  Widget _weekChoiceItem(
    BuildContext context,
    int index,
    ClassTableHeaderMetrics metrics, {
    required double viewportWidth,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: weekButtonHorizontalPadding,
      ),
      child: SizedBox(
        width: weekButtonWidth,
        child: ValueListenableBuilder<double>(
          valueListenable: _pageProgress,
          builder: (context, page, child) {
            return Card(
              color: Theme.of(context).highlightColor.withValues(
                alpha: classTableWeekHighlightAlpha(
                  page: page,
                  index: index,
                  selectedAlpha: _selectedWeekHighlightAlpha,
                  unselectedAlpha: _unselectedWeekHighlightAlpha,
                ),
              ),
              elevation: 0.0,
              child: InkWell(
                borderRadius: _weekChoiceBorderRadius,
                onTap: () => _onWeekTapped(index, viewportWidth: viewportWidth),
                child: Padding(
                  padding: metrics.weekChoiceInnerPadding,
                  child: child,
                ),
              ),
            );
          },
          child: WeekChoiceView(index: index),
        ),
      ),
    );
  }

  double _weekRowOffsetForIndex({
    required int index,
    required double viewportWidth,
  }) {
    return classTableWeekRowOffsetForIndex(
      index: index,
      semesterLength: classTableState.semesterLength,
      viewportWidth: viewportWidth,
    );
  }

  int _currentWeekIndex() {
    if (!pageControl.hasClients) {
      return classTableState.chosenWeek;
    }
    final page = pageControl.page;
    if (page == null) {
      return classTableState.chosenWeek;
    }
    return page.round();
  }

  Future<void> _onWeekTapped(
    int weekIndex, {
    required double viewportWidth,
  }) async {
    if (isTopRowLocked) return;
    final distance = (_currentWeekIndex() - weekIndex).abs();
    final duration = classTableWeekJumpDuration(distance: distance);
    classTableState.chosenWeek = weekIndex;

    final shouldAnimatePage = _shouldAnimatePageControl(weekIndex);
    isTopRowLocked = shouldAnimatePage;

    final futures = <Future<void>>[];
    if (rowControl.hasClients) {
      futures.add(
        rowControl.animateTo(
          _weekRowOffsetForIndex(
            index: weekIndex,
            viewportWidth: viewportWidth,
          ),
          duration: duration,
          curve: Curves.easeInOutCubic,
        ),
      );
    }
    if (shouldAnimatePage && pageControl.hasClients) {
      futures.add(
        pageControl.animateToPage(
          weekIndex,
          curve: Curves.easeInOutCubic,
          duration: duration,
        ),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    if (shouldAnimatePage) {
      isTopRowLocked = false;
    }
  }

  Widget _buildBody(BoxConstraints constraints) {
    final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
    final headerMetrics = resolveClassTableHeaderMetrics(viewportSize);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _topView(headerMetrics, viewportWidth: viewportSize.width),
        DecoratedBox(
          decoration: decoration,
          child: ClasstableWeekPager(
            pageController: pageControl,
            semesterLength: classTableState.semesterLength,
            onPageChanged: (value) {
              if (isTopRowLocked) return;
              classTableState.chosenWeek = value;
              if (!rowControl.hasClients) return;
              rowControl.animateTo(
                _weekRowOffsetForIndex(
                  index: value,
                  viewportWidth: viewportSize.width,
                ),
                duration: const Duration(milliseconds: changePageTime),
                curve: Curves.easeInOut,
              );
            },
          ),
        ).expanded(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, "classtable.page_title")),
        leading: BackButton(
          onPressed: () =>
              Navigator.of(ClassTableState.of(context)!.parentContext).pop(),
        ),
        actions: [ClasstableActionsMenu(classTableState: classTableState)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => _buildBody(constraints),
      ),
    );
  }
}
