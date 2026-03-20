// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

Widget buildSettingSectionTitle(String text) => Text(
  text,
  style: const TextStyle(fontWeight: FontWeight.bold),
).padding(bottom: 8).center();
