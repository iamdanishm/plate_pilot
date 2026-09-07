import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';
import '../../data/recipes_repository.dart';
import '../../domain/recipe_entity.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int _currentServings = 4;
  int _baseServings = 4;
  bool _isServingsInitialized = false;
  final Set<int> _completedSteps = {};
  final Set<String> _checkedIngredients = {};

  void _initServings(int? base) {
    if (!_isServingsInitialized) {
      _baseServings = (base != null && base > 0) ? base : 4;
      _currentServings = _baseServings;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
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

          _initServings(recipe.servings);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Header Card
                _buildHeroHeader(context, recipe, isIOS, isDark),
                const SizedBox(height: 20),

                // Servings Scaler Row
                _buildServingsScaler(context, isIOS),
                const SizedBox(height: 24),

                // Ingredients Section
                Text(
                  'Ingredients (${recipe.ingredients.length})',
                  style: AppTheme.fontStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap an item to cross off as you prep',
                  style: AppTheme.fontStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildIngredientsList(context, recipe, isIOS),
                const SizedBox(height: 28),

                // Cooking Instructions Section
                Text(
                  'Cooking Steps',
                  style: AppTheme.fontStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step-by-step culinary guidance',
                  style: AppTheme.fontStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInstructionsList(context, recipe, isIOS),
                const SizedBox(height: 36),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Add to Plan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${recipe.title}" to Meal Plan proposals!'),
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
                            borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 32),
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
        // Title & Cuisine
        Text(
          recipe.title,
          style: AppTheme.fontStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (recipe.cuisine != null)
              _buildBadge(
                recipe.cuisine!,
                AppTheme.primaryEmerald.withValues(alpha: 0.12),
                AppTheme.primaryEmeraldDark,
              ),
            if (recipe.diet != null)
              _buildBadge(
                recipe.diet!,
                AppTheme.secondaryAmber.withValues(alpha: 0.15),
                AppTheme.secondaryAmberDark,
              ),
            if (recipe.course != null)
              _buildBadge(
                recipe.course!,
                Colors.blue.withValues(alpha: 0.12),
                Colors.blue.shade800,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Time Metrics Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTimeMetric('Prep', '$prepTime m', Icons.kitchen_rounded),
            _buildTimeMetric('Cook', '$cookTime m', Icons.outdoor_grill_rounded),
            _buildTimeMetric(
                'Total', '$totalTime m', Icons.access_time_filled_rounded),
            _buildTimeMetric('Servings', '$_currentServings', Icons.people_rounded),
          ],
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
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: content,
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTheme.fontStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildTimeMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryEmerald),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.fontStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
              icon: const Icon(Icons.remove_rounded),
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
              icon: const Icon(Icons.add_rounded),
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
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: content,
      ),
    );
  }

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
        child: const Text('No ingredient quantities recorded for this recipe.'),
      );
    }

    return Column(
      children: recipe.ingredients.map((ing) {
        final isChecked = _checkedIngredients.contains(ing.id);
        final scaledQty = _formatScaledQuantity(ing.quantity);
        final qtyUnit = [scaledQty, ing.unit ?? ''].where((s) => s.isNotEmpty).join(' ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isChecked
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChecked
                      ? Colors.transparent
                      : Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isChecked
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isChecked
                        ? AppTheme.primaryEmerald
                        : Colors.grey,
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
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qtyUnit,
                        style: AppTheme.fontStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
        child: const Text('No step-by-step instructions available for this recipe.'),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primaryEmerald.withValues(alpha: 0.08)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.primaryEmerald.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryEmerald
                          : AppTheme.primaryEmerald.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : Text(
                              '${step.step}',
                              style: AppTheme.fontStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
}
