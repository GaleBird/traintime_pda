import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:watermeter/page/classtable/class_table_view/class_card_layout.dart';
import 'package:watermeter/page/classtable/classtable_responsive.dart';
import 'package:watermeter/repository/preference.dart' as preference;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          preference.Preference.isGxuMode.key: true,
        });
    preference.prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  });

  group('resolveClassTableHeaderMetrics', () {
    test('uses tiny header metrics for short classtable viewports', () {
      final metrics = resolveClassTableHeaderMetrics(const Size(390, 510));

      expect(metrics.topViewHeight, 42);
      expect(metrics.weekChoiceInnerPadding, const EdgeInsets.all(3));
    });

    test('uses compact header metrics for medium classtable viewports', () {
      final metrics = resolveClassTableHeaderMetrics(const Size(390, 640));

      expect(metrics.topViewHeight, 46);
      expect(metrics.weekChoiceInnerPadding, const EdgeInsets.all(4));
    });

    test('keeps regular header metrics for tall classtable viewports', () {
      final metrics = resolveClassTableHeaderMetrics(const Size(390, 720));

      expect(metrics.topViewHeight, 56);
      expect(metrics.weekChoiceInnerPadding, const EdgeInsets.all(5));
    });
  });

  group('resolveClassTableGridMetrics', () {
    test('uses tiny metrics for very short windows', () {
      final metrics = resolveClassTableGridMetrics(const Size(360, 510));

      expect(metrics.leftColumnWidth, 24);
      expect(metrics.dateRowHeight, 42);
      expect(metrics.periodTimeFontSize, 6.8);
    });

    test('uses compact metrics for short phones', () {
      final metrics = resolveClassTableGridMetrics(const Size(390, 580));

      expect(metrics.leftColumnWidth, 25);
      expect(metrics.dateRowHeight, 46);
      expect(metrics.breakLabelFontSize, 11);
    });

    test('keeps default metrics for regular phones', () {
      final metrics = resolveClassTableGridMetrics(const Size(393, 720));

      expect(metrics.leftColumnWidth, 26);
      expect(metrics.dateRowHeight, 54);
      expect(metrics.periodIndexFontSize, 11);
    });
  });

  group('resolveClassCardLayout', () {
    test('falls back to compact layout on ultra narrow cards', () {
      final layout = resolveClassCardLayout(
        isPhoneLayout: true,
        width: 34,
        height: 84,
        hasTeacher: true,
      );

      expect(layout.showTeacher, isFalse);
      expect(layout.placeMinFontSize, 6.0);
      expect(layout.nameMaxLines, 1);
    });

    test('keeps teacher row on regular phone cards with enough height', () {
      final layout = resolveClassCardLayout(
        isPhoneLayout: true,
        width: 36,
        height: 84,
        hasTeacher: true,
      );

      expect(layout.showTeacher, isTrue);
      expect(layout.placeMaxLines, 2);
      expect(layout.nameMaxLines, 2);
    });

    test('all class-card minimum fonts align with step granularity', () {
      final layouts = [
        resolveClassCardLayout(
          isPhoneLayout: true,
          width: 34,
          height: 84,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: true,
          width: 36,
          height: 60,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: true,
          width: 36,
          height: 84,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: true,
          width: 50,
          height: 68,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: true,
          width: 58,
          height: 84,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: false,
          width: 72,
          height: 58,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: false,
          width: 80,
          height: 88,
          hasTeacher: true,
        ),
        resolveClassCardLayout(
          isPhoneLayout: false,
          width: 96,
          height: 108,
          hasTeacher: true,
        ),
      ];

      for (final layout in layouts) {
        expect((layout.placeMinFontSize / classCardTextStepGranularity) % 1, 0);
      }

      expect((8.5 / classCardTextStepGranularity) % 1, 0);
      expect((10.0 / classCardTextStepGranularity) % 1, 0);
    });
  });
}
