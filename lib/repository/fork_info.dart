// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

class ForkInfo {
  static const String maintainer = 'KIKO';
  static const String maintainerUrl = 'https://github.com/2484895358';
  static const String repositoryOwner = '2484895358';
  static const String repositoryName = 'traintime_pda';
  static const String updateManifestUrl =
      'https://myapk.sgp1.cdn.digitaloceanspaces.com/manifests/update.json';
  static const String updateManifestKeyId = 'update-manifest-rsa-sha256-v1';
  static const String updateManifestSpacesHost =
      'myapk.sgp1.cdn.digitaloceanspaces.com';
  static const String updateManifestPublicKey = '''
-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA5OcXMxRWWf2D9CcokrG2
72DyFwf3s9S7NZL78GbDbkfGCMmTPZI8hcPCbtyd8DM5zUCpJmi9Xp/1jWt6hk5y
2+x3HRzDhliCwT4Ep3qEZw5rYI+S33pW0jhj/VsbPxSYkk01iAWxLiVyR6/X7fPk
eKuwVh8Gzy6m5SEHM+d1cO0j5d3iRn2hr5BFZo4G+PQSHxgPp+AKk9kr1f+cKx7b
7bUder+LgGgblzvvoHY2VwIbYavqo7Dp6Gfhb+h0gCfP3cuPDgOvj93x+x7AmxdD
0gjUtrcy4L3VwKM3AXUQWixupt/5nmLhAIUHxmkpyTyIR9SzwgyzqgvL2YTfeQ9F
faWV8pmmeFCNo2G1M+4dTTdjlwuM1KQvfnZS0Z/AnStw0FZfKQAmEMigU5YQZi+I
pvOAENVzR0Zi5qw+UIzR1WSdht/1GfxHmTxjg2U32dtBHcmiMR844BZ6jxHhb80s
zfShDDUTGNPWNAGOvcukLS30gRvJOR9amZANgUSa+aBNAgMBAAE=
-----END PUBLIC KEY-----
''';
  static const Set<String> trustedUpdateReleaseHosts = {
    'github.com',
    'apps.apple.com',
  };
  static const Set<String> trustedUpdateDownloadHosts = {
    updateManifestSpacesHost,
    'github.com',
    'apps.apple.com',
  };
  static const String trustedSpacesReleasePathPrefix = '/releases/';

  static const String repositoryUrl =
      'https://github.com/$repositoryOwner/$repositoryName';
  static const String releasePageUrl = '$repositoryUrl/releases';
  static const String upstreamRepositoryUrl =
      'https://github.com/BenderBlog/traintime_pda';
}
