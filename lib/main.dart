// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Intro of the watermeter program.

import 'dart:io';
import 'dart:ui';

import 'package:catcher_2/catcher_2.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/app_startup.dart';
import 'package:watermeter/repository/app_brand.dart';
import 'package:watermeter/controller/theme_controller.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/page/login/startup_gate.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

void main() async {
  // Make sure the library is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  log.info("${AppBrand.appName} codebase bootstrapping.");

  await initializeAppBootstrap();

  Catcher2(
    rootWidget: const MyApp(),
    debugConfig: preference.catcherOptions,
    releaseConfig: preference.catcherOptions,
    navigatorKey: preference.debuggerKey,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeController appTheme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    warmUpAppAfterFirstFrame();
    if (Platform.isIOS) HomeWidget.setAppGroupId(preference.appId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final screenWidth =
          PlatformDispatcher.instance.views.first.physicalSize.width /
          PlatformDispatcher.instance.views.first.devicePixelRatio;
      log.info("Screen width: $screenWidth.");
      if (screenWidth < 480) {
        log.info("Vertical vision mode disabled!");
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (c) => MaterialApp(
        localizationsDelegates: [
          c.getI18nDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('en', 'US'),
        ],
        debugShowCheckedModeBanner: false,
        scrollBehavior: MyCustomScrollBehavior(),
        navigatorKey: preference.debuggerKey,
        title: AppBrand.appName,
        theme: FlexThemeData.light(
          colors: c.color.first,
          usedColors: 1,
          surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
          blendLevel: 2,
          tabBarStyle: FlexTabBarStyle.forAppBar,
          subThemesData: const FlexSubThemesData(
            interactionEffects: true,
            tintedDisabledControls: true,
            blendOnLevel: 8,
            useM2StyleDividerInM3: true,
            defaultRadius: 12.0,
            elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
            elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
            outlinedButtonOutlineSchemeColor: SchemeColor.primary,
            toggleButtonsBorderSchemeColor: SchemeColor.primary,
            segmentedButtonSchemeColor: SchemeColor.primary,
            segmentedButtonBorderSchemeColor: SchemeColor.primary,
            unselectedToggleIsColored: true,
            sliderValueTinted: true,
            inputDecoratorSchemeColor: SchemeColor.primary,
            inputDecoratorIsFilled: true,
            inputDecoratorContentPadding: EdgeInsetsDirectional.fromSTEB(
              12,
              16,
              12,
              12,
            ),
            inputDecoratorBackgroundAlpha: 7,
            inputDecoratorBorderSchemeColor: SchemeColor.primary,
            inputDecoratorBorderType: FlexInputBorderType.outline,
            inputDecoratorRadius: 8.0,
            inputDecoratorUnfocusedBorderIsColored: true,
            inputDecoratorBorderWidth: 1.0,
            inputDecoratorFocusedBorderWidth: 2.0,
            inputDecoratorPrefixIconSchemeColor:
                SchemeColor.onPrimaryFixedVariant,
            inputDecoratorSuffixIconSchemeColor: SchemeColor.primary,
            fabUseShape: true,
            fabAlwaysCircular: true,
            fabSchemeColor: SchemeColor.secondary,
            popupMenuRadius: 8.0,
            popupMenuElevation: 3.0,
            alignedDropdown: true,
            dialogBackgroundSchemeColor: SchemeColor.secondaryContainer,
            drawerIndicatorRadius: 12.0,
            drawerIndicatorSchemeColor: SchemeColor.primary,
            bottomNavigationBarMutedUnselectedLabel: false,
            bottomNavigationBarMutedUnselectedIcon: false,
            menuRadius: 8.0,
            menuElevation: 3.0,
            menuBarRadius: 0.0,
            menuBarElevation: 2.0,
            menuBarShadowColor: Color(0x00000000),
            searchBarElevation: 1.0,
            searchViewElevation: 1.0,
            searchUseGlobalShape: true,
            navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
            navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
            navigationBarIndicatorSchemeColor: SchemeColor.primary,
            navigationBarIndicatorRadius: 12.0,
            navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
            navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
            navigationRailUseIndicator: true,
            navigationRailIndicatorSchemeColor: SchemeColor.primary,
            navigationRailIndicatorOpacity: 1.00,
            navigationRailIndicatorRadius: 12.0,
            navigationRailBackgroundSchemeColor: SchemeColor.surface,
            navigationRailLabelType: NavigationRailLabelType.all,
          ),
          keyColors: const FlexKeyColors(keepPrimary: true),
          tones: FlexSchemeVariant.jolly.tones(Brightness.light),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme: const CupertinoThemeData(
            applyThemeToAll: true,
          ),
        ).useSystemChineseFont(Brightness.light),
        darkTheme: FlexThemeData.dark(
          colors: c.color.last,
          usedColors: 1,
          surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
          blendLevel: 2,
          tabBarStyle: FlexTabBarStyle.forAppBar,
          subThemesData: const FlexSubThemesData(
            interactionEffects: true,
            tintedDisabledControls: true,
            blendOnLevel: 10,
            blendOnColors: true,
            useM2StyleDividerInM3: true,
            defaultRadius: 12.0,
            elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
            elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
            outlinedButtonOutlineSchemeColor: SchemeColor.primary,
            toggleButtonsBorderSchemeColor: SchemeColor.primary,
            segmentedButtonSchemeColor: SchemeColor.primary,
            segmentedButtonBorderSchemeColor: SchemeColor.primary,
            unselectedToggleIsColored: true,
            sliderValueTinted: true,
            inputDecoratorSchemeColor: SchemeColor.primary,
            inputDecoratorIsFilled: true,
            inputDecoratorContentPadding: EdgeInsetsDirectional.fromSTEB(
              12,
              16,
              12,
              12,
            ),
            inputDecoratorBackgroundAlpha: 40,
            inputDecoratorBorderSchemeColor: SchemeColor.primary,
            inputDecoratorBorderType: FlexInputBorderType.outline,
            inputDecoratorRadius: 8.0,
            inputDecoratorUnfocusedBorderIsColored: true,
            inputDecoratorBorderWidth: 1.0,
            inputDecoratorFocusedBorderWidth: 2.0,
            inputDecoratorPrefixIconSchemeColor: SchemeColor.primaryFixed,
            inputDecoratorSuffixIconSchemeColor: SchemeColor.primary,
            fabUseShape: true,
            fabAlwaysCircular: true,
            fabSchemeColor: SchemeColor.secondary,
            popupMenuRadius: 8.0,
            popupMenuElevation: 3.0,
            alignedDropdown: true,
            drawerIndicatorRadius: 12.0,
            drawerIndicatorSchemeColor: SchemeColor.primary,
            bottomNavigationBarMutedUnselectedLabel: false,
            bottomNavigationBarMutedUnselectedIcon: false,
            menuRadius: 8.0,
            menuElevation: 3.0,
            menuBarRadius: 0.0,
            menuBarElevation: 2.0,
            menuBarShadowColor: Color(0x00000000),
            searchBarElevation: 1.0,
            searchViewElevation: 1.0,
            searchUseGlobalShape: true,
            navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
            navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
            navigationBarIndicatorSchemeColor: SchemeColor.primary,
            navigationBarIndicatorRadius: 12.0,
            navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
            navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
            navigationRailUseIndicator: true,
            navigationRailIndicatorSchemeColor: SchemeColor.primary,
            navigationRailIndicatorOpacity: 1.00,
            navigationRailIndicatorRadius: 12.0,
            navigationRailBackgroundSchemeColor: SchemeColor.surface,
            navigationRailLabelType: NavigationRailLabelType.all,
          ),
          keyColors: const FlexKeyColors(),
          tones: FlexSchemeVariant.jolly.tones(Brightness.dark),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme: const CupertinoThemeData(
            applyThemeToAll: true,
          ),
        ).useSystemChineseFont(Brightness.dark),
        themeMode: c.colorState,
        home: DefaultTextStyle.merge(
          style: const TextStyle(textBaseline: TextBaseline.ideographic),
          child: const StartupGate(),
        ),
        builder: (context, widget) {
          Catcher2.addDefaultErrorWidget(
            showStacktrace: true,
            title: "Unexpected problem:P",
            description: "An unexpected behaviour occured!",
            maxWidthForSmallMode: 150,
          );
          if (widget != null) return widget;
          throw StateError('widget is null');
        },
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
