import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/public_widget/app_icon.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/page/setting/about_page/about_know_more_rows.dart';
import 'package:watermeter/page/setting/about_page/link_widget.dart';
import 'package:watermeter/repository/app_brand.dart';
import 'package:watermeter/repository/fork_info.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class ForkHeroCard extends StatelessWidget {
  const ForkHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final version = preference.packageInfo.version;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surfaceContainerHigh],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlock = _ForkHeroText(version: version);
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIconWidget(size: 84),
                const SizedBox(height: 16),
                textBlock,
              ],
            );
          }
          return Row(
            children: [
              const AppIconWidget(size: 96),
              const SizedBox(width: 18),
              Expanded(child: textBlock),
            ],
          );
        },
      ),
    );
  }
}

class ProjectContributionCard extends StatelessWidget {
  const ProjectContributionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: Text(
        FlutterI18n.translate(
          context,
          "setting.about_page.project_contribution_title",
        ),
      ).padding(bottom: 8).center(),
      remaining: const [],
      bottomRow: const Column(
        children: [
          ContributionRow(
            icon: Icons.school_rounded,
            titleKey: "setting.about_page.contribution_integration_title",
            bodyKey: "setting.about_page.contribution_integration_body",
          ),
          Divider(height: 24),
          ContributionRow(
            icon: Icons.palette_outlined,
            titleKey: "setting.about_page.contribution_brand_title",
            bodyKey: "setting.about_page.contribution_brand_body",
          ),
          Divider(height: 24),
          ContributionRow(
            icon: Icons.build_circle_outlined,
            titleKey: "setting.about_page.contribution_maintenance_title",
            bodyKey: "setting.about_page.contribution_maintenance_body",
          ),
        ],
      ),
    );
  }
}

class ProjectLinksCard extends StatelessWidget {
  final List<Link> links;

  const ProjectLinksCard({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: Text(
        FlutterI18n.translate(context, "setting.about_page.project_links"),
      ).padding(bottom: 8).center(),
      remaining: const [],
      bottomRow: [
        ...links.map(
          (link) => LinkWidget(icon: link.icon, name: link.name, url: link.url),
        ),
        ListTile(
          minLeadingWidth: 0,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(
            FlutterI18n.translate(
              context,
              "setting.about_page.open_source_license",
            ),
          ),
          subtitle: Text(
            FlutterI18n.translate(
              context,
              "setting.about_page.open_source_license_subtitle",
            ),
          ),
          trailing: const Icon(Icons.navigate_next),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LicensePage(
                applicationName: AppBrand.appName,
                applicationVersion:
                    "v${preference.packageInfo.version}+"
                    "${preference.packageInfo.buildNumber}",
                applicationIcon: const AppIconWidget().padding(vertical: 16),
                applicationLegalese: FlutterI18n.translate(
                  context,
                  "setting.about_page.copyright_notice",
                  translationParams: {"maintainer": ForkInfo.maintainer},
                ),
              ),
            ),
          ),
        ),
      ].toColumn(),
    );
  }
}

class ProjectNoticeCard extends StatelessWidget {
  const ProjectNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReXCard(
      title: Text(
        FlutterI18n.translate(context, "setting.about_page.project_notice"),
      ).padding(bottom: 8).center(),
      remaining: const [],
      bottomRow: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NoticeRow(textKey: "setting.about_page.legal_origin"),
          const SizedBox(height: 12),
          const NoticeRow(textKey: "setting.about_page.legal_license"),
          const SizedBox(height: 12),
          const NoticeRow(textKey: "setting.about_page.legal_independence"),
          const SizedBox(height: 12),
          NoticeRow(
            textKey: "setting.about_page.legal_upstream_notice",
            translationParams: {"maintainer": ForkInfo.maintainer},
          ),
        ],
      ),
    );
  }
}

class _ForkHeroText extends StatelessWidget {
  final String version;

  const _ForkHeroText({required this.version});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            FlutterI18n.translate(
              context,
              "setting.about_page.fork_maintainer_badge",
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          ForkInfo.maintainer,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          FlutterI18n.translate(
            context,
            "setting.about_page.fork_maintainer_project_line",
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: scheme.onPrimaryContainer.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "v$version",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onPrimaryContainer.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          FlutterI18n.translate(
            context,
            "setting.about_page.fork_maintainer_description",
            translationParams: {"maintainer": ForkInfo.maintainer},
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onPrimaryContainer.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}
