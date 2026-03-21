// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const AndroidOptions _androidSecureStorageOptions = AndroidOptions();
const IOSOptions _iosSecureStorageOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
  synchronizable: false,
);
const MacOsOptions _macOsSecureStorageOptions = MacOsOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
  synchronizable: false,
);

const FlutterSecureStorage appSecureStorage = FlutterSecureStorage(
  aOptions: _androidSecureStorageOptions,
  iOptions: _iosSecureStorageOptions,
  mOptions: _macOsSecureStorageOptions,
);
