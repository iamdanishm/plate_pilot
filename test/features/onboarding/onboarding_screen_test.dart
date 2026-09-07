import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/onboarding/presentation/screens/onboarding_screen.dart';

class FakeHouseholdRepo implements IHouseholdRepository {
  bool shouldFail = false;
  Map<String, dynamic>? lastCreated;

  @override
  Future<HouseholdEntity?> getCurrentUserHousehold(String userId) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchMasterAllergens() async {
    return [
      {'id': 'peanuts', 'name': 'Peanuts'},
      {'id': 'dairy', 'name': 'Dairy'},
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
    if (shouldFail) throw Exception('Failed to create profile');

    lastCreated = {
      'householdName': householdName,
      'adultsCount': adultsCount,
      'weeklyBudget': weeklyBudget,
    };

    return HouseholdEntity(
      id: 'h_test_1',
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

class FakeAuthRepoForOnboarding implements IAuthRepository {
  @override
  UserEntity? get currentUser => const UserEntity(id: 'user_onboarding_1', email: 'test@domain.com');

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(currentUser);

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async => currentUser!;

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async => currentUser!;

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders step 1 (Household Profile) and increments adults count', (tester) async {
      final fakeRepo = FakeHouseholdRepo();
      final fakeAuth = FakeAuthRepoForOnboarding();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Setup Household (1/4)'), findsOneWidget);
      expect(find.text('Household Profile'), findsOneWidget);
      expect(find.text('Adults (12+ yrs)'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Default 2 adults

      // Tap + button to increment adults
      final incrementButtons = find.widgetWithIcon(IconButton, Icons.add_rounded);
      await tester.tap(incrementButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('navigates through 4 steps and submits profile on completion', (tester) async {
      final fakeRepo = FakeHouseholdRepo();
      final fakeAuth = FakeAuthRepoForOnboarding();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      expect(find.text('Setup Household (1/4)'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 2: Diet & Safety
      expect(find.text('Setup Household (2/4)'), findsOneWidget);
      expect(find.text('Diet & Safety'), findsOneWidget);
      expect(find.text('VEGETARIAN'), findsOneWidget);

      // Select 'VEGETARIAN' chip
      await tester.tap(find.text('VEGETARIAN'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 3: Cooking Habits
      expect(find.text('Setup Household (3/4)'), findsOneWidget);
      expect(find.text('Cooking Habits'), findsOneWidget);

      // Step 3 -> Step 4
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 4: Weekly Grocery Budget
      expect(find.text('Setup Household (4/4)'), findsOneWidget);
      expect(find.text('Weekly Grocery Budget'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save & Start Planning'), findsOneWidget);

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save & Start Planning'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreated, isNotNull);
      expect(fakeRepo.lastCreated!['adultsCount'], 2);
    });

    testWidgets('back button navigates back to previous step', (tester) async {
      final fakeRepo = FakeHouseholdRepo();
      final fakeAuth = FakeAuthRepoForOnboarding();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            householdRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Setup Household (2/4)'), findsOneWidget);

      // Tap Back in AppBar
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Back at Step 1
      expect(find.text('Setup Household (1/4)'), findsOneWidget);
      expect(find.text('Household Profile'), findsOneWidget);
    });
  });
}
