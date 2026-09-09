import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/recipes/domain/recipe_entity.dart';

abstract class IRecipesRepository {
  Future<List<RecipeEntity>> searchRecipes({
    String? query,
    String? cuisine,
    String? diet,
    int? maxTotalTimeMinutes,
    int limit = 20,
    int offset = 0,
  });

  Future<RecipeEntity?> getRecipeById(String id);
  Future<List<RecipeIngredientEntity>> getRecipeIngredients(String recipeId);
}

class RecipesRepository implements IRecipesRepository {
  final supabase.SupabaseClient _client;

  RecipesRepository(this._client);

  @override
  Future<List<RecipeEntity>> searchRecipes({
    String? query,
    String? cuisine,
    String? diet,
    int? maxTotalTimeMinutes,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var dbQuery = _client.from('recipes').select().eq('language', 'en');

      // Full-text title search
      if (query != null && query.trim().isNotEmpty) {
        dbQuery = dbQuery.ilike('title', '%${query.trim()}%');
      }

      // Cuisine filter
      if (cuisine != null && cuisine.isNotEmpty && cuisine != 'All') {
        dbQuery = dbQuery.ilike('cuisine', '%$cuisine%');
      }

      // Diet filter
      if (diet != null && diet.isNotEmpty && diet != 'All') {
        dbQuery = dbQuery.ilike('diet', '%$diet%');
      }

      // Max total time filter
      if (maxTotalTimeMinutes != null && maxTotalTimeMinutes > 0) {
        dbQuery = dbQuery.lte('total_time_minutes', maxTotalTimeMinutes);
      }

      final response = await dbQuery
          .order('title', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => RecipeEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<RecipeEntity?> getRecipeById(String id) async {
    try {
      final response = await _client
          .from('recipes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final ingredients = await getRecipeIngredients(id);
      return RecipeEntity.fromJson(
        response,
        ingredients: ingredients,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RecipeIngredientEntity>> getRecipeIngredients(String recipeId) async {
    try {
      final response = await _client
          .from('recipe_ingredients')
          .select()
          .eq('recipe_id', recipeId);

      return (response as List)
          .map((json) =>
              RecipeIngredientEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final recipesRepositoryProvider = Provider<IRecipesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RecipesRepository(client);
});

// Search filter state providers
final recipeSearchQueryProvider = StateProvider<String>((ref) => '');
final recipeSelectedCuisineProvider = StateProvider<String>((ref) => 'All');
final recipeSelectedDietProvider = StateProvider<String>((ref) => 'All');
final recipeSelectedMaxTimeProvider = StateProvider<int?>((ref) => null);
final recipesLimitProvider = StateProvider<int>((ref) => 30);

// Reactive search results provider
final recipesListProvider = FutureProvider.autoDispose<List<RecipeEntity>>((ref) async {
  final repo = ref.watch(recipesRepositoryProvider);
  final query = ref.watch(recipeSearchQueryProvider);
  final cuisine = ref.watch(recipeSelectedCuisineProvider);
  final diet = ref.watch(recipeSelectedDietProvider);
  final maxTime = ref.watch(recipeSelectedMaxTimeProvider);
  final limit = ref.watch(recipesLimitProvider);

  return repo.searchRecipes(
    query: query,
    cuisine: cuisine,
    diet: diet,
    maxTotalTimeMinutes: maxTime,
    limit: limit,
  );
});

// Single recipe detail provider
final recipeDetailProvider =
    FutureProvider.family<RecipeEntity?, String>((ref, recipeId) async {
  final repo = ref.watch(recipesRepositoryProvider);
  return repo.getRecipeById(recipeId);
});

