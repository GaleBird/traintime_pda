final RegExp _testingVersionPattern = RegExp(
  r'^\d+(?:\.\d+)*(?:-[0-9A-Za-z][0-9A-Za-z.-]*)$',
);

bool isTestingInstall({required String packageName, required String version}) {
  final normalizedPackageName = packageName.trim().toLowerCase();
  if (normalizedPackageName.endsWith('.dev')) {
    return true;
  }
  return _testingVersionPattern.hasMatch(version.trim());
}
