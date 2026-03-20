import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart';
import 'package:synchronized/synchronized.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';

class GxuCASession {
  static const caBase = "https://ca.gxu.edu.cn:8443/zfca";
  static const yjsxtBase = "https://yjsxt.gxu.edu.cn/tp";
  static const yjsxtService = "$yjsxtBase/";
  static const _smsSendPath = "$caBase/v2/services/sedsms";
  static final Lock _lock = Lock();

  final PersistCookieJar cookieJar = PersistCookieJar(
    persistSession: true,
    storage: FileStorage("${supportPath.path}/cookie/gxu"),
  );

  late final Dio dio =
      Dio(
          BaseOptions(
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              HttpHeaders.userAgentHeader:
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/132.0.0.0 Safari/537.36",
            },
          ),
        )
        ..interceptors.add(CookieManager(cookieJar))
        ..interceptors.add(logDioAdapter)
        ..options.connectTimeout = const Duration(seconds: 10)
        ..options.receiveTimeout = const Duration(seconds: 30)
        ..options.followRedirects = false
        ..options.validateStatus = (status) =>
            status != null && status >= 200 && status < 400;

  Future<void> clearCookieJar() => cookieJar.deleteAll();

  Future<bool> isYjsxtLoggedIn() => _lock.synchronized(_isLoggedIn);

  Future<void> ensureYjsxtLoggedIn({
    required String username,
    required String password,
  }) async {
    await _lock.synchronized(() async {
      if (await _isLoggedIn()) {
        return;
      }
      if (username.isEmpty || password.isEmpty) {
        throw const LoginFailedException(msg: "缺少账号或密码，请在登录页重新登录。");
      }
      await _loginInternal(username: username, password: password);
    });
  }

  Future<void> login({
    required String username,
    required String password,
    void Function(int, String)? onResponse,
  }) => _lock.synchronized(
    () => _loginInternal(
      username: username,
      password: password,
      onResponse: onResponse,
    ),
  );

  Future<void> sendSmsCode({required String mobile}) async {
    await dio.get(_buildLoginUrl());
    final response = await dio.get(
      _smsSendPath,
      queryParameters: {"mobile": mobile},
    );
    final result = response.data.toString().trim();
    if (result == "success") {
      return;
    }
    throw LoginFailedException(msg: _formatSmsSendError(result));
  }

  Future<void> loginWithSms({
    required String mobile,
    required String code,
    void Function(int, String)? onResponse,
  }) => _lock.synchronized(
    () => _loginWithSmsInternal(
      mobile: mobile,
      code: code,
      onResponse: onResponse,
    ),
  );

  Future<void> _loginWithSmsInternal({
    required String mobile,
    required String code,
    void Function(int, String)? onResponse,
  }) async {
    onResponse?.call(10, "login_process.ready_page");
    final loginUrl = _buildLoginUrl();
    final loginPage = await dio.get(loginUrl);
    final execution = _extractExecution(loginPage.data.toString());
    if (execution.isEmpty) {
      throw const LoginFailedException(msg: "广西大学登录页缺少 execution。");
    }
    onResponse?.call(30, "login_process.get_encrypt");
    final pubKey = await _fetchPublicKey();
    final encryptedCode = _encryptPassword(
      password: code,
      modulus: pubKey.modulus,
      exponent: pubKey.exponent,
    );
    onResponse?.call(50, "login_process.ready_login");
    final response = await dio.post(
      loginUrl,
      data: {
        "username": mobile,
        "mobileCode": code,
        "password": encryptedCode,
        "execution": execution,
        "_eventId": "submit",
      },
      options: Options(headers: {HttpHeaders.refererHeader: loginUrl}),
    );
    onResponse?.call(80, "login_process.after_process");
    await _finishLogin(response);
  }

  Future<void> _loginInternal({
    required String username,
    required String password,
    void Function(int, String)? onResponse,
  }) async {
    await clearCookieJar();
    onResponse?.call(10, "login_process.ready_page");
    final loginUrl = _buildLoginUrl();
    final loginPage = await dio.get(loginUrl);
    final execution = _extractExecution(loginPage.data.toString());
    if (execution.isEmpty) {
      throw const LoginFailedException(msg: "广西大学登录页缺少 execution。");
    }
    if (await _needsCaptcha()) {
      throw const LoginFailedException(msg: "广西大学统一认证当前要求验证码。");
    }
    onResponse?.call(30, "login_process.get_encrypt");
    final pubKey = await _fetchPublicKey();
    final encryptedPassword = _encryptPassword(
      password: password,
      modulus: pubKey.modulus,
      exponent: pubKey.exponent,
    );
    onResponse?.call(50, "login_process.ready_login");
    final response = await dio.post(
      loginUrl,
      data: {
        "username": username,
        "password": encryptedPassword,
        "execution": execution,
        "_eventId": "submit",
        "rememberMe": "true",
      },
      options: Options(headers: {HttpHeaders.refererHeader: loginUrl}),
    );
    onResponse?.call(80, "login_process.after_process");
    await _finishLogin(response);
  }

  Future<bool> _isLoggedIn() async {
    if (!await _hasSessionCookies()) {
      return false;
    }
    final response = await dio.get("$yjsxtBase/view?m=up");
    if (response.headers.value(HttpHeaders.locationHeader) != null) {
      return false;
    }
    return _isPortalHtml(response.data.toString());
  }

  Future<bool> _hasSessionCookies() async {
    final portalCookies = await cookieJar.loadForRequest(Uri.parse(yjsxtBase));
    if (portalCookies.isNotEmpty) {
      return true;
    }
    final loginCookies = await cookieJar.loadForRequest(Uri.parse(caBase));
    return loginCookies.isNotEmpty;
  }

  String _buildLoginUrl() {
    return "$caBase/login?service=${Uri.encodeComponent(yjsxtService)}";
  }

  String _extractExecution(String html) {
    return parse(
          html,
        ).querySelector('input[name="execution"]')?.attributes["value"] ??
        "";
  }

  Future<bool> _needsCaptcha() async {
    final response = await dio.get("$caBase/v2/getKaptchaStatus");
    return response.data.toString().contains("true");
  }

  Future<_GxuPublicKey> _fetchPublicKey() async {
    final response = await dio.get("$caBase/v2/getPubKey");
    final data = response.data as Map<String, dynamic>;
    return _GxuPublicKey(
      modulus: data["modulus"]?.toString() ?? "",
      exponent: data["exponent"]?.toString() ?? "",
    );
  }

  String _encryptPassword({
    required String password,
    required String modulus,
    required String exponent,
  }) {
    final reversed = password.split("").reversed.join();
    final paddedData = List<int>.from(reversed.codeUnits);
    final modulusValue = BigInt.parse(modulus, radix: 16);
    final exponentValue = BigInt.parse(exponent, radix: 16);
    final chunkSize = _resolveChunkSize(modulus);
    while (paddedData.length % chunkSize != 0) {
      paddedData.add(0);
    }
    final blocks = <String>[];
    for (var offset = 0; offset < paddedData.length; offset += chunkSize) {
      blocks.add(
        _encryptChunk(
          paddedData: paddedData,
          offset: offset,
          chunkSize: chunkSize,
          modulus: modulusValue,
          exponent: exponentValue,
        ),
      );
    }
    return blocks.join(" ");
  }

  int _resolveChunkSize(String modulus) {
    final normalized = modulus.length.isOdd ? "0$modulus" : modulus;
    return normalized.length ~/ 2 - 2;
  }

  String _encryptChunk({
    required List<int> paddedData,
    required int offset,
    required int chunkSize,
    required BigInt modulus,
    required BigInt exponent,
  }) {
    var block = BigInt.zero;
    var shift = 0;
    for (var index = 0; index < chunkSize; index += 2) {
      final low = paddedData[offset + index];
      final high = index + 1 < chunkSize ? paddedData[offset + index + 1] : 0;
      final digit = low + (high << 8);
      block |= BigInt.from(digit) << shift;
      shift += 16;
    }
    return _toDigitHex(block.modPow(exponent, modulus));
  }

  String _toDigitHex(BigInt value) {
    final hex = value.toRadixString(16);
    final remainder = hex.length % 4;
    if (remainder == 0) {
      return hex;
    }
    return "${"0" * (4 - remainder)}$hex";
  }

  Future<void> _finishLogin(Response response) async {
    var next = response.headers.value(HttpHeaders.locationHeader);
    if (next == null) {
      _throwLoginError(response.data.toString());
    }
    while (next != null) {
      final current = Uri.parse(caBase).resolve(next).toString();
      response = await dio.get(current);
      next = response.headers.value(HttpHeaders.locationHeader);
    }
    final portal = await dio.get("$yjsxtBase/view?m=up");
    if (!_isPortalHtml(portal.data.toString())) {
      throw const LoginFailedException(msg: "广西大学研究生系统登录状态校验失败。");
    }
  }

  bool _isPortalHtml(String html) {
    return html.contains("研究生综合管理系统") &&
        html.contains('perm_item_url="yjs/py/pkgl/ckkbOfYjs"');
  }

  String _formatSmsSendError(String result) {
    if (result == "valid") {
      return "短信服务要求图形验证码校验。";
    }
    if (result == "unbind") {
      return "该手机号未绑定统一身份认证账户。";
    }
    if (result.isEmpty) {
      return "短信验证码发送失败。";
    }
    return "短信验证码发送失败：$result";
  }

  Never _throwLoginError(String html) {
    final text = parse(html).body?.text.replaceAll(RegExp(r"\s+"), " ").trim();
    if (text != null && text.contains("用户名或密码")) {
      throw const PasswordWrongException(msg: "用户名或密码有误");
    }
    throw LoginFailedException(msg: text?.substring(0, 40) ?? "登录失败");
  }
}

class _GxuPublicKey {
  final String modulus;
  final String exponent;

  const _GxuPublicKey({required this.modulus, required this.exponent});
}
