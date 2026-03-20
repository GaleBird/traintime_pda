// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

class PasswordWrongException implements Exception {
  final String msg;

  const PasswordWrongException({required this.msg});

  @override
  String toString() => 'PasswordWrongException($msg)';
}

class LoginFailedException implements Exception {
  final String msg;

  const LoginFailedException({required this.msg});

  @override
  String toString() => 'LoginFailedException($msg)';
}
