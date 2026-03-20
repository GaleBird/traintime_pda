// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

String formatGxuTrafficInGb(String value) {
  final trafficInMb = _parseTrafficInMb(value);
  if (trafficInMb == null) {
    return value;
  }
  return "${(trafficInMb / 1000).toStringAsFixed(2)} GB";
}

String formatGxuRefreshAge(BuildContext context, DateTime refreshedAt) {
  final difference = DateTime.now().difference(refreshedAt);
  if (difference.inMinutes < 1) {
    return FlutterI18n.translate(context, "school_net.gxu.refresh_just_now");
  }
  if (difference.inHours < 1) {
    return FlutterI18n.translate(
      context,
      "school_net.gxu.refresh_minutes",
      translationParams: {"minutes": difference.inMinutes.toString()},
    );
  }
  if (difference.inDays < 1) {
    return FlutterI18n.translate(
      context,
      "school_net.gxu.refresh_hours",
      translationParams: {"hours": difference.inHours.toString()},
    );
  }
  return FlutterI18n.translate(
    context,
    "school_net.gxu.refresh_days",
    translationParams: {"days": difference.inDays.toString()},
  );
}

String formatGxuRefreshExact(DateTime refreshedAt) {
  final month = refreshedAt.month.toString().padLeft(2, "0");
  final day = refreshedAt.day.toString().padLeft(2, "0");
  final hour = refreshedAt.hour.toString().padLeft(2, "0");
  final minute = refreshedAt.minute.toString().padLeft(2, "0");
  return "${refreshedAt.year}-$month-$day $hour:$minute";
}

double? _parseTrafficInMb(String value) {
  final match = RegExp(
    r"(-?\d+(?:\.\d+)?)\s*([A-Za-z]+)",
  ).firstMatch(value.trim());
  final amount = double.tryParse(match?.group(1) ?? "");
  final unit = (match?.group(2) ?? "").toUpperCase();
  if (amount == null) {
    return null;
  }
  switch (unit) {
    case "KB":
    case "K":
      return amount / 1000;
    case "MB":
    case "M":
      return amount;
    case "GB":
    case "G":
      return amount * 1000;
    default:
      return null;
  }
}
