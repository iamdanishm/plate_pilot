import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_entity.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_proposal_entity.dart';

abstract class IMealPlanRepository {
  Future<MealPlanProposalEntity?> getActiveMealPlanProposal(String householdId);
  Future<MealPlanEntity> saveConfirmedMealPlan({
    required String householdId,
    required MealPlanProposalEntity proposal,
    required int defaultServings,
  });
}

class MealPlanRepository implements IMealPlanRepository {
  final supabase.SupabaseClient _client;

  MealPlanRepository(this._client);

  @override
  Future<MealPlanProposalEntity?> getActiveMealPlanProposal(
      String householdId) async {
    if (householdId.isEmpty || householdId == 'default') return null;

    try {
      final response = await _client
          .from('meal_plans')
          .select('*, meal_plan_items(*, recipes(title))')
          .eq('household_id', householdId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final rawItems = response['meal_plan_items'];
      if (rawItems is! List || rawItems.isEmpty) return null;

      const dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];

      final plannedMeals = <PlannedMealProposal>[];
      for (final rawItem in rawItems) {
        final itemMap = rawItem as Map<String, dynamic>;
        final plannedDateStr = itemMap['planned_date'] as String? ?? '';
        final parsedDate = DateTime.tryParse(plannedDateStr) ?? DateTime.now();
        final dayIndex = parsedDate.weekday - 1;
        final dayName = (dayIndex >= 0 && dayIndex < 7) ? dayNames[dayIndex] : 'monday';

        final recipesMap = itemMap['recipes'] as Map<String, dynamic>?;
        final recipeTitle = recipesMap?['title'] as String? ?? 'Saved Recipe';

        final rawCodes = itemMap['reason_codes'];
        final reason = (rawCodes is List && rawCodes.isNotEmpty)
            ? rawCodes.first.toString()
            : 'Confirmed in weekly plan';

        plannedMeals.add(
          PlannedMealProposal(
            day: dayName,
            mealType: itemMap['meal_type'] as String? ?? 'dinner',
            recipeId: itemMap['recipe_id'] as String? ?? '',
            recipeTitle: recipeTitle,
            reasonSummary: reason,
            servings: itemMap['servings'] as int? ?? 2,
          ),
        );
      }

      // Sort by day order
      plannedMeals.sort((a, b) {
        final idxA = dayNames.indexOf(a.day.toLowerCase());
        final idxB = dayNames.indexOf(b.day.toLowerCase());
        return idxA.compareTo(idxB);
      });

      return MealPlanProposalEntity(
        weekSummary: response['notes'] as String? ?? 'Confirmed 7-day meal plan',
        plannedMeals: plannedMeals,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MealPlanEntity> saveConfirmedMealPlan({
    required String householdId,
    required MealPlanProposalEntity proposal,
    required int defaultServings,
  }) async {
    final now = DateTime.now();
    final startDate = now.toIso8601String().split('T').first;
    final endDate = now.add(const Duration(days: 6)).toIso8601String().split('T').first;

    // 1. Create Meal Plan Record
    final planResponse = await _client
        .from('meal_plans')
        .insert({
          'household_id': householdId,
          'start_date': startDate,
          'end_date': endDate,
          'status': 'confirmed',
          'notes': proposal.weekSummary,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();

    final planId = planResponse['id'] as String;

    // 2. Insert Meal Plan Items
    final itemsToInsert = <Map<String, dynamic>>[];
    for (final meal in proposal.plannedMeals) {
      final plannedDate = _computeDateForDay(meal.day, now);
      itemsToInsert.add({
        'meal_plan_id': planId,
        'recipe_id': meal.recipeId,
        'planned_date': plannedDate.toIso8601String().split('T').first,
        'meal_type': meal.mealType,
        'servings': meal.servings > 0 ? meal.servings : defaultServings,
        'reason_codes': [meal.reasonSummary],
        'is_completed': false,
        'created_at': now.toIso8601String(),
      });
    }

    if (itemsToInsert.isNotEmpty) {
      await _client.from('meal_plan_items').insert(itemsToInsert);
    }

    return MealPlanEntity.fromJson(planResponse);
  }

  DateTime _computeDateForDay(String dayName, DateTime reference) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final targetIndex = days.indexOf(dayName.toLowerCase());
    if (targetIndex == -1) return reference;

    final currentWeekday = reference.weekday - 1; // 0 = Mon, 6 = Sun
    final diff = targetIndex - currentWeekday;
    return reference.add(Duration(days: diff));
  }
}

final mealPlanRepositoryProvider = Provider<IMealPlanRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MealPlanRepository(client);
});
