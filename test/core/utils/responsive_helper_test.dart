import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/utils/responsive_helper.dart';

void main() {
  group('ResponsiveBreakpoints', () {
    test('defines expected threshold values', () {
      expect(ResponsiveBreakpoints.compact, 360.0);
      expect(ResponsiveBreakpoints.tablet, 600.0);
      expect(ResponsiveBreakpoints.desktop, 1024.0);
      expect(ResponsiveBreakpoints.wideDesktop, 1440.0);
    });

    test('defines expected max content width constraints', () {
      expect(ResponsiveBreakpoints.maxContentWidthMobile, 600.0);
      expect(ResponsiveBreakpoints.maxContentWidthTablet, 840.0);
      expect(ResponsiveBreakpoints.maxContentWidthDesktop, 1140.0);
    });
  });

  group('ResponsiveHelper.getDeviceTypeFromWidth', () {
    test('classifies width < 360 as compact', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(320),
        DeviceScreenType.compact,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(359.9),
        DeviceScreenType.compact,
      );
    });

    test('classifies width between 360 and 599.9 as mobile', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(360),
        DeviceScreenType.mobile,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(412),
        DeviceScreenType.mobile,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(599.9),
        DeviceScreenType.mobile,
      );
    });

    test('classifies width between 600 and 1023.9 as tablet', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(600),
        DeviceScreenType.tablet,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(768),
        DeviceScreenType.tablet,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1023.9),
        DeviceScreenType.tablet,
      );
    });

    test('classifies width >= 1024 as desktop', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1024),
        DeviceScreenType.desktop,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1440),
        DeviceScreenType.desktop,
      );
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1920),
        DeviceScreenType.desktop,
      );
    });
  });

  group('ResponsiveHelper with BuildContext', () {
    testWidgets('correctly detects device types via MediaQuery', (
      WidgetTester tester,
    ) async {
      late DeviceScreenType detectedType;
      late bool isCompact;
      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;
      late bool isTabletOrLarger;
      late double resolvedValue;

      Widget buildTestWidget(Size size) {
        return MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              detectedType = context.deviceType;
              isCompact = context.isCompact;
              isMobile = context.isMobile;
              isTablet = context.isTablet;
              isDesktop = context.isDesktop;
              isTabletOrLarger = context.isTabletOrLarger;
              resolvedValue = context.responsiveValue(
                compact: 10.0,
                mobile: 20.0,
                tablet: 30.0,
                desktop: 40.0,
              );
              return const SizedBox.shrink();
            },
          ),
        );
      }

      // 1. Test Compact (< 360)
      await tester.pumpWidget(buildTestWidget(const Size(320, 640)));
      expect(detectedType, DeviceScreenType.compact);
      expect(isCompact, isTrue);
      expect(isMobile, isTrue);
      expect(isTablet, isFalse);
      expect(isDesktop, isFalse);
      expect(isTabletOrLarger, isFalse);
      expect(resolvedValue, 10.0);

      // 2. Test Mobile (360 - 599)
      await tester.pumpWidget(buildTestWidget(const Size(412, 915)));
      expect(detectedType, DeviceScreenType.mobile);
      expect(isCompact, isFalse);
      expect(isMobile, isTrue);
      expect(isTablet, isFalse);
      expect(isDesktop, isFalse);
      expect(isTabletOrLarger, isFalse);
      expect(resolvedValue, 20.0);

      // 3. Test Tablet (600 - 1023)
      await tester.pumpWidget(buildTestWidget(const Size(800, 1280)));
      expect(detectedType, DeviceScreenType.tablet);
      expect(isCompact, isFalse);
      expect(isMobile, isFalse);
      expect(isTablet, isTrue);
      expect(isDesktop, isFalse);
      expect(isTabletOrLarger, isTrue);
      expect(resolvedValue, 30.0);

      // 4. Test Desktop (>= 1024)
      await tester.pumpWidget(buildTestWidget(const Size(1440, 900)));
      expect(detectedType, DeviceScreenType.desktop);
      expect(isCompact, isFalse);
      expect(isMobile, isFalse);
      expect(isTablet, isFalse);
      expect(isDesktop, isTrue);
      expect(isTabletOrLarger, isTrue);
      expect(resolvedValue, 40.0);
    });

    testWidgets('detects orientation correctly', (WidgetTester tester) async {
      late bool isPortrait;
      late bool isLandscape;

      Widget buildWidget(Size size) {
        return MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              isPortrait = context.isPortrait;
              isLandscape = context.isLandscape;
              return const SizedBox.shrink();
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget(const Size(400, 800)));
      expect(isPortrait, isTrue);
      expect(isLandscape, isFalse);

      await tester.pumpWidget(buildWidget(const Size(800, 400)));
      expect(isPortrait, isFalse);
      expect(isLandscape, isTrue);
    });

    testWidgets('resolves grid column counts appropriately', (
      WidgetTester tester,
    ) async {
      late int columns;

      Widget buildWidget(Size size) {
        return MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              columns = ResponsiveHelper.gridColumnCount(
                context,
                compact: 1,
                mobile: 2,
                tablet: 3,
                desktop: 4,
              );
              return const SizedBox.shrink();
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget(const Size(320, 600)));
      expect(columns, 1);

      await tester.pumpWidget(buildWidget(const Size(412, 900)));
      expect(columns, 2);

      await tester.pumpWidget(buildWidget(const Size(768, 1024)));
      expect(columns, 3);

      await tester.pumpWidget(buildWidget(const Size(1200, 800)));
      expect(columns, 4);
    });
  });
}
