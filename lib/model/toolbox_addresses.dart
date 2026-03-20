// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewAddresses {
  final String name;
  final String? url;
  final String description;
  final IconData iconData;
  final LaunchMode launchMode;
  final WidgetBuilder? pageBuilder;

  const WebViewAddresses({
    required this.name,
    required this.description,
    required this.iconData,
    this.url,
    this.launchMode = LaunchMode.externalApplication,
    this.pageBuilder,
  }) : assert(url != null || pageBuilder != null);
}
