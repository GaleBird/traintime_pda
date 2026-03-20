// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class InfoCard extends StatelessWidget {
  final IconData? iconData;
  final String title;
  final List<Widget> children;
  final bool dense;

  const InfoCard({
    super.key,
    this.iconData,
    required this.title,
    required this.children,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = dense ? 12.0 : 16.0;
    final titleStyle =
        (dense ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
            ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              textBaseline: TextBaseline.ideographic,
            );
    return [
          [
            if (iconData != null)
              Icon(
                iconData,
                size: dense ? 20 : 24,
                color: theme.primaryColor,
              ).padding(right: 8),
            Text(title, style: titleStyle),
          ].toRow(crossAxisAlignment: CrossAxisAlignment.center),

          SizedBox(height: dense ? 6 : 8),
          ...children,
        ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.start)
        .padding(all: padding)
        .card(elevation: 0);
  }
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool dense;
  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelFontSize = dense ? 14.0 : 16.0;
    final valueFontSize = dense ? 14.0 : 16.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 8),
      child: Row(
        children: [
          Icon(icon, size: dense ? 18 : 20, color: Colors.grey[600]),
          SizedBox(width: dense ? 10 : 12),
          Text(
            "$label：",
            style: TextStyle(color: Colors.grey[600], fontSize: labelFontSize),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
