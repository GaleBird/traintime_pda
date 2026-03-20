// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';

class GxuNetworkParser {
  static const _loginTitle = "欢迎登录用户自助服务系统";
  static const _captchaPath = "/login/randomCode";

  bool isLoginPage(String html) {
    final text = _normalizeText(html);
    return text.contains(_loginTitle) && html.contains(_captchaPath);
  }

  String extractFormAction(String html) {
    final match = RegExp(r'<form action="([^"]+)"').firstMatch(html);
    return _requireGroup(match, "登录表单 action");
  }

  String extractCheckCode(String html) {
    final match = RegExp(
      r'name="checkcode"\s+value="([^"]*)"',
    ).firstMatch(html);
    return _requireGroup(match, "登录页 checkcode");
  }

  String? extractLoginError(String html) {
    final matches = RegExp(r"\}\)\('([^']*)'\);").allMatches(html);
    for (final match in matches) {
      final message = match.group(1)?.trim() ?? "";
      if (message.isNotEmpty && message != "null") {
        return message;
      }
    }
    return null;
  }

  GxuNetworkUsage parseDashboard({
    required String html,
    required String account,
    DateTime? refreshedAt,
  }) {
    final document = parse(html);
    final metrics = _extractMetrics(document);
    return GxuNetworkUsage(
      account: _extractAccount(document) ?? account,
      settlementDate: _extractSettlement(document),
      usedTraffic: _requireMetric(metrics, "已用流量"),
      freeTraffic: _requireMetric(metrics, "免费流量"),
      availableTraffic: _requireMetric(metrics, "可用流量"),
      protection: _requireMetric(metrics, "消费保护"),
      balance: _requireMetric(metrics, "账户余额"),
      refreshedAt: refreshedAt ?? DateTime.now(),
    );
  }

  String _normalizeText(String html) {
    final text = parse(html).body?.text ?? "";
    return text.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  Map<String, String> _extractMetrics(Document document) {
    final metrics = <String, String>{};
    for (final item in document.querySelectorAll("dl")) {
      final label = _normalizeElementText(item.querySelector("dd"));
      final value = _normalizeElementText(item.querySelector("dt"));
      if (label.isNotEmpty && value.isNotEmpty) {
        metrics[label] = value;
      }
    }
    return metrics;
  }

  String? _extractAccount(Document document) {
    final value = _extractRowValue(document, "账号");
    return value.isEmpty ? null : value;
  }

  String _extractSettlement(Document document) {
    final value = _extractRowValue(document, "计费周期");
    final match = RegExp(r"至\s*(\d{4}-\d{2}-\d{2})").firstMatch(value);
    if (match == null) {
      throw const FormatException("GXU 网络页面缺少计费周期结束日期");
    }
    return match.group(1)!;
  }

  String _extractRowValue(Document document, String label) {
    final normalizedTarget = _normalizeLabel(label);
    for (final row in document.querySelectorAll("div.row")) {
      final rowLabel = _normalizeLabel(row.querySelector("label")?.text ?? "");
      if (rowLabel == normalizedTarget) {
        final raw = _normalizeElementText(row);
        final match = RegExp(
          "${RegExp.escape(label)}\\s*[:：]?\\s*(.+)",
        ).firstMatch(raw);
        if (match != null) {
          return match.group(1)!.trim();
        }
      }
    }
    return "";
  }

  String _requireGroup(RegExpMatch? match, String field) {
    final value = match?.group(1)?.trim() ?? "";
    if (value.isEmpty) {
      throw FormatException("GXU 网络登录页缺少字段：$field");
    }
    return value;
  }

  String _normalizeLabel(String text) {
    return text.replaceAll(RegExp(r"[\s　：:]"), "");
  }

  String _normalizeElementText(Element? element) {
    final text = element?.text ?? "";
    return text.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  String _requireMetric(Map<String, String> metrics, String label) {
    final value = metrics[label];
    if (value == null || value.isEmpty) {
      throw FormatException("GXU 网络页面缺少字段：$label");
    }
    return value;
  }
}
