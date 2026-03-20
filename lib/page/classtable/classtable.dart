// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:watermeter/page/classtable/class_page/classtable_page.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';

/// Intro of the classtable.
class ClassTableWindow extends StatefulWidget {
  final int currentWeek;
  final BuildContext parentContext;
  final BoxConstraints constraints;
  const ClassTableWindow({
    super.key,
    required this.currentWeek,
    required this.parentContext,
    required this.constraints,
  });

  @override
  State<ClassTableWindow> createState() => _ClassTableWindowState();
}

class _ClassTableWindowState extends State<ClassTableWindow> {
  late final ClassTableWidgetState _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = ClassTableWidgetState(currentWeek: widget.currentWeek);
  }

  @override
  Widget build(BuildContext context) {
    return ClassTableState(
      parentContext: widget.parentContext,
      constraints: widget.constraints,
      controllers: _controllers,
      child: const ClassTablePage(),
    );
  }
}
