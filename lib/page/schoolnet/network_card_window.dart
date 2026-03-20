// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/schoolnet/gxu_network_info.dart';

class NetworkCardWindow extends StatefulWidget {
  const NetworkCardWindow({super.key});

  @override
  State<NetworkCardWindow> createState() => _NetworkCardWindowState();
}

class _NetworkCardWindowState extends State<NetworkCardWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, "school_net.title")),
      ),
      body: const GxuNetworkInfo(),
    );
  }
}
