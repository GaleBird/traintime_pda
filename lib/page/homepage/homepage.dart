// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/controller/classtable_controller.dart';
import 'package:watermeter/page/homepage/info_widget/classtable_card.dart';
import 'package:watermeter/page/homepage/info_widget/schoolnet_card.dart';
import 'package:watermeter/page/homepage/notice_card/update_card.dart';
import 'package:watermeter/page/homepage/refresh.dart';
import 'package:watermeter/page/homepage/toolbox/gxu_course_selection_card.dart';
import 'package:watermeter/page/homepage/toolbox/score_card.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/notification/course_reminder_service.dart';

class MainPage extends StatefulWidget {
  final Function()? changePage;

  const MainPage({super.key, this.changePage});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    Get.put(ClassTableController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await CourseReminderService().initialize();
        await CourseReminderService().validateAndUpdateNotifications();
        log.info(
          "Notifications validated and updated after homepage initialization.",
        );
      } catch (e, stackTrace) {
        log.error(
          "Failed to validate notifications after homepage initialization",
          e,
          stackTrace,
        );
      }
    });
  }

  List<Widget> _buildSmallFunctionCards() => const [
    ScoreCard(),
    GxuCourseSelectionCard(),
  ];

  String get _now {
    final now = DateTime.now();
    if (now.hour >= 5 && now.hour < 9) return "homepage.time_string.morning";
    if (now.hour >= 9 && now.hour < 11) {
      return "homepage.time_string.before_noon";
    }
    if (now.hour >= 11 && now.hour < 14) return "homepage.time_string.at_noon";
    if (now.hour >= 14 && now.hour < 18) {
      return "homepage.time_string.afternoon";
    }
    if (now.hour >= 18 || now.hour == 0) return "homepage.time_string.night";
    return "homepage.time_string.midnight";
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxScrolled) => [
        SliverAppBar(
          centerTitle: false,
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: GetBuilder<ClassTableController>(
              builder: (c) => Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FlutterI18n.translate(context, _now),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? null
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    c.state == ClassTableState.fetched
                        ? c.getCurrentWeek(updateTime) >= 0 &&
                                  c.getCurrentWeek(updateTime) <
                                      c.classTableData.semesterLength
                              ? FlutterI18n.translate(
                                  context,
                                  "homepage.on_weekday",
                                  translationParams: {
                                    "current":
                                        "${c.getCurrentWeek(updateTime) + 1}",
                                  },
                                )
                              : FlutterI18n.translate(
                                  context,
                                  "homepage.on_holiday",
                                )
                        : c.state == ClassTableState.error
                        ? FlutterI18n.translate(context, "homepage.load_error")
                        : FlutterI18n.translate(context, "homepage.loading"),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? null
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          showToast(
            context: context,
            msg: FlutterI18n.translate(context, "homepage.loading_message"),
          );
          await update(isForceClassTableRefresh: true);
          if (!context.mounted) return;
          _showGxuRefreshResult();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          children: [
            UpdateCard().padding(bottom: 8),
            const ClassTableCard().padding(bottom: 8),
            const SchoolnetCard().padding(bottom: 8),
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: GridView.extent(
                maxCrossAxisExtent: 96,
                shrinkWrap: true,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildSmallFunctionCards(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGxuRefreshResult() {
    final classTableController = Get.find<ClassTableController>();
    final message = classTableController.error;
    if (classTableController.state == ClassTableState.fetched &&
        (message == null || message.isEmpty)) {
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "homepage.loaded"),
      );
      return;
    }
    showToast(
      context: context,
      msg: message ?? FlutterI18n.translate(context, "homepage.load_error"),
    );
  }
}
