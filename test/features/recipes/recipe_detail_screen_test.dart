import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/recipes/data/recipes_repository.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';
import 'package:plate_pilot/features/recipes/presentation/screens/recipe_detail_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testRecipe = RecipeEntity(
    id: 'r_detail_1',
    title: 'Kadhai Paneer Special',
    cuisine: 'North Indian',
    course: 'Main Course',
    diet: 'Vegetarian',
    servings: 2,
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    totalTimeMinutes: 30,
    ingredients: [
      RecipeIngredientEntity(
        id: 'ing_1',
        recipeId: 'r_detail_1',
        rawText: '200g Paneer',
        ingredientName: 'Paneer',
        quantity: 200,
        unit: 'g',
      ),
      RecipeIngredientEntity(
        id: 'ing_2',
        recipeId: 'r_detail_1',
        rawText: '2 Bell Peppers',
        ingredientName: 'Bell Pepper',
        quantity: 2,
        unit: 'pcs',
      ),
      RecipeIngredientEntity(
        id: 'ing_3',
        recipeId: 'r_detail_1',
        rawText: 'Salt to taste',
        ingredientName: 'Salt',
        amountDescription: 'to taste',
      ),
    ],
    instructions: [
      RecipeStepEntity(
        step: 1,
        text: 'Cut paneer and bell peppers into bite-sized cubes.',
      ),
      RecipeStepEntity(
        step: 2,
        text: 'Sauté kadhai masala spices with ghee in hot pan.',
      ),
    ],
  );

  group('RecipeDetailScreen Component 6 Tests', () {
    testWidgets('renders recipe details, metrics, and initial ingredient quantities', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeDetailProvider('r_detail_1').overrideWith((ref) async => testRecipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'r_detail_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title, tags, and time metrics
      expect(find.text('Kadhai Paneer Special'), findsOneWidget);
      expect(find.text('North Indian'), findsOneWidget);
      expect(find.text('Vegetarian'), findsOneWidget);
      expect(find.text('10 m'), findsOneWidget);
      expect(find.text('20 m'), findsOneWidget);
      expect(find.text('30 m'), findsOneWidget);

      // Verify initial ingredient quantities for 2 base servings
      expect(find.text('Paneer'), findsOneWidget);
      expect(find.text('200 g'), findsOneWidget);
      expect(find.text('Bell Pepper'), findsOneWidget);
      expect(find.text('2 pcs'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);
      expect(find.text('to taste'), findsOneWidget);

      // Verify cooking steps
      expect(find.text('Cut paneer and bell peppers into bite-sized cubes.'), findsOneWidget);
      expect(find.text('Sauté kadhai masala spices with ghee in hot pan.'), findsOneWidget);
    });

    testWidgets('scaling servings dynamically multiplies ingredient quantities', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeDetailProvider('r_detail_1').overrideWith((ref) async => testRecipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'r_detail_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial servings is 2 (base servings). Paneer is 200 g.
      expect(find.text('200 g'), findsOneWidget);

      // Tap increment button (+) to scale to 3 servings
      final addButton = find.byIcon(Icons.add_rounded);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Tap increment button (+) again to scale to 4 servings (2x base)
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // At 4 servings (2x), Paneer should be 400 g and Bell Pepper should be 4 pcs
      expect(find.text('400 g'), findsOneWidget);
      expect(find.text('4 pcs'), findsOneWidget);
    });

    testWidgets('tapping ingredient or step marks as completed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeDetailProvider('r_detail_1').overrideWith((ref) async => testRecipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'r_detail_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Paneer item to check off
      await tester.tap(find.text('Paneer'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Scroll step into view and tap to mark completed
      final stepFinder = find.text('Cut paneer and bell peppers into bite-sized cubes.');
      await tester.scrollUntilVisible(stepFinder, 200);
      await tester.tap(stepFinder);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('tapping segmented tabs toggles between Overview, Ingredients, and Steps views', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeDetailProvider('r_detail_1').overrideWith((ref) async => testRecipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'r_detail_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state is Overview: both Ingredients and Cooking Steps are present
      expect(find.text('Ingredients (3)'), findsWidgets);
      expect(find.text('Cooking Steps'), findsOneWidget);

      // Tap on Ingredients tab
      await tester.tap(find.text('Ingredients (3)').first);
      await tester.pumpAndSettle();

      // In Ingredients view: Paneer is visible, Cooking Steps header is hidden
      expect(find.text('Paneer'), findsOneWidget);
      expect(find.text('Cooking Steps'), findsNothing);

      // Tap on Steps tab
      await tester.tap(find.text('Steps (2)'));
      await tester.pumpAndSettle();

      // In Steps view: Cooking Steps is visible, Paneer is hidden
      expect(find.text('Cooking Steps'), findsOneWidget);
      expect(find.text('Paneer'), findsNothing);

      // Tap back on Overview tab
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // Both are back
      expect(find.text('Paneer'), findsOneWidget);
      expect(find.text('Cooking Steps'), findsOneWidget);
    });
  });
}
