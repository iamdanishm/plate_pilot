import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';

abstract class IHomeRepository {
  Future<int> getPantryItemCount(String householdId);
  Future<int> getPendingGroceryCount(String householdId);
  Future<Map<String, dynamic>?> getActiveMealPlan(String householdId);
  Future<List<RecipeEntity>> getRecommendedRecipes({
    List<String> preferredCuisines = const [],
    List<String> dietaryRestrictions = const [],
    int limit = 3,
  });
}

class HomeRepository implements IHomeRepository {
  final supabase.SupabaseClient _client;

  HomeRepository(this._client);

  @override
  Future<int> getPantryItemCount(String householdId) async {
    if (householdId == 'default') return 0;
    try {
      final response = await _client
          .from('pantry_items')
          .select('id')
          .eq('household_id', householdId);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<int> getPendingGroceryCount(String householdId) async {
    if (householdId == 'default') return 0;
    try {
      final response = await _client
          .from('grocery_items')
          .select('id')
          .eq('household_id', householdId)
          .eq('is_checked', false);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>?> getActiveMealPlan(String householdId) async {
    if (householdId == 'default') return null;
    try {
      final response = await _client
          .from('meal_plans')
          .select()
          .eq('household_id', householdId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RecipeEntity>> getRecommendedRecipes({
    List<String> preferredCuisines = const [],
    List<String> dietaryRestrictions = const [],
    int limit = 3,
  }) async {
    try {
      var query = _client.from('recipes').select().eq('language', 'en');

      // If preferred cuisines specified
      if (preferredCuisines.isNotEmpty) {
        final cuisine = preferredCuisines.first;
        query = query.ilike('cuisine', '%$cuisine%');
      }

      // If dietary restriction is specified
      if (dietaryRestrictions.isNotEmpty) {
        final diet = dietaryRestrictions.first.toLowerCase();
        if (diet.contains('non')) {
          // Matches both "Non Vegeterian" and "High Protein Non Vegetarian"
          query = query.ilike('diet', '%Non Veget%');
        } else if (diet.contains('vegan')) {
          query = query.ilike('diet', '%vegan%');
        } else if (diet.contains('eggetarian')) {
          query = query.ilike('diet', '%egg%');
        } else if (diet.contains('sattvic') || diet.contains('jain')) {
          query = query.ilike('diet', '%No Onion No Garlic%');
        } else if (diet.contains('veg')) {
          query = query.ilike('diet', '%vegetarian%');
        }
      }

      final response = await query.order('title', ascending: true).limit(limit);
      return (response as List)
          .map((r) => RecipeEntity.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final homeRepositoryProvider = Provider<IHomeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HomeRepository(client);
});

final homePantryCountProvider = FutureProvider.family<int, String>((ref, householdId) async {
  if (householdId == 'default') return 0;
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getPantryItemCount(householdId);
});

final homeGroceryCountProvider = FutureProvider.family<int, String>((ref, householdId) async {
  if (householdId == 'default') return 0;
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getPendingGroceryCount(householdId);
});

final homeActiveMealPlanProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, householdId) async {
  if (householdId == 'default') return null;
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getActiveMealPlan(householdId);
});

final homeRecommendedRecipesProvider = FutureProvider.family<List<RecipeEntity>, String>((ref, householdId) async {
  if (householdId == 'default') return [];
  final household = await ref.watch(currentUserHouseholdProvider.future);
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getRecommendedRecipes(
    preferredCuisines: household?.preferredCuisines ?? const [],
    dietaryRestrictions: household?.dietaryRestrictions ?? const [],
  );
});
