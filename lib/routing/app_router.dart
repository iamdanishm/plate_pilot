import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/auth/presentation/screens/login_screen.dart';
import 'package:plate_pilot/features/auth/presentation/screens/register_screen.dart';
import 'package:plate_pilot/features/auth/presentation/screens/splash_screen.dart';
import 'package:plate_pilot/features/grocery/presentation/screens/grocery_screen.dart';
import 'package:plate_pilot/features/home/presentation/screens/home_screen.dart';
import 'package:plate_pilot/features/meal_plan/presentation/screens/meal_plan_screen.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:plate_pilot/features/pantry/presentation/screens/pantry_screen.dart';
import 'package:plate_pilot/features/profile/presentation/screens/profile_screen.dart';
import 'package:plate_pilot/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:plate_pilot/features/recipes/presentation/screens/recipes_screen.dart';
import 'package:plate_pilot/shared/widgets/app_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// Provider to toggle router redirect guard in tests if needed
final routerAuthGuardEnabledProvider = Provider<bool>((ref) => true);

/// Listenable notifier bridging Riverpod auth & household streams with GoRouter.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserEntity?>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AsyncValue<HouseholdEntity?>>(
      currentUserHouseholdProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<bool>(
      routerAuthGuardEnabledProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isAuthGuardEnabled = _ref.read(routerAuthGuardEnabledProvider);
    final location = state.matchedLocation;
    if (!isAuthGuardEnabled) {
      if (location == '/splash') return '/';
      return null;
    }

    final authState = _ref.read(authStateChangesProvider);

    final isAuthRoute = location == '/login' || location == '/register';
    final isSplashRoute = location == '/splash';
    final isOnboardingRoute = location == '/onboarding';

    // 1. If auth state is still loading, stay on splash screen
    if (authState.isLoading) {
      return isSplashRoute ? null : '/splash';
    }

    final user = authState.asData?.value;

    // 2. If not authenticated:
    if (user == null) {
      if (isAuthRoute) return null;
      return '/login';
    }

    // 3. If authenticated, check household profile
    final householdState = _ref.read(currentUserHouseholdProvider);

    // If household is still loading, stay on splash screen to prevent flashing HomeScreen
    if (householdState.isLoading) {
      return isSplashRoute ? null : '/splash';
    }

    final hasHousehold = householdState.asData?.value != null;

    // 4. Authenticated without household -> route to onboarding
    if (!hasHousehold) {
      if (isOnboardingRoute) return null;
      return '/onboarding';
    }

    // 5. Authenticated with household -> route away from auth, onboarding, and splash to home
    if (isAuthRoute || isOnboardingRoute || isSplashRoute) {
      return '/';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

/// Provider for the application's GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: notifier.redirect,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Recipe Catalog & Detail Routes
      GoRoute(
        path: '/recipes',
        name: 'recipes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RecipesScreen(),
      ),
      GoRoute(
        path: '/recipes/:id',
        name: 'recipe_detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final servingsParam = state.uri.queryParameters['servings'];
          final initialServings = servingsParam != null ? int.tryParse(servingsParam) : null;
          return RecipeDetailScreen(recipeId: id, initialServings: initialServings);
        },
      ),

      // Main Navigation Shell (StatefulShellRoute with 5 Branches)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Meal Plan
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meal-plan',
                name: 'meal_plan',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MealPlanScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Pantry
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pantry',
                name: 'pantry',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PantryScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Grocery
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/grocery',
                name: 'grocery',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: GroceryScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
