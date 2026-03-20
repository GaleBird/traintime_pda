// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watermeter/model/toolbox_addresses.dart';

class WebViewListTile extends StatelessWidget {
  final WebViewAddresses data;
  const WebViewListTile({super.key, required this.data});

  Future<void> _handleTap(BuildContext context) async {
    final pageBuilder = data.pageBuilder;
    if (pageBuilder != null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: pageBuilder));
      return;
    }
    final url = data.url;
    if (url == null) {
      return;
    }
    final isOpened = await launchUrl(
      Uri.parse(url),
      mode: data.launchMode,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
    if (!isOpened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FlutterI18n.translate(context, "toolbox.open_failed")),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(data.iconData),
      title: Text(data.name),
      subtitle: Text(data.description),
      onTap: () => _handleTap(context),
    );
  }
}
