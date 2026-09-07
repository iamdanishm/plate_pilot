import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/home/data/home_repository.dart';
import 'package:plate_pilot/features/home/presentation/screens/home_screen.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testHousehold = HouseholdEntity(
    id: 'h_test_1',
    ownerId: 'u_test_1',
    name: 'The Sharma Family',
    adultsCount: 2,
    childrenCount: 1,
    dietaryRestrictions: const ['Vegetarian'],
    weeklyBudget: 4200.0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final testRecipes = [
    const RecipeEntity(
      id: 'r_1',
      title: 'Paneer Butter Masala',
      cuisine: 'North Indian',
      diet: 'Vegetarian',
      prepTimeMinutes: 15,
      cookTimeMinutes: 20,
    ),
    const RecipeEntity(
      id: 'r_2',
      title: 'Palak Dal',
      cuisine: 'Indian',
      diet: 'Vegetarian',
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
    ),
  ];

  group('HomeScreen Component 5 Dashboard Tests', () {
    testWidgets('renders dynamic household greeting, member badges and stats', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserHouseholdProvider.overrideWith((ref) async => testHousehold),
            homePantryCountProvider('h_test_1').overrideWith((ref) async => 24),
            homeGroceryCountProvider('h_test_1').overrideWith((ref) async => 7),
            homeActiveMealPlanProvider('h_test_1').overrideWith((ref) async => null),
            homeRecommendedRecipesProvider('h_test_1').overrideWith((ref) async => testRecipes),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify household name and member badges
      expect(find.text('The Sharma Family'), findsOneWidget);
      expect(find.text('2 Adults, 1 Child'), findsOneWidget);
      expect(find.text('Vegetarian'), findsAtLeastNWidgets(1));

      // Verify quick stats
      expect(find.text('24 tracked'), findsOneWidget);
      expect(find.text('7 pending'), findsOneWidget);
      expect(find.text('₹4200'), findsOneWidget);

      // Verify Hero banner when no active meal plan
      expect(find.text('Ready to optimize this week?'), findsOneWidget);
      expect(find.text('Generate Meal Plan'), findsOneWidget);

      // Verify recommended recipes are rendered
      expect(find.text('Paneer Butter Masala'), findsOneWidget);
      expect(find.text('Palak Dal'), findsOneWidget);
      expect(find.text('North Indian • 35 mins • Vegetarian'), findsOneWidget);
      expect(find.text('Indian • 25 mins • Vegetarian'), findsOneWidget);
    });

    testWidgets('renders active meal plan banner when plan exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserHouseholdProvider.overrideWith((ref) async => testHousehold),
            homePantryCountProvider('h_test_1').overrideWith((ref) async => 15),
            homeGroceryCountProvider('h_test_1').overrideWith((ref) async => 3),
            homeActiveMealPlanProvider('h_test_1').overrideWith((ref) async => {
              'id': 'plan_1',
              'status': 'active',
            }),
            homeRecommendedRecipesProvider('h_test_1').overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify active plan banner state
      expect(find.text('Your Week is Planned & Ready!'), findsOneWidget);
      expect(find.text('View Meal Plan'), findsOneWidget);
      expect(find.text('Active Meal Plan'), findsOneWidget);

      // Verify empty recipes catalog card
      expect(find.text('Catalog ready with 6,800+ recipes'), findsOneWidget);
    });
  });
}
