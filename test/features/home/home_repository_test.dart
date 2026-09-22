import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/home/data/home_repository.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';

class FakeHomeRepository implements IHomeRepository {
  List<String>? lastPreferredCuisines;
  List<String>? lastDietaryRestrictions;

  @override
  Future<int> getPantryItemCount(String householdId) async => 5;

  @override
  Future<int> getPendingGroceryCount(String householdId) async => 3;

  @override
  Future<Map<String, dynamic>?> getActiveMealPlan(String householdId) async => null;

  @override
  Future<List<RecipeEntity>> getRecommendedRecipes({
    List<String> preferredCuisines = const [],
    List<String> dietaryRestrictions = const [],
    int limit = 3,
  }) async {
    lastPreferredCuisines = preferredCuisines;
    lastDietaryRestrictions = dietaryRestrictions;

    if (dietaryRestrictions.contains('non_vegetarian')) {
      return [
        const RecipeEntity(
          id: 'r_chicken',
          title: 'Butter Chicken',
          cuisine: 'North Indian',
          diet: 'Non Vegeterian',
        ),
      ];
    }

    return [
      const RecipeEntity(
        id: 'r_paneer',
        title: 'Paneer Makhani',
        cuisine: 'North Indian',
        diet: 'Vegetarian',
      ),
    ];
  }
}

void main() {
  group('HomeRepository & Recommendations Tests', () {
    test('homeRecommendedRecipesProvider passes preferredCuisines and non_vegetarian correctly', () async {
      final fakeRepo = FakeHomeRepository();
      final nonVegHousehold = HouseholdEntity(
        id: 'h_non_veg',
        ownerId: 'u_1',
        name: 'Khan Family',
        dietaryRestrictions: const ['non_vegetarian'],
        preferredCuisines: const ['Mughlai', 'North Indian'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserHouseholdProvider.overrideWith((ref) async => nonVegHousehold),
        ],
      );

      final recipes = await container.read(homeRecommendedRecipesProvider('h_non_veg').future);
      expect(recipes.length, 1);
      expect(recipes.first.title, 'Butter Chicken');
      expect(recipes.first.diet, 'Non Vegeterian');

      expect(fakeRepo.lastDietaryRestrictions, ['non_vegetarian']);
      expect(fakeRepo.lastPreferredCuisines, ['Mughlai', 'North Indian']);
    });
  });
}
