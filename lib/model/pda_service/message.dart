// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

class UpdateMessage {
  const UpdateMessage({
    required this.code,
    required this.update,
    required this.ioslink,
    required this.github,
    required this.fdroid,
  });

  final String code;
  final List<String> update;
  final String ioslink;
  final String github;
  final String fdroid;
}
