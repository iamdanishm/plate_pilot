import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/onboarding/presentation/controllers/onboarding_controller.dart';

class MockHouseholdRepository implements IHouseholdRepository {
  bool shouldFail = false;
  Map<String, dynamic>? lastCreatedProfile;

  @override
  Future<HouseholdEntity?> getCurrentUserHousehold(String userId) async {
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMasterAllergens() async {
    return [
      {'id': 'dairy', 'name': 'Dairy', 'common_terms': ['milk', 'cheese']},
      {'id': 'gluten', 'name': 'Gluten', 'common_terms': ['wheat', 'flour']},
    ];
  }

  @override
  Future<HouseholdEntity> createHouseholdWithProfile({
    required String userId,
    required String householdName,
    required int adultsCount,
    required int childrenCount,
    required List<String> dietaryRestrictions,
    required List<Map<String, dynamic>> allergens,
    required List<String> preferredCuisines,
    required int maxWeekdayCookingTime,
    required int maxWeekendCookingTime,
    required double weeklyBudget,
    required String currency,
  }) async {
    if (shouldFail) throw Exception('Database constraint error');

    lastCreatedProfile = {
      'userId': userId,
      'householdName': householdName,
      'adultsCount': adultsCount,
      'childrenCount': childrenCount,
      'dietaryRestrictions': dietaryRestrictions,
      'allergens': allergens,
      'preferredCuisines': preferredCuisines,
      'maxWeekdayCookingTime': maxWeekdayCookingTime,
      'maxWeekendCookingTime': maxWeekendCookingTime,
      'weeklyBudget': weeklyBudget,
      'currency': currency,
    };

    return HouseholdEntity(
      id: 'household_abc_123',
      ownerId: userId,
      name: householdName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateHouseholdMembers({
    required String householdId,
    required int adultsCount,
    required int childrenCount,
    List<String> dietaryRestrictions = const [],
  }) async {}

  @override
  Future<void> updateWeeklyBudget({
    required String householdId,
    required double weeklyBudget,
  }) async {}
}

void main() {
  group('OnboardingController Tests', () {
    test('default state has expected initial values', () {
      final mockRepo = MockHouseholdRepository();
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final state = container.read(onboardingControllerProvider);
      expect(state.currentStep, 0);
      expect(state.householdName, 'My Household');
      expect(state.adultsCount, 2);
      expect(state.childrenCount, 0);
      expect(state.selectedDiets, contains('vegetarian'));
      expect(state.weeklyBudget, 3000.0);
    });

    test('step progression and updates work correctly', () {
      final mockRepo = MockHouseholdRepository();
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(onboardingControllerProvider.notifier);

      // Step 0 updates
      controller.setHouseholdName('Patel Family');
      controller.setAdultsCount(3);
      controller.setChildrenCount(2);

      var state = container.read(onboardingControllerProvider);
      expect(state.householdName, 'Patel Family');
      expect(state.adultsCount, 3);
      expect(state.childrenCount, 2);

      // Next step
      expect(controller.nextStep(), true);
      state = container.read(onboardingControllerProvider);
      expect(state.currentStep, 1);

      // Step 1: Diets & Allergens
      controller.toggleDiet('vegan');
      controller.toggleAllergen('peanuts', isHard: true);
      state = container.read(onboardingControllerProvider);
      expect(state.selectedDiets, contains('vegan'));
      expect(state.selectedAllergens['peanuts'], true);

      // Next step
      expect(controller.nextStep(), true);
      state = container.read(onboardingControllerProvider);
      expect(state.currentStep, 2);

      // Step 2: Cuisines and times
      controller.toggleCuisine('Gujarati');
      controller.setCookingTimes(weekday: 30, weekend: 90);
      state = container.read(onboardingControllerProvider);
      expect(state.selectedCuisines, contains('Gujarati'));
      expect(state.maxWeekdayCookingTime, 30);
      expect(state.maxWeekendCookingTime, 90);

      // Next step
      expect(controller.nextStep(), true);
      state = container.read(onboardingControllerProvider);
      expect(state.currentStep, 3);

      // Step 3: Budget
      controller.setBudget(4500.0);
      state = container.read(onboardingControllerProvider);
      expect(state.weeklyBudget, 4500.0);

      // At step 3, nextStep returns false
      expect(controller.nextStep(), false);
      // previousStep goes back
      expect(controller.previousStep(), true);
      expect(container.read(onboardingControllerProvider).currentStep, 2);
    });

    test('submitOnboarding persists profile and sets isCompleted', () async {
      final mockRepo = MockHouseholdRepository();
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(onboardingControllerProvider.notifier);
      controller.setHouseholdName('Verma Household');
      controller.setBudget(5000.0);

      final result = await controller.submitOnboarding('user_999');

      expect(result, isNotNull);
      expect(result?.id, 'household_abc_123');
      expect(result?.name, 'Verma Household');

      final state = container.read(onboardingControllerProvider);
      expect(state.isCompleted, true);
      expect(state.isSubmitting, false);
      expect(state.errorMessage, isNull);

      expect(mockRepo.lastCreatedProfile?['userId'], 'user_999');
      expect(mockRepo.lastCreatedProfile?['householdName'], 'Verma Household');
      expect(mockRepo.lastCreatedProfile?['weeklyBudget'], 5000.0);
    });

    test('submitOnboarding failure sets errorMessage', () async {
      final mockRepo = MockHouseholdRepository()..shouldFail = true;
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(onboardingControllerProvider.notifier);
      final result = await controller.submitOnboarding('user_999');

      expect(result, isNull);
      final state = container.read(onboardingControllerProvider);
      expect(state.isCompleted, false);
      expect(state.isSubmitting, false);
      expect(state.errorMessage, contains('Database constraint error'));
    });

    test('submitOnboarding preserves standard allergen identifiers correctly', () async {
      final mockRepo = MockHouseholdRepository();
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(onboardingControllerProvider.notifier);
      controller.toggleAllergen('egg', isHard: true);
      controller.toggleAllergen('fish', isHard: true);
      controller.toggleAllergen('shellfish', isHard: true);

      final result = await controller.submitOnboarding('user_allergy_test');
      expect(result, isNotNull);

      final submittedAllergens = mockRepo.lastCreatedProfile?['allergens'] as List<Map<String, dynamic>>?;
      expect(submittedAllergens, isNotNull);
      expect(submittedAllergens?.length, 3);
      final allergenIds = submittedAllergens?.map((a) => a['allergen_id']).toList();
      expect(allergenIds, containsAll(['egg', 'fish', 'shellfish']));
    });
  });
}
