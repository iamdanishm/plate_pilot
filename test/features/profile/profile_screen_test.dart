import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/profile/presentation/screens/profile_screen.dart';

class FakeProfileAuthRepo implements IAuthRepository {
  bool signOutCalled = false;

  @override
  UserEntity? get currentUser => const UserEntity(id: 'user_p1', email: 'dan@platepilot.app');

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(currentUser);

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async => currentUser!;

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async => currentUser!;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class FakeProfileHouseholdRepo implements IHouseholdRepository {
  final household = HouseholdEntity(
    id: 'h_p1',
    ownerId: 'user_p1',
    name: 'Sharma Household',
    adultsCount: 3,
    childrenCount: 1,
    dietaryRestrictions: ['Vegetarian'],
    allergens: [
      {'id': 'peanuts', 'name': 'Peanuts'}
    ],
    weeklyBudget: 4500,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Future<HouseholdEntity?> getCurrentUserHousehold(String userId) async => household;

  @override
  Future<List<Map<String, dynamic>>> fetchMasterAllergens() async => [];

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
  }) async => household;

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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders real household name, email, and configured values', (tester) async {
      final fakeAuth = FakeProfileAuthRepo();
      final fakeHousehold = FakeProfileHouseholdRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            currentUserHouseholdProvider.overrideWith((ref) async => fakeHousehold.household),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Household Profile'), findsOneWidget);
      expect(find.text('Sharma Household'), findsOneWidget);
      expect(find.text('dan@platepilot.app'), findsOneWidget);
      expect(find.text('3 Adults • 1 Children'), findsOneWidget);
      expect(find.text('₹4500 / week'), findsOneWidget);
    });

    testWidgets('tapping Family Members opens in-place edit sheet', (tester) async {
      final fakeAuth = FakeProfileAuthRepo();
      final fakeHousehold = FakeProfileHouseholdRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            currentUserHouseholdProvider.overrideWith((ref) async => fakeHousehold.household),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Family Members'));
      await tester.pumpAndSettle();

      // Verified bottom sheet opened with title and save button
      expect(find.text('Adjust portion scaling across all planned meals.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Sign Out opens dialog and calls signOut on confirmation', (tester) async {
      final fakeAuth = FakeProfileAuthRepo();
      final fakeHousehold = FakeProfileHouseholdRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            currentUserHouseholdProvider.overrideWith((ref) async => fakeHousehold.household),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll until Sign Out tile is visible and tap it
      await tester.scrollUntilVisible(find.text('Sign Out'), 100);
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out of PlatePilot?'), findsOneWidget);

      // Confirm sign out in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(fakeAuth.signOutCalled, isTrue);
    });
  });
}
