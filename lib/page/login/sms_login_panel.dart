// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/login/login_form_widgets.dart';
import 'package:watermeter/page/login/phone_utils.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/logger.dart';

class SmsLoginPanel extends StatefulWidget {
  final GxuCASession session;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final double fieldSpacing;
  final VoidCallback onSubmit;

  const SmsLoginPanel({
    super.key,
    required this.session,
    required this.phoneController,
    required this.codeController,
    required this.fieldSpacing,
    required this.onSubmit,
  });

  @override
  State<SmsLoginPanel> createState() => _SmsLoginPanelState();
}

class _SmsLoginPanelState extends State<SmsLoginPanel> {
  static const _defaultCountdownSeconds = 60;

  Timer? _smsTimer;
  int _countdownSeconds = 0;
  bool _obscureCode = true;

  @override
  void dispose() {
    _smsTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _smsTimer?.cancel();
    setState(() {
      _countdownSeconds = seconds;
    });
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() => _countdownSeconds = 0);
        return;
      }
      setState(() => _countdownSeconds -= 1);
    });
  }

  Future<void> _sendSmsCode() async {
    final phone = normalizeChinaPhone(widget.phoneController.text);
    if (phone.isEmpty) {
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "login.phone_required"),
      );
      return;
    }
    if (!isChinaPhone(phone)) {
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "login.phone_invalid"),
      );
      return;
    }

    try {
      await widget.session.sendSmsCode(mobile: phone);
      if (!mounted) return;
      showToast(
        context: context,
        msg: FlutterI18n.translate(context, "login.sms_sent"),
      );
      _startCountdown(_defaultCountdownSeconds);
    } catch (e) {
      log.warning("[sms_login_panel][send_sms] failed (${e.runtimeType}).");
      if (!mounted) return;
      final msg = e is LoginFailedException
          ? e.msg
          : FlutterI18n.translate(context, "login.sms_send_failed");
      showToast(context: context, msg: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmsLoginFields(
      phoneController: widget.phoneController,
      codeController: widget.codeController,
      countdownSeconds: _countdownSeconds,
      onSendCode: _sendSmsCode,
      onSubmit: widget.onSubmit,
      obscureCode: _obscureCode,
      onToggleCodeVisibility: () {
        setState(() {
          _obscureCode = !_obscureCode;
        });
      },
      fieldSpacing: widget.fieldSpacing,
    );
  }
}
