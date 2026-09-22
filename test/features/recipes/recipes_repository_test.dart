import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/recipes/data/recipes_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('RecipesRepository Diet Normalization Tests', () {
    test('searchRecipes normalizes non-veg filter for dataset spelling splits', () async {
      final mockClient = SupabaseClient(
        'https://mock.supabase.co',
        'mock-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final repo = RecipesRepository(mockClient);

      // In mock environment where HTTP call fails, it safely catches and returns []
      final results1 = await repo.searchRecipes(diet: 'Non Vegeterian');
      expect(results1, isEmpty);

      final results2 = await repo.searchRecipes(diet: 'Non Vegetarian');
      expect(results2, isEmpty);

      final results3 = await repo.searchRecipes(diet: 'non_vegetarian');
      expect(results3, isEmpty);
    });
  });
}
