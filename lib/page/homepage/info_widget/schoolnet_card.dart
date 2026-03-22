// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/page/homepage/main_page_card.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/schoolnet/gxu_network_formatter.dart';
import 'package:watermeter/page/schoolnet/network_card_window.dart';
import 'package:watermeter/repository/gxu_ids/gxu_schoolnet_credentials.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_session.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/schoolnet_session.dart';

class SchoolnetCard extends StatelessWidget {
  const SchoolnetCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (preference.getBool(preference.Preference.isGxuMode)) {
      return const _GxuSchoolnetCard();
    }
    return const _XduSchoolnetCard();
  }
}

class _XduSchoolnetCard extends StatelessWidget {
  const _XduSchoolnetCard();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MainPageCard(
        onPressed: () async {
          context.pushReplacement(const NetworkCardWindow());
        },
        isLoad: schoolNetStatus.value == SessionState.fetching,
        icon: MingCuteIcons.mgc_wifi_fill,
        text: FlutterI18n.translate(context, "homepage.school_net.no_password"),
        infoText: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 20),
            children: [
              if (_isMissingPassword()) ...[
                TextSpan(
                  text: FlutterI18n.translate(
                    context,
                    "homepage.school_net.no_password",
                  ),
                ),
              ] else if (schoolNetStatus.value == SessionState.fetched) ...[
                TextSpan(
                  text: FlutterI18n.translate(
                    context,
                    "homepage.school_net.title",
                    translationParams: {
                      "usage": networkInfo.value!.used.replaceAll("G", " GB"),
                    },
                  ),
                ),
              ] else
                TextSpan(
                  text: FlutterI18n.translate(
                    context,
                    schoolNetStatus.value == SessionState.error
                        ? "homepage.school_net.failed"
                        : "homepage.school_net.fetching",
                  ),
                ),
            ],
          ),
        ),
        bottomText: Text(
          schoolNetStatus.value == SessionState.fetched
              ? FlutterI18n.translate(
                  context,
                  "homepage.school_net.remaining",
                  translationParams: {"remaining": networkInfo.value!.charged},
                )
              : schoolNetStatus.value == SessionState.error
              ? FlutterI18n.translate(context, isError.value)
              : FlutterI18n.translate(context, "homepage.school_net.fetching"),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  bool _isMissingPassword() {
    return preference
        .getString(preference.Preference.schoolNetQueryPassword)
        .isEmpty;
  }
}

class _GxuSchoolnetCard extends StatelessWidget {
  const _GxuSchoolnetCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasCache = gxuNetworkInfo.value != null;
      return MainPageCard(
        onPressed: () async {
          context.pushReplacement(const NetworkCardWindow());
        },
        isLoad: !hasCache && gxuNetworkStatus.value == SessionState.fetching,
        icon: MingCuteIcons.mgc_wifi_fill,
        text: FlutterI18n.translate(context, "homepage.school_net.no_password"),
        infoText: Text(
          _buildInfoText(context),
          style: const TextStyle(fontSize: 20),
        ),
        bottomText: Text(
          _buildBottomText(context),
          overflow: TextOverflow.ellipsis,
        ),
      );
    });
  }

  String _buildInfoText(BuildContext context) {
    final usage = gxuNetworkInfo.value;
    if (usage != null) {
      return FlutterI18n.translate(
        context,
        "homepage.school_net.title",
        translationParams: {"usage": formatGxuTrafficInGb(usage.usedTraffic)},
      );
    }
    if (_isMissingPassword()) {
      return FlutterI18n.translate(context, "homepage.school_net.no_password");
    }
    if (gxuNetworkStatus.value == SessionState.error) {
      return _resolveMessage(context, gxuNetworkError.value);
    }
    if (gxuNetworkStatus.value == SessionState.fetching) {
      return FlutterI18n.translate(context, "homepage.school_net.fetching");
    }
    return FlutterI18n.translate(context, "homepage.school_net.no_cache");
  }

  String _buildBottomText(BuildContext context) {
    final usage = gxuNetworkInfo.value;
    if (usage != null) {
      return _buildCachedBottomText(context, usage);
    }
    if (gxuNetworkStatus.value == SessionState.fetching) {
      return FlutterI18n.translate(context, "homepage.school_net.fetching");
    }
    if (gxuNetworkStatus.value == SessionState.error) {
      return _resolveMessage(context, gxuNetworkError.value);
    }
    if (_isMissingPassword()) {
      return FlutterI18n.translate(
        context,
        "homepage.school_net.no_cache_hint",
      );
    }
    return FlutterI18n.translate(context, "homepage.school_net.no_cache_hint");
  }

  String _buildCachedBottomText(BuildContext context, GxuNetworkUsage usage) {
    final age = formatGxuRefreshAge(context, usage.refreshedAt);
    if (isGxuSchoolnetCredentialError(gxuNetworkError.value)) {
      return FlutterI18n.translate(
        context,
        "homepage.school_net.cache_need_credentials",
        translationParams: {"age": age},
      );
    }
    if (gxuNetworkError.value.isNotEmpty) {
      return FlutterI18n.translate(
        context,
        "homepage.school_net.cache_refresh_failed",
        translationParams: {"age": age},
      );
    }
    final settlement = FlutterI18n.translate(
      context,
      "homepage.school_net.remaining",
      translationParams: {"remaining": usage.settlementDate},
    );
    final refresh = FlutterI18n.translate(
      context,
      "homepage.school_net.cache_age",
      translationParams: {"age": age},
    );
    return "$settlement · $refresh";
  }

  bool _isMissingPassword() {
    return preference
        .getString(preference.Preference.schoolNetQueryPassword)
        .isEmpty;
  }

  String _resolveMessage(BuildContext context, String value) {
    if (value.startsWith("school_net.") || value.startsWith("homepage.")) {
      return FlutterI18n.translate(context, value);
    }
    return value;
  }
}
