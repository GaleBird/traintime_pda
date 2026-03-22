import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/update_install_variant.dart';

void main() {
  group('isTestingInstall', () {
    test('treats dev package suffix as testing install', () {
      expect(
        isTestingInstall(
          packageName: 'io.github.benderblog.traintime_pda.dev',
          version: '1.0.2',
        ),
        isTrue,
      );
    });

    test('treats prerelease version as testing install', () {
      expect(
        isTestingInstall(
          packageName: 'io.github.benderblog.traintime_pda',
          version: '1.0.2-dev',
        ),
        isTrue,
      );
    });

    test('keeps stable release install out of testing channel', () {
      expect(
        isTestingInstall(
          packageName: 'io.github.benderblog.traintime_pda',
          version: '1.0.2',
        ),
        isFalse,
      );
    });
  });
}
