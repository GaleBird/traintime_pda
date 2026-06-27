// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// PigHub API session. https://www.pighub.top

import 'dart:math' as math;
import 'dart:isolate';

import 'package:dio/dio.dart';

const _base = "https://www.pighub.top";
const _latestImagesPath = "/api/images?sort=2";
const _connectTimeout = Duration(seconds: 10);
const _receiveTimeout = Duration(seconds: 30);

Dio get _dio => Dio(
  BaseOptions(connectTimeout: _connectTimeout, receiveTimeout: _receiveTimeout),
);

final math.Random _random = math.Random();
List<PigHubImage>? _cachedImages;

class PigHubImage {
  final String id;
  final String thumbnail; // relative path, e.g. /images/xxx.jpg
  final String title;
  final String imageType; // "static" or "gif"

  const PigHubImage({
    required this.id,
    required this.thumbnail,
    required this.title,
    required this.imageType,
  });

  factory PigHubImage.fromJson(Map<String, dynamic> json) {
    final filename = _readRequiredField(json, "filename");
    return PigHubImage(
      id: _readRequiredField(json, "id"),
      thumbnail: _readRequiredField(json, "image_url"),
      title: _readRequiredField(json, "title"),
      imageType: _detectImageType(filename),
    );
  }

  /// Full URL of the image.
  String get url => "$_base$thumbnail";
}

List<dynamic> _extractImageList(dynamic data) {
  if (data is Map<String, dynamic> && data["data"] is List<dynamic>) {
    return data["data"] as List<dynamic>;
  }
  throw const FormatException("Invalid PigHub response format.");
}

String _detectImageType(String filename) {
  return filename.toLowerCase().endsWith(".gif") ? "gif" : "static";
}

String _readRequiredField(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException("Missing PigHub image field: $key");
  }

  final text = value.toString();
  if (text.trim().isEmpty) {
    throw FormatException("Empty PigHub image field: $key");
  }
  return text;
}

List<PigHubImage> _parsePigImages(dynamic data) {
  final List<dynamic> images = _extractImageList(data);
  if (images.isEmpty) {
    throw Exception("PigHub returned an empty image list.");
  }

  return images
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException("Invalid PigHub image item format.");
        }
        return PigHubImage.fromJson(item);
      })
      .toList(growable: false);
}

Future<List<PigHubImage>> _getAllPigs({bool forceRefresh = false}) async {
  if (!forceRefresh && _cachedImages != null && _cachedImages!.isNotEmpty) {
    return _cachedImages!;
  }

  final response = await _dio.get("$_base$_latestImagesPath");

  // Parse in a background isolate to avoid UI jank on large payloads.
  final parsed = await Isolate.run(() => _parsePigImages(response.data));
  _cachedImages = parsed;
  return parsed;
}

/// Fetches one image at random.
///
/// It caches PigHub's full image list in memory, then picks randomly from cache
/// to avoid repeatedly downloading and parsing large responses.
Future<PigHubImage> getRandomPig({bool forceRefresh = false}) async {
  final images = await _getAllPigs(forceRefresh: forceRefresh);
  final index = _random.nextInt(images.length);
  return images[index];
}
