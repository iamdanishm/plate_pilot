import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/recipes/data/recipes_repository.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';
import 'package:plate_pilot/features/recipes/presentation/screens/recipes_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testRecipes = [
    const RecipeEntity(
      id: 'r_1',
      title: 'Butter Chicken Masala',
      cuisine: 'North Indian',
      course: 'Main Course',
      diet: 'Non Vegeterian',
      prepTimeMinutes: 20,
      cookTimeMinutes: 25,
      totalTimeMinutes: 45,
    ),
    const RecipeEntity(
      id: 'r_2',
      title: 'Palak Paneer',
      cuisine: 'Indian',
      course: 'Main Course',
      diet: 'Vegetarian',
      prepTimeMinutes: 15,
      cookTimeMinutes: 15,
      totalTimeMinutes: 30,
    ),
  ];

  group('RecipesScreen Component 6 Tests', () {
    testWidgets('renders search bar, filter chips, and recipe list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipesListProvider.overrideWith((ref) async => testRecipes),
          ],
          child: const MaterialApp(
            home: RecipesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app title and search field
      expect(find.text('Explore Recipes'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify filter chips
      expect(find.text('Indian'), findsOneWidget);
      expect(find.text('North Indian'), findsOneWidget);
      expect(find.text('Vegetarian'), findsAtLeastNWidgets(1));
      expect(find.text('Non Vegeterian'), findsAtLeastNWidgets(1));
      expect(find.text('≤30 mins'), findsOneWidget);

      // Verify recipe cards rendered
      expect(find.text('Butter Chicken Masala'), findsOneWidget);
      expect(find.text('Palak Paneer'), findsOneWidget);
      expect(find.text('45 mins'), findsOneWidget);
      expect(find.text('30 mins'), findsOneWidget);
    });

    testWidgets('entering search query updates recipeSearchQueryProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recipesListProvider.overrideWith((ref) async => testRecipes),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RecipesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Biryani');
      expect(container.read(recipeSearchQueryProvider), 'Biryani');
    });

    testWidgets('tapping cuisine chip toggles selected cuisine', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recipesListProvider.overrideWith((ref) async => testRecipes),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RecipesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('North Indian'));
      expect(container.read(recipeSelectedCuisineProvider), 'North Indian');
    });

    testWidgets('renders empty state when no recipes match query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipesListProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: RecipesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No recipes found'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);
    });
  });
}
