import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/home/data/home_repository.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/routing/app_router.dart';
import 'package:plate_pilot/shared/widgets/app_scaffold.dart';

class FakeAuthForScaffold implements IAuthRepository {
  final UserEntity user;
  FakeAuthForScaffold(this.user);

  @override
  UserEntity? get currentUser => user;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(user);

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async => user;

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async => user;

  @override
  Future<void> signOut() async {}
}

class FakeHouseholdForScaffold implements IHouseholdRepository {
  final HouseholdEntity household;
  FakeHouseholdForScaffold(this.household);

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

  const testUser = UserEntity(id: 'u_scaffold', email: 'scaffold@test.com');
  final testHousehold = HouseholdEntity(
    id: 'h_scaffold_1',
    ownerId: 'u_scaffold',
    name: 'Scaffold Household',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('AppScaffold Navigation Shell Tests', () {
    testWidgets('renders all 5 navigation destinations and grocery badge', (tester) async {
      final fakeAuth = FakeAuthForScaffold(testUser);
      final fakeHousehold = FakeHouseholdForScaffold(testHousehold);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            authStateChangesProvider.overrideWith((ref) => Stream.value(testUser)),
            currentUserHouseholdProvider.overrideWith((ref) async => testHousehold),
            homeGroceryCountProvider('h_scaffold_1').overrideWith((ref) async => 5),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppScaffold is mounted
      expect(find.byType(AppScaffold), findsOneWidget);

      // Verify all 5 navigation labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Pantry'), findsOneWidget);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify grocery badge with count '5' is rendered
      expect(find.text('5'), findsOneWidget);
    });
  });
}
