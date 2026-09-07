import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/grocery/domain/grocery_item_entity.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_entity.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';

void main() {
  group('Hardened Domain Entities Serialization Tests', () {
    test('HouseholdEntity serializes and deserializes correctly', () {
      final json = {
        'id': 'h_123',
        'owner_id': 'u_456',
        'name': 'Sharma Family',
        'created_at': '2026-09-01T10:00:00.000Z',
        'updated_at': '2026-09-01T10:00:00.000Z',
      };

      final household = HouseholdEntity.fromJson(json);
      expect(household.id, equals('h_123'));
      expect(household.ownerId, equals('u_456'));
      expect(household.name, equals('Sharma Family'));
      expect(household.toJson()['name'], equals('Sharma Family'));
    });

    test('RecipeEntity serializes provenance and qualitative ingredients', () {
      final json = {
        'id': 'rec_masala_karela',
        'title': 'Masala Karela Recipe',
        'description': null,
        'cuisine': 'Indian',
        'meal_type': 'dinner',
        'course': 'Side Dish',
        'diet': 'Diabetic Friendly',
        'servings': 6,
        'prep_time_minutes': 15,
        'cook_time_minutes': 30,
        'total_time_minutes': 45,
        'difficulty': null,
        'source': 'mendeley_archanas_kitchen',
        'source_recipe_id': '1',
        'source_url': 'https://www.archanaskitchen.com/masala-karela-recipe',
        'dietary_properties': ['Diabetic Friendly'],
        'instructions': [
          {'step': 1, 'text': 'De-seed the karela and slice.'},
        ],
        'is_public': true,
      };

      final ingredientJson = {
        'id': 'ri_1',
        'recipe_id': 'rec_masala_karela',
        'canonical_ingredient_id': 'salt',
        'raw_text': 'Salt - to taste',
        'ingredient_name': 'salt',
        'quantity': null,
        'unit': null,
        'amount_description': 'to taste',
        'preparation': null,
        'is_optional': false,
      };

      final recipe = RecipeEntity.fromJson(
        json,
        ingredients: [RecipeIngredientEntity.fromJson(ingredientJson)],
      );

      expect(recipe.title, equals('Masala Karela Recipe'));
      expect(recipe.source, equals('mendeley_archanas_kitchen'));
      expect(recipe.sourceRecipeId, equals('1'));
      expect(recipe.course, equals('Side Dish'));
      expect(recipe.diet, equals('Diabetic Friendly'));
      expect(recipe.computedTotalTimeMinutes, equals(45));
      expect(recipe.ingredients.length, equals(1));
      expect(recipe.ingredients.first.amountDescription, equals('to taste'));
      expect(recipe.ingredients.first.quantity, isNull);
    });

    test('PantryItemEntity handles qualitative amounts correctly', () {
      final qualitativeItem = {
        'id': 'p_qual',
        'household_id': 'h_123',
        'canonical_ingredient_id': 'oil_mustard',
        'name': 'Mustard Oil',
        'quantity': null,
        'unit': null,
        'amount_description': 'half bottle left',
        'storage_location': 'pantry',
        'expires_at': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final item = PantryItemEntity.fromJson(qualitativeItem);
      expect(item.quantity, isNull);
      expect(item.amountDescription, equals('half bottle left'));
      expect(item.storageLocation, equals('pantry'));
    });

    test('MealPlanEntity handles nullable estimatedCost (price unavailable)', () {
      final planJson = {
        'id': 'mp_1',
        'household_id': 'h_123',
        'start_date': '2026-09-01',
        'end_date': '2026-09-07',
        'status': 'proposed',
        'target_budget': 3500.0,
        'estimated_cost': null, // Price not yet calculated or unavailable
        'notes': 'Weekly plan',
      };

      final plan = MealPlanEntity.fromJson(planJson);
      expect(plan.status, equals('proposed'));
      expect(plan.estimatedCost, isNull);
    });

    test('GroceryItemEntity handles qualitative shopping items', () {
      final itemJson = {
        'id': 'gi_1',
        'grocery_list_id': 'gl_1',
        'canonical_ingredient_id': 'salt',
        'name': 'Salt',
        'quantity': null,
        'unit': null,
        'amount_description': '1 small pack',
        'category': 'spices',
        'is_purchased': false,
        'estimated_price': null,
      };

      final item = GroceryItemEntity.fromJson(itemJson);
      expect(item.name, equals('Salt'));
      expect(item.quantity, isNull);
      expect(item.amountDescription, equals('1 small pack'));
      expect(item.estimatedPrice, isNull);
    });
  });
}
