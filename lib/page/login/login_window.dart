// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/login/login_form.dart';

const _gxuBrandRed = Color(0xFFD73A3A);
const _loginCardMaxWidth = 420.0;
const _loginPagePadding = 24.0;
const _loginCardRadius = 32.0;
const _loginHeaderImageWidth = 272.0;
const _loginTopPadding = 18.0;
const _loginBottomPadding = 20.0;
const _loginLandscapeHorizontalPaddingFactor = 0.12;
const _loginLandscapeGap = 48.0;
const _loginLandscapeHeaderPadding = 32.0;
const _loginPortraitSpacing = 18.0;
const _loginAnimationDuration = Duration(milliseconds: 240);

class LoginWindow extends StatelessWidget {
  const LoginWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _resolveOverlayStyle(theme),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: theme.colorScheme.surface,
        resizeToAvoidBottomInset: false,
        body: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  SystemUiOverlayStyle _resolveOverlayStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent);
  }

  Widget _buildBody(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final horizontalPadding = width / height > 1.0
        ? width * _loginLandscapeHorizontalPaddingFactor
        : _loginPagePadding;
    final topPadding = _loginTopPadding;
    final bottomPadding = _loginBottomPadding;
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedPadding(
        duration: _loginAnimationDuration,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: topPadding,
          bottom: bottomPadding,
        ),
        child: AnimatedContainer(
          duration: _loginAnimationDuration,
          curve: Curves.easeOutCubic,
          height:
              (constraints.maxHeight - topPadding - bottomPadding - bottomInset)
                  .clamp(0.0, double.infinity),
          alignment: Alignment.center,
          child: _buildResponsiveContent(context, width: width, height: height),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final header = const _LoginBrandHeader();
    final formCard = const _LoginFormCard();
    if (width / height > 1.0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: header
                .constrained(maxWidth: _loginCardMaxWidth)
                .padding(right: _loginLandscapeHeaderPadding),
          ),
          const SizedBox(width: _loginLandscapeGap),
          Expanded(child: formCard),
        ],
      );
    }
    return AnimatedAlign(
      duration: _loginAnimationDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: OverflowBox(
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const SizedBox(height: _loginPortraitSpacing),
            formCard,
          ],
        ),
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _loginAnimationDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/gxu_name.svg',
        width: _loginHeaderImageWidth,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: _loginAnimationDuration,
      curve: Curves.easeOutCubic,
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: _loginCardMaxWidth),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_loginCardRadius),
        border: Border.all(color: _gxuBrandRed.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const LoginForm(),
    );
  }
}
