// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watermeter/page/homepage/home.dart';
import 'package:watermeter/page/login/bottom_buttons.dart';
import 'package:watermeter/page/login/login_form_widgets.dart';
import 'package:watermeter/page/login/phone_utils.dart';
import 'package:watermeter/page/login/sms_login_panel.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_classtable_session.dart';
import 'package:watermeter/repository/gxu_ids/gxu_schoolnet_credentials.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/preference.dart' as preference;

const _loginFieldSpacing = 16.0;
const _loginPasswordOptionsSpacing = 10.0;
const _loginPortraitActionSpacing = 8.0;
const _loginLandscapeActionSpacing = 16.0;
const _gxuForgotPasswordUrl =
    "http://ca.gxu.edu.cn:81/zfim/securitycenter/findPwd/index.zf";

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _idsAccountController = TextEditingController();
  final TextEditingController _idsPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final FocusNode _idsAccountFocusNode = FocusNode();
  final FocusNode _idsPasswordFocusNode = FocusNode();

  final GxuCASession _session = GxuCASession();

  LoginMethod _method = LoginMethod.password;
  bool _couldNotView = true;

  @override
  void initState() {
    super.initState();
    _prefillInputs();
    preference.setBool(preference.Preference.isGxuMode, true);
  }

  @override
  void dispose() {
    _idsAccountController.dispose();
    _idsPasswordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _idsAccountFocusNode.dispose();
    _idsPasswordFocusNode.dispose();
    super.dispose();
  }

  void _prefillInputs() {
    final cachedAccount = preference.getString(
      preference.Preference.idsAccount,
    );
    if (cachedAccount.isNotEmpty) {
      _idsAccountController.text = cachedAccount;
    }
    final cachedPhone = preference.getString(preference.Preference.gxuCaPhone);
    if (cachedPhone.isNotEmpty) {
      _phoneController.text = cachedPhone;
    }
  }

  Future<void> _openForgotPassword() async {
    final shouldOpen = await _confirmForgotPasswordOpen();
    if (shouldOpen != true || !mounted) {
      return;
    }
    try {
      final opened = await launchUrl(
        Uri.parse(_gxuForgotPasswordUrl),
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) return;
      showToast(
        context: context,
        msg: FlutterI18n.translate(
          context,
          "login.failed_open_forgot_password",
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showToast(
        context: context,
        msg: FlutterI18n.translate(
          context,
          "login.failed_open_forgot_password",
        ),
      );
    }
  }

  Future<bool?> _confirmForgotPasswordOpen() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, "login.forgot_password")),
        content: Text(
          FlutterI18n.translate(
            context,
            "login.forgot_password_security_warning",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(FlutterI18n.translate(context, "cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(FlutterI18n.translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLoginFromKeyboard() async {
    FocusScope.of(context).unfocus();
    await login();
  }

  ProgressDialog _buildProgressDialog() {
    final pd = ProgressDialog(context: context);
    pd.show(
      msg: FlutterI18n.translate(context, "login.on_login_progress"),
      max: 100,
      hideValue: true,
      completed: Completed(
        completedMsg: FlutterI18n.translate(context, "login.complete_login"),
      ),
    );
    return pd;
  }

  Future<void> _setLoginMethod(LoginMethod method) async {
    setState(() => _method = method);
    await _session.clearCookieJar();
  }

  Future<void> login() async {
    if (_method == LoginMethod.password) {
      if (_idsPasswordController.text.isEmpty) {
        showToast(
          context: context,
          msg: FlutterI18n.translate(
            context,
            "login.incorrect_password_pattern",
          ),
        );
        return;
      }
    } else {
      final phone = normalizeChinaPhone(_phoneController.text);
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
      if (_smsCodeController.text.isEmpty) {
        showToast(
          context: context,
          msg: FlutterI18n.translate(context, "login.sms_code_required"),
        );
        return;
      }
    }

    final pd = _buildProgressDialog();
    try {
      if (_method == LoginMethod.password) {
        await _loginWithPassword(pd);
      } else {
        await _loginWithSms(pd);
      }
    } catch (e, s) {
      _handleLoginError(pd, e, s);
    }
  }

  Future<void> _loginWithPassword(ProgressDialog pd) async {
    final classtableSession = GxuClasstableSession(caSession: _session);
    await _session.login(
      username: _idsAccountController.text,
      password: _idsPasswordController.text,
      onResponse: (number, status) =>
          pd.update(msg: FlutterI18n.translate(context, status), value: number),
    );
    if (!mounted) return;

    await syncGxuSchoolnetAccountFromPasswordLogin(_idsAccountController.text);
    await preference.setString(
      preference.Preference.idsPassword,
      _idsPasswordController.text,
    );
    await _finishPostLogin(pd, classtableSession);
  }

  Future<void> _loginWithSms(ProgressDialog pd) async {
    final phone = normalizeChinaPhone(_phoneController.text);
    final classtableSession = GxuClasstableSession(caSession: _session);
    await _session.loginWithSms(
      mobile: phone,
      code: _smsCodeController.text,
      onResponse: (number, status) =>
          pd.update(msg: FlutterI18n.translate(context, status), value: number),
    );
    if (!mounted) return;
    await handleGxuSmsLoginSuccess(phone);
    await _finishPostLogin(pd, classtableSession);
  }

  Future<void> _finishPostLogin(
    ProgressDialog pd,
    GxuClasstableSession classtableSession,
  ) async {
    await preference.setBool(preference.Preference.isGxuMode, true);
    await preference.setBool(preference.Preference.role, true);
    await preference.setBool(
      preference.Preference.isUserDefinedSemester,
      false,
    );
    await preference.setString(
      preference.Preference.currentSemester,
      await classtableSession.getCurrentSemesterCode(),
    );
    _completeLogin(pd);
  }

  void _completeLogin(ProgressDialog pd) {
    if (!mounted) return;
    if (pd.isOpen()) pd.close();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _handleLoginError(ProgressDialog pd, Object e, StackTrace s) {
    if (pd.isOpen()) {
      pd.close();
    }
    if (!mounted) return;

    if (e is PasswordWrongException) {
      showToast(context: context, msg: e.msg);
      return;
    }
    if (e is LoginFailedException) {
      showToast(context: context, msg: e.msg);
      return;
    }
    if (e is DioException) {
      final message = _formatDioMessage(e);
      showToast(context: context, msg: message);
      return;
    }

    log.warning("[login_form][login] Login failed: $e\n$s");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().substring(0, min(e.toString().length, 120))),
      ),
    );
    showToast(
      context: context,
      msg: FlutterI18n.translate(context, "login.failed_login_other"),
    );
  }

  String _formatDioMessage(DioException e) {
    final message = e.message;
    if (message != null) {
      return FlutterI18n.translate(
        context,
        "login.failed_login_with_message",
        translationParams: {"message": message.toString()},
      );
    }
    final response = e.response;
    if (response == null) {
      return FlutterI18n.translate(
        context,
        "login.failed_login_cannot_connect_to_server",
      );
    }
    return FlutterI18n.translate(
      context,
      "login.failed_login_with_code",
      translationParams: {"code": response.statusCode.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width / size.height > 1.0;
    const fieldSpacing = _loginFieldSpacing;
    final actionSpacing = isLandscape
        ? _loginLandscapeActionSpacing
        : _loginPortraitActionSpacing;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginMethodSwitch(
          method: _method,
          onChanged: (method) => _setLoginMethod(method),
        ),
        SizedBox(height: fieldSpacing),
        _buildMethodFields(fieldSpacing),
        SizedBox(height: actionSpacing),
        _buildLoginButton(context),
        const SizedBox(height: 8.0),
        const ButtomButtons(),
      ],
    ).constrained(maxWidth: 400);
  }

  Widget _buildMethodFields(double fieldSpacing) {
    if (_method == LoginMethod.password) {
      return Column(
        children: [
          PasswordLoginFields(
            accountController: _idsAccountController,
            passwordController: _idsPasswordController,
            accountFocusNode: _idsAccountFocusNode,
            passwordFocusNode: _idsPasswordFocusNode,
            obscurePassword: _couldNotView,
            fieldSpacing: fieldSpacing,
            onAccountEditingComplete: () =>
                _idsPasswordFocusNode.requestFocus(),
            onPasswordSubmitted: _submitLoginFromKeyboard,
            onToggleVisibility: () {
              setState(() {
                _couldNotView = !_couldNotView;
              });
            },
          ),
          const SizedBox(height: _loginPasswordOptionsSpacing),
          PasswordLoginOptionsRow(onForgotPassword: _openForgotPassword),
        ],
      );
    }
    return SmsLoginPanel(
      session: _session,
      phoneController: _phoneController,
      codeController: _smsCodeController,
      fieldSpacing: fieldSpacing,
      onSubmit: _submitLoginFromKeyboard,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        maximumSize: const Size(double.infinity, 64),
      ),
      onPressed: login,
      child: Text(
        FlutterI18n.translate(context, "login.login"),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      ),
    );
  }
}
