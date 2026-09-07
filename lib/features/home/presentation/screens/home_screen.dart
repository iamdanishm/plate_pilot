import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../onboarding/data/household_repository.dart';
import '../../../onboarding/domain/household_entity.dart';
import '../../../recipes/domain/recipe_entity.dart';
import '../../data/home_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = AppTheme.isIOS;
    final householdAsync = ref.watch(currentUserHouseholdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: AppTheme.fontStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: householdAsync.when(
        data: (household) {
          final effectiveHousehold = household ??
              HouseholdEntity(
                id: 'default',
                ownerId: 'default',
                name: 'My Household',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
          return _buildDashboard(
              context, ref, effectiveHousehold, isIOS, isDark);
        },
        loading: () => _buildDashboardSkeleton(context, isIOS),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load household details',
                  style: AppTheme.fontStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentUserHouseholdProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    HouseholdEntity household,
    bool isIOS,
    bool isDark,
  ) {
    final pantryCountAsync = ref.watch(homePantryCountProvider(household.id));
    final groceryCountAsync = ref.watch(homeGroceryCountProvider(household.id));
    final activeMealPlanAsync =
        ref.watch(homeActiveMealPlanProvider(household.id));
    final recipesAsync =
        ref.watch(homeRecommendedRecipesProvider(household.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserHouseholdProvider);
        ref.invalidate(homePantryCountProvider(household.id));
        ref.invalidate(homeGroceryCountProvider(household.id));
        ref.invalidate(homeActiveMealPlanProvider(household.id));
        ref.invalidate(homeRecommendedRecipesProvider(household.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Household Welcome Header
            _buildWelcomeHeader(context, household),
            const SizedBox(height: 20),

            // Hero Banner: Plan Your Week / Active Meal Plan
            activeMealPlanAsync.when(
              data: (plan) => _buildHeroBanner(context, isIOS, plan != null),
              loading: () => _buildHeroBanner(context, isIOS, false),
              error: (_, __) => _buildHeroBanner(context, isIOS, false),
            ),
            const SizedBox(height: 24),

            // Today's Meal Plan Card
            Text(
              "Today's Meals",
              style: AppTheme.fontStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            activeMealPlanAsync.when(
              data: (plan) => _buildTodayMealCard(
                context,
                isIOS,
                isDark,
                hasActivePlan: plan != null,
              ),
              loading: () => _buildTodayMealCard(
                context,
                isIOS,
                isDark,
                hasActivePlan: false,
              ),
              error: (_, __) => _buildTodayMealCard(
                context,
                isIOS,
                isDark,
                hasActivePlan: false,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats Row (Pantry, Grocery, Budget)
            Row(
              children: [
                Expanded(
                  child: pantryCountAsync.when(
                    data: (count) => _buildStatCard(
                      context,
                      title: 'Pantry Items',
                      value: '$count tracked',
                      icon: Icons.kitchen_rounded,
                      color: AppTheme.primaryEmerald,
                      onTap: () => context.go('/pantry'),
                      isIOS: isIOS,
                    ),
                    loading: () => _buildStatCard(
                      context,
                      title: 'Pantry Items',
                      value: '...',
                      icon: Icons.kitchen_rounded,
                      color: AppTheme.primaryEmerald,
                      onTap: () => context.go('/pantry'),
                      isIOS: isIOS,
                    ),
                    error: (_, __) => _buildStatCard(
                      context,
                      title: 'Pantry Items',
                      value: '0 tracked',
                      icon: Icons.kitchen_rounded,
                      color: AppTheme.primaryEmerald,
                      onTap: () => context.go('/pantry'),
                      isIOS: isIOS,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: groceryCountAsync.when(
                    data: (count) => _buildStatCard(
                      context,
                      title: 'Grocery List',
                      value: '$count pending',
                      icon: Icons.shopping_basket_rounded,
                      color: AppTheme.secondaryAmberDark,
                      onTap: () => context.go('/grocery'),
                      isIOS: isIOS,
                    ),
                    loading: () => _buildStatCard(
                      context,
                      title: 'Grocery List',
                      value: '...',
                      icon: Icons.shopping_basket_rounded,
                      color: AppTheme.secondaryAmberDark,
                      onTap: () => context.go('/grocery'),
                      isIOS: isIOS,
                    ),
                    error: (_, __) => _buildStatCard(
                      context,
                      title: 'Grocery List',
                      value: '0 pending',
                      icon: Icons.shopping_basket_rounded,
                      color: AppTheme.secondaryAmberDark,
                      onTap: () => context.go('/grocery'),
                      isIOS: isIOS,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Weekly Budget',
                    value: '₹${household.weeklyBudget.toInt()}',
                    icon: Icons.savings_rounded,
                    color: Colors.blueAccent,
                    onTap: () => context.go('/profile'),
                    isIOS: isIOS,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recommended for Tonight Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended for Tonight',
                  style: AppTheme.fontStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/recipes'),
                  child: const Text('Explore All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return _buildEmptyRecipesCard(context, isIOS);
                }
                return Column(
                  children: recipes
                      .map((recipe) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRecipeItemCard(
                                context, recipe, isIOS, isDark),
                          ))
                      .toList(),
                );
              },
              loading: () => _buildRecipeSkeletonCard(context, isIOS),
              error: (_, __) => _buildEmptyRecipesCard(context, isIOS),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSkeleton(BuildContext context, bool isIOS) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isIOS ? 20 : 28),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSkeletonCard(BuildContext context, bool isIOS) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, HouseholdEntity household) {
    final membersText = StringBuffer();
    membersText.write('${household.adultsCount} Adult${household.adultsCount > 1 ? 's' : ''}');
    if (household.childrenCount > 0) {
      membersText.write(', ${household.childrenCount} Child${household.childrenCount > 1 ? 'ren' : ''}');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: AppTheme.fontStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                household.name,
                style: AppTheme.fontStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      membersText.toString(),
                      style: AppTheme.fontStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmeraldDark,
                      ),
                    ),
                  ),
                  if (household.dietaryRestrictions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        household.dietaryRestrictions.first
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w.isNotEmpty
                                ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
                                : '')
                            .join(' '),
                        style: AppTheme.fontStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryAmberDark,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => context.go('/profile'),
          tooltip: 'Household Settings',
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isIOS, bool hasActivePlan) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasActivePlan
              ? [
                  AppTheme.primaryEmeraldDark,
                  AppTheme.primaryEmerald,
                ]
              : [
                  AppTheme.primaryEmerald,
                  AppTheme.primaryEmeraldDark,
                ],
        ),
        borderRadius: BorderRadius.circular(isIOS ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasActivePlan ? 'Active Meal Plan' : 'Weekly Planner',
              style: AppTheme.fontStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasActivePlan
                ? 'Your Week is Planned & Ready!'
                : 'Ready to optimize this week?',
            style: AppTheme.fontStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasActivePlan
                ? 'Track recipes, cooking steps, and auto-generated groceries for your household.'
                : 'Turn your pantry ingredients and weekly budget into an AI-curated meal plan.',
            style: AppTheme.fontStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => context.go('/meal-plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryEmeraldDark,
              elevation: 0,
            ),
            child: Text(
              hasActivePlan ? 'View Meal Plan' : 'Generate Meal Plan',
              style: AppTheme.fontStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMealCard(
    BuildContext context,
    bool isIOS,
    bool isDark, {
    required bool hasActivePlan,
  }) {
    final content = Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.dinner_dining_rounded,
            size: 32,
            color: AppTheme.primaryEmerald,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tonight • Dinner',
                style: AppTheme.fontStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasActivePlan
                    ? 'Paneer Tikka Masala with Roti'
                    : 'No meal planned for today',
                style: AppTheme.fontStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasActivePlan
                    ? 'Uses pantry: Paneer, Tomatoes • 30 mins'
                    : 'Generate a plan to get automatic daily recipes',
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: () => context.go('/meal-plan'),
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        onTap: () => context.go('/meal-plan'),
        padding: const EdgeInsets.all(16),
        child: content,
      );
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/meal-plan'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isIOS,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.fontStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTheme.fontStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: content,
      );
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      ),
    );
  }

  Widget _buildRecipeItemCard(
    BuildContext context,
    RecipeEntity recipe,
    bool isIOS,
    bool isDark,
  ) {
    final timeStr = recipe.computedTotalTimeMinutes > 0
        ? '${recipe.computedTotalTimeMinutes} mins'
        : 'Quick & Easy';

    final content = Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.secondaryAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.soup_kitchen_rounded,
            color: AppTheme.secondaryAmberDark,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: AppTheme.fontStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${recipe.cuisine ?? 'Indian'} • $timeStr • ${recipe.diet ?? 'Vegetarian'}',
                style: AppTheme.fontStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        onTap: () => context.push('/recipes/${recipe.id}'),
        padding: const EdgeInsets.all(14),
        child: content,
      );
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/recipes/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: content,
        ),
      ),
    );
  }

  Widget _buildEmptyRecipesCard(BuildContext context, bool isIOS) {
    final content = Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppTheme.primaryEmerald,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catalog ready with 6,800+ recipes',
                style: AppTheme.fontStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to explore and search recipes for your household.',
                style: AppTheme.fontStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        onTap: () => context.push('/recipes'),
        padding: const EdgeInsets.all(14),
        child: content,
      );
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/recipes'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: content,
        ),
      ),
    );
  }
}
