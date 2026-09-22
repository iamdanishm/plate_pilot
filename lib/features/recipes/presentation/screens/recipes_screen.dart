import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe_entity.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  bool _hasSyncedHouseholdDiet = false;
  bool _isLoadingMore = false;

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
    'No Onion No Garlic (Sattvic)',
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
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 300) {
      final currentLimit = ref.read(recipesLimitProvider);
      final currentLoaded = ref.read(recipesListProvider).asData?.value.length ?? 0;
      if (currentLoaded >= currentLimit) {
        _loadMore(currentLimit);
      }
    }
  }

  Future<void> _loadMore(int currentLimit) async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    ref.read(recipesLimitProvider.notifier).state = currentLimit + 30;
    try {
      await ref.read(recipesListProvider.future);
    } catch (_) {
      // Ignored in scroll pagination
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _syncHouseholdDietIfNeeded() {
    if (_hasSyncedHouseholdDiet) return;
    try {
      final household = ref.read(currentUserHouseholdProvider).asData?.value;
      if (household != null && household.dietaryRestrictions.isNotEmpty) {
        final diet = household.dietaryRestrictions.first.toLowerCase();
        String? mappedDiet;
        if (diet.contains('sattvic') || diet.contains('jain')) {
          mappedDiet = 'No Onion No Garlic (Sattvic)';
        } else if (diet.contains('non')) {
          mappedDiet = 'Non Vegeterian';
        } else if (diet.contains('vegan')) {
          mappedDiet = 'Vegan';
        } else if (diet.contains('egg')) {
          mappedDiet = 'Eggetarian';
        } else if (diet.contains('veg')) {
          mappedDiet = 'Vegetarian';
        }

        if (mappedDiet != null && ref.read(recipeSelectedDietProvider) == 'All') {
          Future.microtask(() {
            if (mounted) {
              ref.read(recipeSelectedDietProvider.notifier).state = mappedDiet!;
            }
          });
        }
        _hasSyncedHouseholdDiet = true;
      }
    } catch (_) {
      // Ignored if household provider is mocked or unavailable in test
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

    try {
      ref.listen(currentUserHouseholdProvider, (_, __) => _syncHouseholdDietIfNeeded());
      _syncHouseholdDietIfNeeded();
    } catch (_) {
      // Ignored in test environment
    }

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
                          ref.read(recipesLimitProvider.notifier).state = 30;
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(recipeSearchQueryProvider.notifier).state = val;
                ref.read(recipesLimitProvider.notifier).state = 30;
              },
            ),
          ),

          // Preference Filter Feedback Strip
          if (selectedDiet != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 14, color: AppTheme.primaryEmerald),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Filtered by household diet ($selectedDiet)',
                      style: AppTheme.fontStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmeraldDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(recipeSelectedDietProvider.notifier).state = 'All';
                      ref.read(recipesLimitProvider.notifier).state = 30;
                    },
                    child: Text(
                      'Show All',
                      style: AppTheme.fontStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Horizontal Cuisine Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
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
                        ref.read(recipesLimitProvider.notifier).state = 30;
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
                        ref.read(recipesLimitProvider.notifier).state = 30;
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
                        ref.read(recipesLimitProvider.notifier).state = 30;
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
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              data: (recipes) {
                if (recipes.isEmpty) {
                  return _buildEmptyState(context);
                }

                final currentLimit = ref.watch(recipesLimitProvider);
                final canLoadMore = recipes.length >= currentLimit;

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(recipesLimitProvider.notifier).state = 30;
                    ref.invalidate(recipesListProvider);
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: recipes.length + ((canLoadMore && _isLoadingMore) ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == recipes.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }
                      final recipe = recipes[index];
                      return _buildRecipeCard(context, recipe, isIOS, isDark);
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: AppTheme.primaryEmerald,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),

        // Title and Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.fontStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    timeStr,
                    style: AppTheme.fontStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (recipe.diet != null) ...[
                    const SizedBox(width: 8),
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
                ],
              ),
            ],
          ),
        ),

        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/recipes/${recipe.id}'),
          child: content,
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
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

  // Scrollable Empty State (prevents bottom overflow when software keyboard is open)
  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 42,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No recipes found',
                    style: AppTheme.fontStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try changing keywords or resetting your active filters.',
                    textAlign: TextAlign.center,
                    style: AppTheme.fontStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(recipeSearchQueryProvider.notifier).state = '';
                      ref.read(recipeSelectedCuisineProvider.notifier).state = 'All';
                      ref.read(recipeSelectedDietProvider.notifier).state = 'All';
                      ref.read(recipeSelectedMaxTimeProvider.notifier).state = null;
                      ref.read(recipesLimitProvider.notifier).state = 30;
                    },
                    label: const Text('Reset All Filters'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
