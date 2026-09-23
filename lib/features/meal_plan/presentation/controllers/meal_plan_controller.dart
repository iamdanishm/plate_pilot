import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/features/home/data/home_repository.dart';
import 'package:plate_pilot/features/meal_plan/data/meal_plan_ai_service.dart';
import 'package:plate_pilot/features/meal_plan/data/meal_plan_repository.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_proposal_entity.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';

class MealPlanState {
  final bool isGenerating;
  final bool isSwapping;
  final bool isSaving;
  final bool isSaved;
  final bool isInitialized;
  final String? swappingDay;
  final MealPlanProposalEntity? proposal;
  final String? errorMessage;
  final String? successMessage;

  const MealPlanState({
    this.isGenerating = false,
    this.isSwapping = false,
    this.isSaving = false,
    this.isSaved = false,
    this.isInitialized = false,
    this.swappingDay,
    this.proposal,
    this.errorMessage,
    this.successMessage,
  });

  MealPlanState copyWith({
    bool? isGenerating,
    bool? isSwapping,
    bool? isSaving,
    bool? isSaved,
    bool? isInitialized,
    String? swappingDay,
    MealPlanProposalEntity? proposal,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return MealPlanState(
      isGenerating: isGenerating ?? this.isGenerating,
      isSwapping: isSwapping ?? this.isSwapping,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      isInitialized: isInitialized ?? this.isInitialized,
      swappingDay: swappingDay ?? this.swappingDay,
      proposal: proposal ?? this.proposal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class MealPlanController extends StateNotifier<MealPlanState> {
  final IMealPlanAiService _aiService;
  final IMealPlanRepository _repository;
  final String _householdId;
  final int _defaultServings;
  final Ref? _ref;

  MealPlanController(
    this._aiService,
    this._repository,
    this._householdId,
    this._defaultServings, [
    this._ref,
  ]) : super(const MealPlanState()) {
    loadActivePlan();
  }

  Future<void> loadActivePlan() async {
    if (_householdId.isEmpty || _householdId == 'default') {
      state = state.copyWith(isInitialized: true);
      return;
    }

    try {
      final existingPlan =
          await _repository.getActiveMealPlanProposal(_householdId);
      if (existingPlan != null && state.proposal == null) {
        state = state.copyWith(
          proposal: existingPlan,
          isSaved: true,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (_) {
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> generatePlan() async {
    if (_householdId.isEmpty || _householdId == 'default') return;

    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final proposal = await _aiService.generateMealPlanProposal(_householdId);
      final scaledMeals = proposal.plannedMeals.map((m) {
        return m.copyWith(
          servings: _defaultServings > 0 ? _defaultServings : 2,
        );
      }).toList();

      state = state.copyWith(
        isGenerating: false,
        proposal: MealPlanProposalEntity(
          weekSummary: proposal.weekSummary,
          plannedMeals: scaledMeals,
        ),
        isSaved: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> swapMeal({
    required String targetDay,
    required String targetMealType,
    required String reason,
  }) async {
    if (_householdId.isEmpty || state.proposal == null) return;

    state = state.copyWith(
      isSwapping: true,
      swappingDay: targetDay,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final swapResult = await _aiService.requestMealSwap(
        householdId: _householdId,
        targetDay: targetDay,
        targetMealType: targetMealType,
        swapReason: reason,
        currentPlanSummary: state.proposal?.weekSummary,
      );

      final updatedMeals = state.proposal!.plannedMeals.map((meal) {
        if (meal.day.toLowerCase() == targetDay.toLowerCase()) {
          return PlannedMealProposal(
            day: meal.day,
            mealType: meal.mealType,
            recipeId: swapResult.replacementRecipeId,
            recipeTitle: swapResult.replacementRecipeTitle,
            reasonSummary: swapResult.reasonSummary,
            servings: meal.servings > 0 ? meal.servings : _defaultServings,
          );
        }
        return meal;
      }).toList();

      final updatedProposal = MealPlanProposalEntity(
        weekSummary: state.proposal!.weekSummary,
        plannedMeals: updatedMeals,
      );

      state = state.copyWith(
        isSwapping: false,
        swappingDay: null,
        proposal: updatedProposal,
        isSaved: false, // User swapped a meal, proposal is modified and can be confirmed
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSwapping: false,
        swappingDay: null,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> confirmPlan() async {
    if (_householdId.isEmpty || state.proposal == null) return false;

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _repository.saveConfirmedMealPlan(
        householdId: _householdId,
        proposal: state.proposal!,
        defaultServings: _defaultServings > 0 ? _defaultServings : 2,
      );

      state = state.copyWith(
        isSaving: false,
        isSaved: true,
        successMessage: 'Weekly plan confirmed and saved to your household!',
        clearError: true,
      );

      // Invalidate home screen active plan cache so dashboard reflects it immediately
      _ref?.invalidate(homeActiveMealPlanProvider(_householdId));
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save plan: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }
}

final mealPlanControllerProvider = StateNotifierProvider.family<
    MealPlanController, MealPlanState, String>((ref, householdId) {
  final aiService = ref.watch(mealPlanAiServiceProvider);
  final repo = ref.watch(mealPlanRepositoryProvider);
  final household = ref.watch(currentUserHouseholdProvider).asData?.value;
  final servings = household != null ? (household.adultsCount + household.childrenCount) : 2;
  return MealPlanController(aiService, repo, householdId, servings, ref);
});
