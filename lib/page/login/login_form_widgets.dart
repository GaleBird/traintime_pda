// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:styled_widget/styled_widget.dart';

enum LoginMethod { password, sms }

InputDecoration buildLoginInputDecoration({
  required IconData iconData,
  required String hintText,
  Widget? suffixIcon,
}) => InputDecoration(
  prefixIcon: Icon(iconData),
  hintText: hintText,
  suffixIcon: suffixIcon,
);

class LoginMethodSwitch extends StatelessWidget {
  final LoginMethod method;
  final ValueChanged<LoginMethod> onChanged;

  const LoginMethodSwitch({
    super.key,
    required this.method,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LoginMethod>(
      segments: [
        ButtonSegment(
          value: LoginMethod.password,
          label: Text(FlutterI18n.translate(context, "login.method_password")),
        ),
        ButtonSegment(
          value: LoginMethod.sms,
          label: Text(FlutterI18n.translate(context, "login.method_sms")),
        ),
      ],
      selected: {method},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class PasswordLoginFields extends StatelessWidget {
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final FocusNode accountFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onAccountEditingComplete;
  final VoidCallback onPasswordSubmitted;
  final VoidCallback onToggleVisibility;
  final double fieldSpacing;

  const PasswordLoginFields({
    super.key,
    required this.accountController,
    required this.passwordController,
    required this.accountFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onAccountEditingComplete,
    required this.onPasswordSubmitted,
    required this.onToggleVisibility,
    required this.fieldSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: accountController,
          focusNode: accountFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onAccountEditingComplete(),
          decoration: buildLoginInputDecoration(
            iconData: MingCuteIcons.mgc_user_3_fill,
            hintText: FlutterI18n.translate(context, "login.identity_number"),
          ),
        ).center(),
        SizedBox(height: fieldSpacing),
        TextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onPasswordSubmitted(),
          decoration: buildLoginInputDecoration(
            iconData: MingCuteIcons.mgc_safe_lock_fill,
            hintText: FlutterI18n.translate(context, "login.password"),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ).center(),
      ],
    );
  }
}

class PasswordLoginOptionsRow extends StatelessWidget {
  final VoidCallback onForgotPassword;

  const PasswordLoginOptionsRow({super.key, required this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onForgotPassword,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: colorScheme.primary,
          ),
          child: Text(FlutterI18n.translate(context, "login.forgot_password")),
        ),
      ],
    );
  }
}

class SmsLoginFields extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final int countdownSeconds;
  final VoidCallback? onSendCode;
  final VoidCallback onSubmit;
  final double fieldSpacing;

  const SmsLoginFields({
    super.key,
    required this.phoneController,
    required this.codeController,
    required this.countdownSeconds,
    required this.onSendCode,
    required this.onSubmit,
    required this.fieldSpacing,
  });

  String _sendButtonText(BuildContext context) {
    if (countdownSeconds <= 0) {
      return FlutterI18n.translate(context, "login.send_sms_code");
    }
    return FlutterI18n.translate(
      context,
      "login.send_sms_retry",
      translationParams: {"seconds": countdownSeconds.toString()},
    );
  }

  Widget _buildCodeField(BuildContext context) {
    return TextField(
      controller: codeController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      decoration: buildLoginInputDecoration(
        iconData: MingCuteIcons.mgc_safe_lock_fill,
        hintText: FlutterI18n.translate(context, "login.sms_code"),
      ),
    );
  }

  Widget _buildSendCodeButton(BuildContext context, {required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 44,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12.5),
        ),
        onPressed: countdownSeconds > 0 ? null : onSendCode,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_sendButtonText(context)),
        ),
      ),
    );
  }

  Widget _buildCodeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildCodeField(context)),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: _buildSendCodeButton(context, fullWidth: true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: buildLoginInputDecoration(
            iconData: MingCuteIcons.mgc_phone_fill,
            hintText: FlutterI18n.translate(context, "login.phone_number"),
          ),
        ).center(),
        SizedBox(height: fieldSpacing),
        _buildCodeRow(context),
      ],
    );
  }
}
