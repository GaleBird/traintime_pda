// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

final log = TalkerFlutter.init();
final logDioAdapter = TalkerDioLogger(
  talker: log,
  settings: const TalkerDioLoggerSettings(
    enabled: kDebugMode,
    printRequestData: false,
    printRequestHeaders: false,
    printResponseData: false,
    printResponseHeaders: false,
    printResponseMessage: false,
    printErrorData: false,
    printErrorHeaders: false,
    printErrorMessage: true,
    hiddenHeaders: {"authorization", "cookie", "set-cookie"},
  ),
);

class PDACatcher2Logger extends Catcher2Logger {
  @override
  void info(String message) {
    log.info('Custom Catcher2 Logger | Info | $message');
  }

  @override
  void fine(String message) {
    log.info('Custom Catcher2 Logger | Fine | $message');
  }

  @override
  void warning(String message) {
    log.warning('Custom Catcher2 Logger | Warning | $message');
  }

  @override
  void severe(String message) {
    log.error('Custom Catcher2 Logger | Servere | $message');
  }
}
