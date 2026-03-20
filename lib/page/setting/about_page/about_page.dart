// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/public_widget/app_icon.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/setting/about_page/about_know_more_page.dart';
import 'package:watermeter/page/setting/about_page/easter_egg_page.dart';
import 'package:watermeter/page/setting/about_page/link_widget.dart';
import 'package:watermeter/repository/app_brand.dart';
import 'package:watermeter/repository/fork_info.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  List<Link> linkData() => [
    Link(
      icon: const Icon(Icons.home),
      name: FlutterI18n.translate(context, "setting.about_page.homepage"),
      url: ForkInfo.maintainerUrl,
    ),
    Link(
      icon: const Icon(Icons.code),
      name: FlutterI18n.translate(context, "setting.about_page.code"),
      url: ForkInfo.repositoryUrl,
    ),
    Link(
      icon: const Icon(Icons.call_split),
      name: FlutterI18n.translate(context, "setting.about_page.upstream_code"),
      url: ForkInfo.upstreamRepositoryUrl,
    ),
  ];

  Widget _title(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
          const AppIconWidget(),
          const SizedBox(height: 16),
          Text(
            AppBrand.appName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "v${preference.packageInfo.version}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              FlutterI18n.translate(
                context,
                "setting.header_subtitle",
                translationParams: {"maintainer": ForkInfo.maintainer},
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.center)
        .padding(all: 32)
        .gestures(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EasterEggPage()),
          ),
        );
  }

  Widget get _developerList => ReXCard(
    title: Text(
      FlutterI18n.translate(context, "setting.acknowledgement"),
    ).padding(bottom: 8).center(),
    remaining: const [],
    bottomRow: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FlutterI18n.translate(
            context,
            "setting.about_page.fork_maintainer_description",
            translationParams: {"maintainer": ForkInfo.maintainer},
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 12),
        Text(
          FlutterI18n.translate(
            context,
            "setting.about_page.upstream_acknowledgement_subtitle",
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.left,
        ),
      ],
    ),
  );

  Widget _moreList(BuildContext context) => ReXCard(
    title: Text(
      FlutterI18n.translate(context, "setting.about_page.title"),
    ).padding(bottom: 8).center(),
    remaining: const [],
    bottomRow: [
      ...linkData().map(
        (link) => LinkWidget(icon: link.icon, name: link.name, url: link.url),
      ),
      ListTile(
        minLeadingWidth: 0,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.balance),
        title: Text(
          FlutterI18n.translate(context, "setting.about_page.know_more"),
        ),
        subtitle: Text(
          FlutterI18n.translate(
            context,
            "setting.about_page.know_more_subtitle",
          ),
        ),
        trailing: const Icon(Icons.navigate_next),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AboutKnowMorePage())),
      ),
      if (Platform.isAndroid)
        ListTile(
          minLeadingWidth: 0,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.code),
          title: Text(
            FlutterI18n.translate(context, "setting.about_page.sign_android"),
          ),
          subtitle: Text(preference.packageInfo.buildSignature),
        ),
    ].toColumn(),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 600 && size.width / size.height > 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, "setting.about_page.title")),
      ),
      body: Builder(
        builder: (context) {
          if (isWide) {
            return [
                  [_title(context), _developerList]
                      .toColumn(mainAxisAlignment: MainAxisAlignment.center)
                      .padding(vertical: 8)
                      .scrollable()
                      .flexible(),
                  [
                    _moreList(context),
                  ].toColumn().padding(vertical: 8).scrollable().flexible(),
                ]
                .toRow(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                )
                .constrained(maxWidth: 800)
                .center();
          }
          return [_title(context), _developerList, _moreList(context)]
              .toColumn(mainAxisAlignment: MainAxisAlignment.center)
              .padding(horizontal: 16)
              .scrollable()
              .constrained(maxWidth: 600)
              .center();
        },
      ),
    );
  }
}
