import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_proposal_entity.dart';

abstract class IMealPlanAiService {
  Future<MealPlanProposalEntity> generateMealPlanProposal(String householdId);

  Future<MealSwapProposalEntity> requestMealSwap({
    required String householdId,
    required String targetDay,
    required String targetMealType,
    required String swapReason,
    String? currentPlanSummary,
  });
}

class MealPlanAiService implements IMealPlanAiService {
  final SupabaseClient _client;

  MealPlanAiService(this._client);

  @override
  Future<MealPlanProposalEntity> generateMealPlanProposal(
      String householdId) async {
    try {
      final response = await _client.functions.invoke(
        'meal-plan-ai',
        body: {
          'action': 'generate_plan',
          'household_id': householdId,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data is Map
            ? response.data['error']
            : 'Server returned error status ${response.status}';
        throw Exception('AI Planner Error (${response.status}): $errorMsg');
      }

      final data = response.data as Map<String, dynamic>;
      return MealPlanProposalEntity.fromJson(data);
    } catch (e) {
      throw Exception('Failed to generate meal plan proposal: $e');
    }
  }

  @override
  Future<MealSwapProposalEntity> requestMealSwap({
    required String householdId,
    required String targetDay,
    required String targetMealType,
    required String swapReason,
    String? currentPlanSummary,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'meal-plan-ai',
        body: {
          'action': 'swap_meal',
          'household_id': householdId,
          'target_day': targetDay,
          'target_meal_type': targetMealType,
          'swap_reason': swapReason,
          'current_plan_summary': currentPlanSummary,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data is Map
            ? response.data['error']
            : 'Server returned error status ${response.status}';
        throw Exception('AI Swap Error (${response.status}): $errorMsg');
      }

      final data = response.data as Map<String, dynamic>;
      return MealSwapProposalEntity.fromJson(data);
    } catch (e) {
      throw Exception('Failed to request meal swap: $e');
    }
  }
}

final mealPlanAiServiceProvider = Provider<IMealPlanAiService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MealPlanAiService(client);
});
