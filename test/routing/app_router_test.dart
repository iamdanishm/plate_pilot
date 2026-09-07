import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/auth/presentation/screens/login_screen.dart';
import 'package:plate_pilot/features/auth/presentation/screens/splash_screen.dart';
import 'package:plate_pilot/features/home/presentation/screens/home_screen.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:plate_pilot/routing/app_router.dart';

class FakeAuthRepoForRouter implements IAuthRepository {
  UserEntity? user;
  FakeAuthRepoForRouter([this.user]);

  @override
  UserEntity? get currentUser => user;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(user);

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async =>
      UserEntity(id: 'u_1', email: email);

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async =>
      UserEntity(id: 'u_1', email: email);

  @override
  Future<void> signOut() async {
    user = null;
  }
}

class FakeHouseholdRepoForRouter implements IHouseholdRepository {
  HouseholdEntity? household;
  FakeHouseholdRepoForRouter([this.household]);

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
  }) async {
    return HouseholdEntity(
      id: 'h_1',
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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppRouter Lifecycle & Guard Tests', () {
    testWidgets('initial boot shows SplashScreen while auth resolves', (tester) async {
      final fakeAuth = FakeAuthRepoForRouter(null);
      final fakeHousehold = FakeHouseholdRepoForRouter(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            authStateChangesProvider.overrideWith((ref) => const Stream.empty()), // In-flight loading
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
      await tester.pump();

      // Verified SplashScreen is the initial view
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
    });

    testWidgets('when authenticated user is checking household, stays on SplashScreen without flashing HomeScreen', (tester) async {
      const testUser = UserEntity(id: 'u_temp', email: 'test@user.com');
      final fakeAuth = FakeAuthRepoForRouter(testUser);
      final fakeHousehold = FakeHouseholdRepoForRouter(null);
      final completer = Completer<HouseholdEntity?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            authStateChangesProvider.overrideWith((ref) => Stream.value(testUser)),
            currentUserHouseholdProvider.overrideWith((ref) => completer.future), // In-flight household query
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
      await tester.pump();

      // Verified stays on SplashScreen and NEVER flashes HomeScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      // Now complete the household query as null
      completer.complete(null);
      await tester.pumpAndSettle();

      // Smoothly transitions directly to OnboardingScreen
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('unauthenticated user is redirected to /login', (tester) async {
      final fakeAuth = FakeAuthRepoForRouter(null);
      final fakeHousehold = FakeHouseholdRepoForRouter(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
            currentUserHouseholdProvider.overrideWith((ref) async => null),
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

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('authenticated user without household is redirected to /onboarding', (tester) async {
      const testUser = UserEntity(id: 'user_new', email: 'new@user.com');
      final fakeAuth = FakeAuthRepoForRouter(testUser);
      final fakeHousehold = FakeHouseholdRepoForRouter(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            authStateChangesProvider.overrideWith((ref) => Stream.value(testUser)),
            currentUserHouseholdProvider.overrideWith((ref) async => null),
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

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Setup Household (1/4)'), findsOneWidget);
    });

    testWidgets('authenticated user with household accesses / (HomeScreen)', (tester) async {
      const testUser = UserEntity(id: 'user_onboarded', email: 'done@user.com');
      final testHousehold = HouseholdEntity(
        id: 'h_123',
        ownerId: 'user_onboarded',
        name: 'The Cook Family',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final fakeAuth = FakeAuthRepoForRouter(testUser);
      final fakeHousehold = FakeHouseholdRepoForRouter(testHousehold);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            authStateChangesProvider.overrideWith((ref) => Stream.value(testUser)),
            currentUserHouseholdProvider.overrideWith((ref) async => testHousehold),
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

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Ready to optimize this week?'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('when auth guard is disabled, navigates to HomeScreen directly', (tester) async {
      final fakeAuth = FakeAuthRepoForRouter(null);
      final fakeHousehold = FakeHouseholdRepoForRouter(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            householdRepositoryProvider.overrideWithValue(fakeHousehold),
            routerAuthGuardEnabledProvider.overrideWithValue(false),
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

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Ready to optimize this week?'), findsOneWidget);
    });
  });
}
