import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe_entity.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  late final TextEditingController _searchController;

  static const List<String> _cuisines = [
    'All',
    'Indian',
    'North Indian',
    'South Indian',
    'Continental',
    'Italian',
    'Bengali',
    'Maharashtrian',
    'Kerala',
  ];

  static const List<String> _diets = [
    'All',
    'Vegetarian',
    'Non Vegeterian',
    'Vegan',
    'Eggetarian',
    'High Protein',
  ];

  static const List<int?> _timeLimits = [
    null,
    30,
    45,
    60,
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(recipeSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipesAsync = ref.watch(recipesListProvider);
    final selectedCuisine = ref.watch(recipeSelectedCuisineProvider);
    final selectedDiet = ref.watch(recipeSelectedDietProvider);
    final selectedTime = ref.watch(recipeSelectedMaxTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore Recipes',
          style: AppTheme.fontStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search 6,800+ recipes, dishes...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(recipeSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(recipeSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Cuisine Dropdown / Chips
                ..._cuisines.map((c) {
                  final isSelected = selectedCuisine == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(recipeSelectedCuisineProvider.notifier).state =
                            selected ? c : 'All';
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Secondary Diet & Time Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Diet Filters
                ..._diets.map((d) {
                  final isSelected = selectedDiet == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(recipeSelectedDietProvider.notifier).state =
                            selected ? d : 'All';
                      },
                    ),
                  );
                }),

                // Time Limits
                ..._timeLimits.map((t) {
                  final isSelected = selectedTime == t;
                  final label = t == null ? 'Any Time' : '≤$t mins';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(recipeSelectedMaxTimeProvider.notifier).state =
                            selected ? t : null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Recipe Results List
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(recipesListProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return _buildRecipeCard(
                          context, recipe, isIOS, isDark);
                    },
                  ),
                );
              },
              loading: () => _buildLoadingSkeleton(isIOS),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load recipes',
                        style: AppTheme.fontStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(recipesListProvider),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    RecipeEntity recipe,
    bool isIOS,
    bool isDark,
  ) {
    final timeStr = recipe.computedTotalTimeMinutes > 0
        ? '${recipe.computedTotalTimeMinutes} mins'
        : 'Quick';

    final content = Row(
      children: [
        // Recipe Icon / Thumbnail
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: AppTheme.primaryEmerald,
            size: 32,
          ),
        ),
        const SizedBox(width: 14),

        // Recipe Metadata
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
                '${recipe.cuisine ?? 'Indian'} • ${recipe.course ?? 'Main Course'}',
                style: AppTheme.fontStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 12, color: AppTheme.secondaryAmberDark),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: AppTheme.fontStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryAmberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (recipe.diet != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe.diet!,
                        style: AppTheme.fontStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryEmeraldDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        onTap: () => context.push('/recipes/${recipe.id}'),
        padding: const EdgeInsets.all(12),
        child: content,
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/recipes/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No recipes found',
              style: AppTheme.fontStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing keywords or clearing selected cuisine/diet filters.',
              textAlign: TextAlign.center,
              style: AppTheme.fontStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                ref.read(recipeSearchQueryProvider.notifier).state = '';
                ref.read(recipeSelectedCuisineProvider.notifier).state = 'All';
                ref.read(recipeSelectedDietProvider.notifier).state = 'All';
                ref.read(recipeSelectedMaxTimeProvider.notifier).state = null;
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isIOS) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
