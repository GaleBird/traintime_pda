import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/setting/about_page/about_know_more_cards.dart';
import 'package:watermeter/page/setting/about_page/link_widget.dart';
import 'package:watermeter/repository/fork_info.dart';

class AboutKnowMorePage extends StatelessWidget {
  const AboutKnowMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(context, "setting.about_page.know_more"),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const ForkHeroCard(),
              const SizedBox(height: 16),
              ProjectLinksCard(links: _buildLinks(context)),
              const SizedBox(height: 16),
              const ProjectNoticeCard(),
            ],
          ),
        ),
      ),
    );
  }

  List<Link> _buildLinks(BuildContext context) {
    return [
      Link(
        icon: const Icon(Icons.code),
        name: FlutterI18n.translate(context, "setting.about_page.code"),
        url: ForkInfo.repositoryUrl,
      ),
      Link(
        icon: const Icon(Icons.call_split),
        name: FlutterI18n.translate(
          context,
          "setting.about_page.upstream_code",
        ),
        url: ForkInfo.upstreamRepositoryUrl,
      ),
    ];
  }
}
