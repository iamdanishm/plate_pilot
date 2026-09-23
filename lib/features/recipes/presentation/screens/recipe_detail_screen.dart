import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../onboarding/data/household_repository.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe_entity.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final int? initialServings;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.initialServings,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int _currentServings = 4;
  int _baseServings = 4;
  bool _isServingsInitialized = false;
  int _activeViewIndex = 0; // 0 = Overview (All), 1 = Ingredients, 2 = Steps
  final Set<int> _completedSteps = {};
  final Set<String> _checkedIngredients = {};

  void _initServings(int? base, int? householdServings) {
    if (!_isServingsInitialized) {
      _baseServings = (base != null && base > 0) ? base : 4;
      if (widget.initialServings != null && widget.initialServings! > 0) {
        _currentServings = widget.initialServings!;
      } else if (householdServings != null && householdServings > 0) {
        _currentServings = householdServings;
      } else {
        _currentServings = _baseServings;
      }
      _isServingsInitialized = true;
    }
  }

  double get _servingsMultiplier => _currentServings / _baseServings;

  String _formatScaledQuantity(double? quantity) {
    if (quantity == null) return '';
    final scaled = quantity * _servingsMultiplier;
    if (scaled == scaled.roundToDouble()) {
      return scaled.toInt().toString();
    }
    return scaled.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Bookmark Recipe',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recipe bookmarked!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Recipe',
            onPressed: () {},
          ),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) {
          if (recipe == null) {
            return Center(
              child: Text(
                'Recipe not found',
                style: AppTheme.fontStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final household = ref.watch(currentUserHouseholdProvider).asData?.value;
          final householdServings = household != null
              ? (household.adultsCount + household.childrenCount)
              : null;
          _initServings(recipe.servings, householdServings);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Header Card
                _buildHeroHeader(context, recipe, isIOS, isDark),
                const SizedBox(height: 14),

                // 2. Segmented Mode Controller (Overview / Ingredients / Steps)
                _buildSegmentedTabBar(context, recipe),
                const SizedBox(height: 16),

                // 3. View Content (Controlled by active segment)
                if (_activeViewIndex == 0 || _activeViewIndex == 1) ...[
                  _buildServingsScaler(context, isIOS),
                  const SizedBox(height: 18),
                  _buildSectionHeader(
                    title: 'Ingredients (${recipe.ingredients.length})',
                    subtitle: 'Tap an item to cross off as you prep',
                  ),
                  const SizedBox(height: 10),
                  _buildIngredientsList(context, recipe, isIOS),
                  const SizedBox(height: 22),
                ],

                if (_activeViewIndex == 0 || _activeViewIndex == 2) ...[
                  _buildSectionHeader(
                    title: 'Cooking Steps',
                    subtitle: _completedSteps.isEmpty
                        ? 'Step-by-step culinary guidance'
                        : '${_completedSteps.length} of ${recipe.instructions.length} steps finished',
                  ),
                  const SizedBox(height: 10),
                  _buildInstructionsList(context, recipe, isIOS),
                  const SizedBox(height: 24),
                ],

                // 4. Action Buttons
                _buildBottomActionBar(context, recipe, isIOS),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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
                  'Failed to load recipe',
                  style: AppTheme.fontStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(recipeDetailProvider(widget.recipeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Hero Header
  Widget _buildHeroHeader(
    BuildContext context,
    RecipeEntity recipe,
    bool isIOS,
    bool isDark,
  ) {
    final prepTime = recipe.prepTimeMinutes ?? 0;
    final cookTime = recipe.cookTimeMinutes ?? 0;
    final totalTime = recipe.computedTotalTimeMinutes;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Title
        Text(
          recipe.title,
          style: AppTheme.fontStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Badges Wrap (Cuisine, Diet, Course)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (recipe.cuisine != null)
              _buildBadge(
                recipe.cuisine!,
                AppTheme.primaryEmerald.withValues(alpha: 0.12),
                AppTheme.primaryEmeraldDark,
                Icons.restaurant_rounded,
              ),
            if (recipe.diet != null)
              _buildBadge(
                recipe.diet!,
                AppTheme.secondaryAmber.withValues(alpha: 0.15),
                AppTheme.secondaryAmberDark,
                Icons.eco_rounded,
              ),
            if (recipe.course != null)
              _buildBadge(
                recipe.course!,
                Colors.indigo.withValues(alpha: 0.12),
                Colors.indigo.shade800,
                Icons.dinner_dining_rounded,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Time Metrics Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeMetric('Prep', '$prepTime m', Icons.kitchen_rounded),
              _buildTimeDivider(),
              _buildTimeMetric('Cook', '$cookTime m', Icons.outdoor_grill_rounded),
              _buildTimeDivider(),
              _buildTimeMetric(
                  'Total', '$totalTime m', Icons.access_time_filled_rounded),
              _buildTimeDivider(),
              _buildTimeMetric(
                  'Servings', '$_currentServings', Icons.people_rounded),
            ],
          ),
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.all(18),
        child: content,
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: content,
      ),
    );
  }

  Widget _buildTimeDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textCol),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTheme.fontStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryEmerald),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.fontStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTheme.fontStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 2. Segmented View Switcher
  Widget _buildSegmentedTabBar(BuildContext context, RecipeEntity recipe) {
    final segments = [
      'Overview',
      'Ingredients (${recipe.ingredients.length})',
      'Steps (${recipe.instructions.length})',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = _activeViewIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeViewIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryEmerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxInsets.boxShadow(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    segments[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.fontStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.fontStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTheme.fontStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // 3. Portion Scaler
  Widget _buildServingsScaler(BuildContext context, bool isIOS) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portion Scaler',
              style: AppTheme.fontStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Automatically scales ingredients',
              style: AppTheme.fontStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.remove_rounded, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: _currentServings > 1
                  ? () => setState(() => _currentServings--)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$_currentServings',
                style: AppTheme.fontStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add_rounded, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: _currentServings < 16
                  ? () => setState(() => _currentServings++)
                  : null,
            ),
          ],
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: content,
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: content,
      ),
    );
  }

  // 4. Ingredients List
  Widget _buildIngredientsList(
    BuildContext context,
    RecipeEntity recipe,
    bool isIOS,
  ) {
    if (recipe.ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No ingredient quantities recorded for this recipe.'),
        ),
      );
    }

    return Column(
      children: recipe.ingredients.map((ing) {
        final isChecked = _checkedIngredients.contains(ing.id);
        final scaledQty = _formatScaledQuantity(ing.quantity);
        final computedQtyUnit =
            [scaledQty, ing.unit ?? ''].where((s) => s.isNotEmpty).join(' ');
        final qtyUnit = computedQtyUnit.isNotEmpty
            ? computedQtyUnit
            : (ing.amountDescription?.trim().isNotEmpty == true
                ? ing.amountDescription!.trim()
                : '');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (isChecked) {
                  _checkedIngredients.remove(ing.id);
                } else {
                  _checkedIngredients.add(ing.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isChecked
                    ? Colors.grey.withValues(alpha: 0.06)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isChecked
                      ? Colors.transparent
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isChecked
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isChecked ? AppTheme.primaryEmerald : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ing.ingredientName ?? ing.rawText,
                      style: AppTheme.fontStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isChecked ? Colors.grey : null,
                      ),
                    ),
                  ),
                  if (qtyUnit.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qtyUnit,
                        style: AppTheme.fontStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryEmeraldDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Cooking Steps List
  Widget _buildInstructionsList(
    BuildContext context,
    RecipeEntity recipe,
    bool isIOS,
  ) {
    if (recipe.instructions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No step-by-step instructions available for this recipe.'),
        ),
      );
    }

    return Column(
      children: recipe.instructions.map((step) {
        final isCompleted = _completedSteps.contains(step.step);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                if (isCompleted) {
                  _completedSteps.remove(step.step);
                } else {
                  _completedSteps.add(step.step);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primaryEmerald.withValues(alpha: 0.06)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.primaryEmerald.withValues(alpha: 0.3)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryEmerald
                          : AppTheme.primaryEmerald.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : Text(
                              '${step.step}',
                              style: AppTheme.fontStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryEmeraldDark,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      step.text,
                      style: AppTheme.fontStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 6. Persistent Bottom Action Bar
  Widget _buildBottomActionBar(
    BuildContext context,
    RecipeEntity recipe,
    bool isIOS,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Add to Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${recipe.title}" to meal proposals!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.soup_kitchen_rounded),
                label: const Text('Start Cooking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cooking mode ready!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxInsets {
  static BoxShadow boxShadow({
    required Color color,
    required double blurRadius,
    required Offset offset,
  }) {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      offset: offset,
    );
  }
}
