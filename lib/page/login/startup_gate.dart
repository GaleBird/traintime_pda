// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watermeter/page/homepage/home.dart';
import 'package:watermeter/page/login/login_window.dart';
import 'package:watermeter/page/public_widget/app_icon.dart';
import 'package:watermeter/repository/gxu_ids/gxu_ca_session.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/preference.dart' as preference;

enum _StartupTarget { home, login }

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final Future<_StartupTarget> _target = _resolveTarget();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupTarget>(
      future: _target,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupSplash();
        }
        if (snapshot.hasError) {
          log.warning("[startup_gate] Startup check failed: ${snapshot.error}");
          return const LoginWindow();
        }
        return switch (snapshot.data) {
          _StartupTarget.home => const HomePage(),
          _StartupTarget.login || null => const LoginWindow(),
        };
      },
    );
  }

  Future<_StartupTarget> _resolveTarget() async {
    final username = preference.getString(preference.Preference.idsAccount);
    final password = preference.getString(preference.Preference.idsPassword);
    if (username.isNotEmpty && password.isNotEmpty) {
      return _StartupTarget.home;
    }

    final cachedPhone = preference.getString(preference.Preference.gxuCaPhone);
    if (cachedPhone.isEmpty) {
      return _StartupTarget.login;
    }

    try {
      final loggedIn = await GxuCASession().isYjsxtLoggedIn();
      return loggedIn ? _StartupTarget.home : _StartupTarget.login;
    } catch (e, s) {
      log.warning("[startup_gate] session check failed: $e\n$s");
      return _StartupTarget.login;
    }
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconWidget(),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
