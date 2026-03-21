import 'dart:io';

import 'package:path/path.dart' as path;

const _allowedHttpHosts = {
  'afdian.net',
  'ca.gxu.edu.cn',
  'ehall.xidian.edu.cn',
  'payment.xidian.edu.cn',
  'self.gxu.edu.cn',
  'tybjxgl.xidian.edu.cn',
  'wlsy.xidian.edu.cn',
};

const _ignoredDirectories = {
  '.dart_tool',
  '.flutter',
  '.git',
  '.plugin_symlinks',
  '.symlinks',
  '.transforms',
  'build',
  'ephemeral',
  'tmp',
};

const _textExtensions = {
  '.dart',
  '.gradle',
  '.java',
  '.json',
  '.kt',
  '.md',
  '.properties',
  '.ps1',
  '.py',
  '.sh',
  '.xml',
  '.yaml',
  '.yml',
};

void main() {
  final root = Directory.current;
  final files = _collectFiles(root);
  final issues = <AuditIssue>[
    ..._checkSensitiveFiles(files, root),
    ..._checkTextPatterns(files, root),
    ..._checkRequiredGuards(root),
  ];

  if (issues.isEmpty) {
    stdout.writeln('Security audit passed with no blocking findings.');
    return;
  }

  stdout.writeln('Security audit found ${issues.length} issue(s):');
  for (final issue in issues) {
    stdout.writeln('[${issue.severity}] ${issue.location}: ${issue.message}');
  }
  exitCode = 1;
}

List<File> _collectFiles(Directory root) {
  final files = <File>[];
  final pending = <Directory>[root];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    List<FileSystemEntity> children;
    try {
      children = current.listSync();
    } on FileSystemException {
      continue;
    }
    for (final entity in children) {
      if (entity is Directory) {
        if (_shouldIgnoreDirectory(entity, root)) {
          continue;
        }
        pending.add(entity);
        continue;
      }
      if (entity is! File || _shouldIgnoreFile(entity, root)) {
        continue;
      }
      files.add(entity);
    }
  }
  return files;
}

bool _shouldIgnoreDirectory(Directory directory, Directory root) {
  final relative = path.relative(directory.path, from: root.path);
  final segments = path.split(relative);
  return segments.any(_ignoredDirectories.contains);
}

bool _shouldIgnoreFile(File file, Directory root) {
  final relative = path.relative(file.path, from: root.path);
  final segments = path.split(relative);
  return segments.any(_ignoredDirectories.contains);
}

List<AuditIssue> _checkSensitiveFiles(List<File> files, Directory root) {
  final issues = <AuditIssue>[];
  const exactRiskPaths = {'android/key.properties', 'android/app/key.jks'};
  for (final file in files) {
    final relative = path
        .relative(file.path, from: root.path)
        .replaceAll('\\', '/');
    final lower = relative.toLowerCase();
    final extension = path.extension(lower);
    if (exactRiskPaths.contains(lower)) {
      issues.add(AuditIssue('critical', relative, '签名文件出现在仓库工作树中'));
      continue;
    }
    if (lower.endsWith('.env') || lower.contains('/.env.')) {
      issues.add(AuditIssue('high', relative, '.env 文件不应保留在仓库中'));
    }
    if ({
      '.jks',
      '.keystore',
      '.p12',
      '.pfx',
      '.mobileprovision',
    }.contains(extension)) {
      issues.add(AuditIssue('critical', relative, '检测到高风险签名或证书文件'));
    }
  }
  return issues;
}

List<AuditIssue> _checkTextPatterns(List<File> files, Directory root) {
  final issues = <AuditIssue>[];
  for (final file in files) {
    if (!_textExtensions.contains(path.extension(file.path).toLowerCase())) {
      continue;
    }
    final relative = path
        .relative(file.path, from: root.path)
        .replaceAll('\\', '/');
    if (relative == 'tool/security_audit.dart') {
      continue;
    }
    final content = file.readAsStringSync();
    _checkPrivateKey(content, relative, issues);
    _checkTlsBypass(content, relative, issues);
    _checkCookieStorage(content, relative, issues);
    _checkVerboseLogs(content, relative, issues);
    if (relative.startsWith('lib/')) {
      _checkHttpLinks(content, relative, issues);
    }
  }
  return issues;
}

void _checkPrivateKey(
  String content,
  String relative,
  List<AuditIssue> issues,
) {
  if (content.contains('-----BEGIN PRIVATE KEY-----') ||
      content.contains('-----BEGIN RSA PRIVATE KEY-----')) {
    issues.add(AuditIssue('critical', relative, '检测到私钥内容'));
  }
}

void _checkTlsBypass(String content, String relative, List<AuditIssue> issues) {
  const patterns = [
    'badCertificateCallback',
    'allowBadCertificates',
    'withTrustedRoots: false',
  ];
  for (final pattern in patterns) {
    if (content.contains(pattern)) {
      issues.add(AuditIssue('critical', relative, '检测到 TLS 校验绕过: $pattern'));
    }
  }
}

void _checkCookieStorage(
  String content,
  String relative,
  List<AuditIssue> issues,
) {
  if (relative.startsWith('lib/') && content.contains('FileStorage(')) {
    issues.add(AuditIssue('high', relative, '检测到明文 Cookie 文件存储'));
  }
}

void _checkVerboseLogs(
  String content,
  String relative,
  List<AuditIssue> issues,
) {
  const riskyFlags = [
    'printRequestData: true',
    'printRequestHeaders: true',
    'printResponseData: true',
    'printResponseHeaders: true',
    'printErrorHeaders: true',
  ];
  for (final flag in riskyFlags) {
    if (content.contains(flag)) {
      issues.add(AuditIssue('medium', relative, '检测到高风险网络日志配置: $flag'));
    }
  }
}

void _checkHttpLinks(String content, String relative, List<AuditIssue> issues) {
  final matches = RegExp(r'''http://[^\s'"]+''').allMatches(content);
  for (final match in matches) {
    final rawUrl = match.group(0)!;
    final candidate = rawUrl.split(r'$').first;
    final uri = Uri.tryParse(candidate);
    if (uri == null) {
      issues.add(AuditIssue('medium', relative, '检测到不可解析的明文 HTTP 地址: $rawUrl'));
      continue;
    }
    if (_allowedHttpHosts.contains(uri.host)) {
      continue;
    }
    issues.add(AuditIssue('medium', relative, '检测到未豁免的明文 HTTP 地址: $rawUrl'));
  }
}

List<AuditIssue> _checkRequiredGuards(Directory root) {
  final issues = <AuditIssue>[];
  final workflowFile = File(
    path.join(root.path, '.github', 'workflows', 'release_for_android.yaml'),
  );
  final updateSessionFile = File(
    path.join(root.path, 'lib', 'repository', 'pda_service_session.dart'),
  );
  final preferenceFile = File(
    path.join(root.path, 'lib', 'repository', 'preference.dart'),
  );

  final workflow = workflowFile.readAsStringSync();
  if (!workflow.contains('UPDATE_MANIFEST_SIGNING_KEY') ||
      !workflow.contains('--signing-key')) {
    issues.add(
      AuditIssue(
        'critical',
        '.github/workflows/release_for_android.yaml',
        '更新清单签名流程缺失',
      ),
    );
  }

  final updateSession = updateSessionFile.readAsStringSync();
  if (!updateSession.contains('validateAndStripUpdateManifestSignature')) {
    issues.add(
      AuditIssue(
        'critical',
        'lib/repository/pda_service_session.dart',
        '更新清单未启用签名校验',
      ),
    );
  }

  final preference = preferenceFile.readAsStringSync();
  for (final key in [
    'Preference.idsPassword',
    'Preference.schoolNetQueryPassword',
    'Preference.sportPassword',
    'Preference.experimentPassword',
    'Preference.electricityPassword',
  ]) {
    if (!preference.contains(key)) {
      issues.add(
        AuditIssue('high', 'lib/repository/preference.dart', '安全存储白名单缺少 $key'),
      );
    }
  }

  return issues;
}

class AuditIssue {
  const AuditIssue(this.severity, this.location, this.message);

  final String severity;
  final String location;
  final String message;
}
