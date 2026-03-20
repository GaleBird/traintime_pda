// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

String normalizeChinaPhone(String input) {
  final cleaned = input.replaceAll(RegExp(r"\s+"), "");
  if (cleaned.startsWith("+86")) return cleaned.substring(3);
  if (cleaned.startsWith("86") && cleaned.length == 13) {
    return cleaned.substring(2);
  }
  return cleaned;
}

bool isChinaPhone(String phone) => RegExp(r"^1\d{10}$").hasMatch(phone);
