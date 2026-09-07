import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';

class OnboardingFormState {
  final int currentStep;
  final String householdName;
  final int adultsCount;
  final int childrenCount;
  final List<String> selectedDiets;
  final Map<String, bool> selectedAllergens; // allergenId -> isHardConstraint
  final List<String> selectedCuisines;
  final int maxWeekdayCookingTime;
  final int maxWeekendCookingTime;
  final double weeklyBudget;
  final String currency;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isCompleted;

  const OnboardingFormState({
    this.currentStep = 0,
    this.householdName = 'My Household',
    this.adultsCount = 2,
    this.childrenCount = 0,
    this.selectedDiets = const ['vegetarian'],
    this.selectedAllergens = const {},
    this.selectedCuisines = const ['North Indian', 'South Indian'],
    this.maxWeekdayCookingTime = 45,
    this.maxWeekendCookingTime = 60,
    this.weeklyBudget = 3000.0,
    this.currency = 'INR',
    this.isSubmitting = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  OnboardingFormState copyWith({
    int? currentStep,
    String? householdName,
    int? adultsCount,
    int? childrenCount,
    List<String>? selectedDiets,
    Map<String, bool>? selectedAllergens,
    List<String>? selectedCuisines,
    int? maxWeekdayCookingTime,
    int? maxWeekendCookingTime,
    double? weeklyBudget,
    String? currency,
    bool? isSubmitting,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return OnboardingFormState(
      currentStep: currentStep ?? this.currentStep,
      householdName: householdName ?? this.householdName,
      adultsCount: adultsCount ?? this.adultsCount,
      childrenCount: childrenCount ?? this.childrenCount,
      selectedDiets: selectedDiets ?? this.selectedDiets,
      selectedAllergens: selectedAllergens ?? this.selectedAllergens,
      selectedCuisines: selectedCuisines ?? this.selectedCuisines,
      maxWeekdayCookingTime:
          maxWeekdayCookingTime ?? this.maxWeekdayCookingTime,
      maxWeekendCookingTime:
          maxWeekendCookingTime ?? this.maxWeekendCookingTime,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      currency: currency ?? this.currency,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingFormState> {
  final IHouseholdRepository _householdRepository;
  final Ref _ref;

  OnboardingController(this._householdRepository, this._ref)
      : super(const OnboardingFormState());

  void setHouseholdName(String name) {
    state = state.copyWith(householdName: name);
  }

  void setAdultsCount(int count) {
    if (count < 1) return;
    state = state.copyWith(adultsCount: count);
  }

  void setChildrenCount(int count) {
    if (count < 0) return;
    state = state.copyWith(childrenCount: count);
  }

  void toggleDiet(String diet) {
    final diets = List<String>.from(state.selectedDiets);
    if (diets.contains(diet)) {
      if (diets.length > 1) {
        diets.remove(diet);
      }
    } else {
      diets.add(diet);
    }
    state = state.copyWith(selectedDiets: diets);
  }

  void toggleAllergen(String allergenId, {bool isHard = true}) {
    final allergens = Map<String, bool>.from(state.selectedAllergens);
    if (allergens.containsKey(allergenId)) {
      allergens.remove(allergenId);
    } else {
      allergens[allergenId] = isHard;
    }
    state = state.copyWith(selectedAllergens: allergens);
  }

  void toggleCuisine(String cuisine) {
    final cuisines = List<String>.from(state.selectedCuisines);
    if (cuisines.contains(cuisine)) {
      if (cuisines.length > 1) {
        cuisines.remove(cuisine);
      }
    } else {
      cuisines.add(cuisine);
    }
    state = state.copyWith(selectedCuisines: cuisines);
  }

  void setCookingTimes({int? weekday, int? weekend}) {
    state = state.copyWith(
      maxWeekdayCookingTime: weekday ?? state.maxWeekdayCookingTime,
      maxWeekendCookingTime: weekend ?? state.maxWeekendCookingTime,
    );
  }

  void setBudget(double budget) {
    if (budget < 500) return;
    state = state.copyWith(weeklyBudget: budget);
  }

  bool nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      return true;
    }
    return false;
  }

  bool previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      return true;
    }
    return false;
  }

  Future<HouseholdEntity?> submitOnboarding(String userId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final allergensList = state.selectedAllergens.entries.map((e) {
        return {
          'allergen_id': e.key,
          'is_hard_constraint': e.value,
        };
      }).toList();

      final household = await _householdRepository.createHouseholdWithProfile(
        userId: userId,
        householdName: state.householdName,
        adultsCount: state.adultsCount,
        childrenCount: state.childrenCount,
        dietaryRestrictions: state.selectedDiets,
        allergens: allergensList,
        preferredCuisines: state.selectedCuisines,
        maxWeekdayCookingTime: state.maxWeekdayCookingTime,
        maxWeekendCookingTime: state.maxWeekendCookingTime,
        weeklyBudget: state.weeklyBudget,
        currency: state.currency,
      );

      _ref.invalidate(currentUserHouseholdProvider);

      state = state.copyWith(
        isSubmitting: false,
        isCompleted: true,
      );

      return household;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingFormState>((ref) {
  final householdRepo = ref.watch(householdRepositoryProvider);
  return OnboardingController(householdRepo, ref);
});
