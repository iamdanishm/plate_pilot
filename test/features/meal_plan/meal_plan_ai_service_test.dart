import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/meal_plan/data/meal_plan_ai_service.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_proposal_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('MealPlanProposalEntity Tests', () {
    test('serializes and deserializes 7-day AI proposal JSON correctly', () {
      final mockJson = {
        'week_summary':
            'A balanced North Indian vegetarian week utilizing stocked paneer and lentils.',
        'planned_days': [
          {
            'day': 'monday',
            'meal_type': 'dinner',
            'recipe_id': 'r_101',
            'recipe_title': 'Palak Paneer',
            'reason_summary': 'Uses expiring spinach and stocked paneer.',
          },
          {
            'day': 'tuesday',
            'meal_type': 'dinner',
            'recipe_id': 'r_102',
            'recipe_title': 'Toor Dal Tadka with Jeera Rice',
            'reason_summary': 'Quick 20-minute weekday meal using pantry dal.',
          },
        ],
      };

      final proposal = MealPlanProposalEntity.fromJson(mockJson);

      expect(
        proposal.weekSummary,
        'A balanced North Indian vegetarian week utilizing stocked paneer and lentils.',
      );
      expect(proposal.plannedMeals.length, 2);
      expect(proposal.plannedMeals[0].day, 'monday');
      expect(proposal.plannedMeals[0].recipeId, 'r_101');
      expect(proposal.plannedMeals[0].recipeTitle, 'Palak Paneer');
      expect(
        proposal.plannedMeals[0].reasonSummary,
        'Uses expiring spinach and stocked paneer.',
      );

      final exportedJson = proposal.toJson();
      expect(exportedJson['week_summary'], proposal.weekSummary);
      expect((exportedJson['planned_days'] as List).length, 2);
    });

    test('handles empty or malformed planned_days gracefully', () {
      final emptyJson = {
        'week_summary': 'No meals planned',
        'planned_days': null,
      };

      final proposal = MealPlanProposalEntity.fromJson(emptyJson);
      expect(proposal.weekSummary, 'No meals planned');
      expect(proposal.plannedMeals, isEmpty);
    });
  });

  group('MealSwapProposalEntity Tests', () {
    test('serializes and deserializes meal swap JSON correctly', () {
      final mockJson = {
        'replacement_recipe_id': 'r_205',
        'replacement_recipe_title': 'Chole Bhature',
        'reason_summary': 'Fits weekend dinner request for a richer dish.',
      };

      final swap = MealSwapProposalEntity.fromJson(mockJson);
      expect(swap.replacementRecipeId, 'r_205');
      expect(swap.replacementRecipeTitle, 'Chole Bhature');
      expect(swap.reasonSummary, 'Fits weekend dinner request for a richer dish.');

      final exported = swap.toJson();
      expect(exported['replacement_recipe_id'], 'r_205');
    });
  });

  group('MealPlanAiService Tests', () {
    late SupabaseClient mockClient;
    late MealPlanAiService service;

    setUp(() {
      mockClient = SupabaseClient(
        'https://mock.supabase.co',
        'mock-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      service = MealPlanAiService(mockClient);
    });

    test('throws descriptive exception when Edge Function returns error or unreachable', () async {
      expect(
        () async => await service.generateMealPlanProposal('household-123'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to generate meal plan proposal'),
          ),
        ),
      );
    });

    test('throws descriptive exception when swap request fails', () async {
      expect(
        () async => await service.requestMealSwap(
          householdId: 'household-123',
          targetDay: 'wednesday',
          targetMealType: 'dinner',
          swapReason: 'Need something lighter',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to request meal swap'),
          ),
        ),
      );
    });
  });
}
