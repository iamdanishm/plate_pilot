import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/core/theme/glass_container.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppConstants Tests', () {
    test('constants have expected values', () {
      expect(AppConstants.appName, equals('PlatePilot'));
      expect(AppConstants.defaultHouseholdSize, equals(2));
      expect(AppConstants.defaultWeeklyBudget, equals(3000.0));
      expect(AppConstants.defaultCurrencySymbol, equals('₹'));
    });
  });

  group('AppTheme Tests', () {
    test('lightTheme has Material 3 and custom primary color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(AppTheme.primaryEmerald));
      expect(theme.brightness, equals(Brightness.light));
    });

    test('darkTheme has dark brightness and custom primary color', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(AppTheme.primaryEmeraldLight));
      expect(theme.brightness, equals(Brightness.dark));
    });
  });

  group('GlassContainer Widget Tests', () {
    testWidgets('renders child widget with frosted glass style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassContainer(
              borderRadius: 24,
              child: Text('Frosted Content'),
            ),
          ),
        ),
      );

      expect(find.text('Frosted Content'), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
    });
  });
}
