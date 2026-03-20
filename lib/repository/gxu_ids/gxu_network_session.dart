// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:get/get.dart' hide Response;
import 'package:watermeter/model/gxu_ids/gxu_network_usage.dart';
import 'package:watermeter/page/public_widget/captcha_input_dialog.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_cache.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_parser.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as prefs;

const _maxCaptchaAttempts = 3;

Rxn<GxuNetworkUsage?> gxuNetworkInfo = Rxn();
Rx<SessionState> gxuNetworkStatus = SessionState.none.obs;
final gxuNetworkRefreshing = false.obs;
final gxuNetworkError = "".obs;

Future<void> loadCachedGxuNetworkUsage() async {
  final usage = await loadGxuNetworkUsageCache();
  if (usage == null) {
    return;
  }
  gxuNetworkInfo.value = usage;
  gxuNetworkStatus.value = SessionState.fetched;
  gxuNetworkError.value = "";
}

Future<void> updateGxuNetworkUsage({
  Future<String> Function(List<int>)? captchaFunction,
}) async {
  if (gxuNetworkRefreshing.value ||
      gxuNetworkStatus.value == SessionState.fetching) {
    return;
  }
  log.info("[GxuNetworkSession] Ready to fetch GXU network usage.");
  await GxuNetworkSession().getNetworkUsage(captchaFunction: captchaFunction);
}

class GxuNetworkSession {
  static const _baseUrl = "http://self.gxu.edu.cn";

  final _parser = GxuNetworkParser();
  final PersistCookieJar _cookieJar = PersistCookieJar(
    persistSession: true,
    storage: FileStorage("${supportPath.path}/cookie/gxu_network"),
  );

  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              HttpHeaders.userAgentHeader:
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/132.0.0.0 Safari/537.36",
            },
            followRedirects: false,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 400,
          ),
        )
        ..interceptors.add(CookieManager(_cookieJar))
        ..interceptors.add(logDioAdapter)
        ..options.connectTimeout = const Duration(seconds: 10)
        ..options.receiveTimeout = const Duration(seconds: 30);

  Future<void> clearCookieJar() => _cookieJar.deleteAll();

  Future<void> getNetworkUsage({
    required Future<String> Function(List<int>)? captchaFunction,
  }) async {
    final hasCache = gxuNetworkInfo.value != null;
    _beginRefresh(hasCache: hasCache);

    final password = prefs.getString(prefs.Preference.schoolNetQueryPassword);
    if (password.isEmpty) {
      _setError("school_net.empty_password", hasCache: hasCache);
      gxuNetworkRefreshing.value = false;
      return;
    }

    final username = prefs.getString(prefs.Preference.idsAccount);
    if (username.isEmpty) {
      _setError("school_net.gxu.account_missing", hasCache: hasCache);
      gxuNetworkRefreshing.value = false;
      return;
    }
    try {
      final dashboard = await _dio.get("/dashboard");
      if (_requiresLogin(dashboard)) {
        final loggedIn = await _login(
          username: username,
          password: password,
          captchaFunction: captchaFunction,
        );
        if (!loggedIn) {
          return;
        }
      }
      await _fetchDashboard(username);
    } on FormatException {
      _setError("school_net.gxu.page_changed", hasCache: hasCache);
    } catch (error, stackTrace) {
      log.error(
        "[GxuNetworkSession] Failed to fetch dashboard.",
        error,
        stackTrace,
      );
      _setError("school_net.error_fetch", hasCache: hasCache);
    } finally {
      gxuNetworkRefreshing.value = false;
    }
  }

  Future<bool> _login({
    required String username,
    required String password,
    required Future<String> Function(List<int>)? captchaFunction,
  }) async {
    final directLogin = await _tryPasswordOnlyLogin(
      username: username,
      password: password,
    );
    if (directLogin.$1) {
      return true;
    }
    if (_isPasswordError(directLogin.$2)) {
      _setError(
        "school_net.wrong_password",
        hasCache: gxuNetworkInfo.value != null,
      );
      return false;
    }

    final captchaLogin = await _tryCaptchaLogin(
      username: username,
      password: password,
      captchaFunction: captchaFunction,
    );
    if (captchaLogin.$1) {
      return true;
    }
    if (_isPasswordError(captchaLogin.$2)) {
      _setError(
        "school_net.wrong_password",
        hasCache: gxuNetworkInfo.value != null,
      );
      return false;
    }
    _setError(captchaLogin.$2, hasCache: gxuNetworkInfo.value != null);
    return false;
  }

  Future<void> _fetchDashboard(String username) async {
    final response = await _dio.get("/dashboard");
    if (_requiresLogin(response)) {
      throw const FormatException("GXU dashboard still requires login.");
    }
    final usage = _parser.parseDashboard(
      html: response.data.toString(),
      account: username,
      refreshedAt: DateTime.now(),
    );
    gxuNetworkInfo.value = usage;
    await saveGxuNetworkUsageCache(usage);
    gxuNetworkError.value = "";
    gxuNetworkStatus.value = SessionState.fetched;
  }

  Future<List<int>> _fetchCaptchaBytes() async {
    final response = await _dio.get<List<int>>(
      "/login/randomCode",
      queryParameters: {"t": DateTime.now().millisecondsSinceEpoch.toString()},
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException("GXU captcha image is empty.");
    }
    return bytes;
  }

  Future<String?> _resolveCaptchaCode({
    required int attempt,
    required List<int> bytes,
    required Future<String> Function(List<int>)? captchaFunction,
  }) async {
    if (attempt == _maxCaptchaAttempts) {
      if (captchaFunction == null) {
        return null;
      }
      return captchaFunction(bytes);
    }
    return DigitCaptchaClientProvider.infer(DigitCaptchaType.zfw, bytes);
  }

  Future<String> _readLoginError() async {
    final loginPage = await _dio.get("/login/");
    final message = _parser.extractLoginError(loginPage.data.toString());
    if (message == null || message.isEmpty) {
      return "school_net.gxu.login_failed";
    }
    if (message.contains("验证码")) {
      return "school_net.captcha_failed";
    }
    return message;
  }

  Future<(bool, String)> _tryPasswordOnlyLogin({
    required String username,
    required String password,
  }) async {
    final loginPage = await _dio.get("/login/");
    final formAction = _parser.extractFormAction(loginPage.data.toString());
    await _dio.post(
      _normalizeAction(formAction),
      data: {
        "account": username,
        "password": password,
        "foo": "",
        "bar": "",
        "submit": "登录",
      },
    );
    final dashboard = await _dio.get("/dashboard");
    if (!_requiresLogin(dashboard)) {
      return (true, "");
    }
    return (false, await _readLoginError());
  }

  Future<(bool, String)> _tryCaptchaLogin({
    required String username,
    required String password,
    required Future<String> Function(List<int>)? captchaFunction,
  }) async {
    var lastError = "school_net.gxu.login_failed";
    for (var attempt = 1; attempt <= _maxCaptchaAttempts; attempt++) {
      final loginPage = await _dio.get("/login/");
      final loginHtml = loginPage.data.toString();
      final formAction = _parser.extractFormAction(loginHtml);
      final checkcode = _parser.extractCheckCode(loginHtml);
      final captchaBytes = await _fetchCaptchaBytes();
      final captchaCode = await _resolveCaptchaCode(
        attempt: attempt,
        bytes: captchaBytes,
        captchaFunction: captchaFunction,
      );
      if (captchaCode == null || captchaCode.isEmpty) {
        lastError = "school_net.captcha_failed";
        continue;
      }
      await _dio.post(
        _normalizeAction(formAction),
        data: {
          "account": username,
          "password": password,
          "code": captchaCode,
          "checkcode": checkcode,
          "foo": "",
          "bar": "",
          "submit": "登录",
        },
      );
      final dashboard = await _dio.get("/dashboard");
      if (!_requiresLogin(dashboard)) {
        return (true, "");
      }
      lastError = await _readLoginError();
      if (_isPasswordError(lastError)) {
        return (false, lastError);
      }
    }
    return (false, lastError);
  }

  bool _isPasswordError(String message) {
    return message.contains("账号") || message.contains("密码");
  }

  bool _requiresLogin(Response<dynamic> response) {
    final location = response.headers.value(HttpHeaders.locationHeader) ?? "";
    if (location.contains("/login")) {
      return true;
    }
    return _parser.isLoginPage(response.data.toString());
  }

  String _normalizeAction(String action) {
    if (action.startsWith("http")) {
      return action;
    }
    final uri = Uri.parse(_baseUrl).resolve(action);
    return uri.path.isEmpty ? "/" : uri.path;
  }

  void _beginRefresh({required bool hasCache}) {
    gxuNetworkRefreshing.value = true;
    gxuNetworkError.value = "";
    if (!hasCache) {
      gxuNetworkStatus.value = SessionState.fetching;
    }
  }

  void _setError(String value, {required bool hasCache}) {
    gxuNetworkError.value = value;
    gxuNetworkStatus.value = hasCache
        ? SessionState.fetched
        : SessionState.error;
  }
}
