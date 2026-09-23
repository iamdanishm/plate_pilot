import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/core/theme/glass_container.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_proposal_entity.dart';
import 'package:plate_pilot/features/meal_plan/presentation/controllers/meal_plan_controller.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  void _showSwapMealSheet(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    PlannedMealProposal meal,
  ) {
    final customReasonController = TextEditingController();
    final presets = [
      'Need something lighter',
      'Quick 20-minute meal',
      'Comfort food / richer dish',
      'Kid-friendly favorite',
      'Uses different pantry items',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.neutralSurfaceDark
                  : AppTheme.neutralSurfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Swap ${meal.day.toUpperCase()}',
                        style: AppTheme.fontStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Currently: ${meal.recipeTitle}',
                    style: AppTheme.fontStyle(
                      fontSize: 14,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a reason or preference for the swap:',
                    style: AppTheme.fontStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      return ActionChip(
                        label: Text(preset),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref
                              .read(mealPlanControllerProvider(householdId)
                                  .notifier)
                              .swapMeal(
                                targetDay: meal.day,
                                targetMealType: meal.mealType,
                                reason: preset,
                              );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      hintText: 'Or enter custom constraint (e.g. Vegetarian only)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: AppTheme.primaryEmerald),
                        onPressed: () {
                          final text = customReasonController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.of(ctx).pop();
                            ref
                                .read(mealPlanControllerProvider(householdId)
                                    .notifier)
                                .swapMeal(
                                  targetDay: meal.day,
                                  targetMealType: meal.mealType,
                                  reason: text,
                                );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = AppTheme.isIOS;
    final householdAsync = ref.watch(currentUserHouseholdProvider);

    return householdAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            'Weekly Meal Plan',
            style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Weekly Meal Plan',
            style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Text('Error loading household: $e'),
        ),
      ),
      data: (household) {
        if (household == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Weekly Meal Plan',
                style: AppTheme.fontStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            body: const Center(
              child: Text('No active household found.'),
            ),
          );
        }

        return _buildContent(context, ref, household, isIOS);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HouseholdEntity household,
    bool isIOS,
  ) {
    final state = ref.watch(mealPlanControllerProvider(household.id));
    final controller =
        ref.read(mealPlanControllerProvider(household.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weekly Meal Plan',
          style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (state.proposal != null && !state.isGenerating)
            IconButton(
              key: const Key('regenerate_meal_plan_button'),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Regenerate Plan',
              onPressed: () => controller.generatePlan(),
            ),
        ],
      ),
      bottomNavigationBar: (state.proposal != null && !state.isGenerating && !state.isSaved)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: ElevatedButton.icon(
                  key: const Key('confirm_meal_plan_button'),
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          final ok = await controller.confirmPlan();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ 7-Day Plan confirmed and saved to your household!'),
                                backgroundColor: AppTheme.primaryEmerald,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    state.isSaving ? 'Saving Plan...' : 'Confirm & Save 7-Day Plan',
                    style: AppTheme.fontStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: AppTheme.fontStyle(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 1. GENERATING LOADING STATE
            if (state.isGenerating) ...[
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Gemini AI is crafting your week...',
                      style: AppTheme.fontStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Matching recipes with stocked pantry ingredients,\nrespecting dietary limits, and ensuring weekly variety.',
                      textAlign: TextAlign.center,
                      style: AppTheme.fontStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ]

            // 2. EMPTY STATE (BEFORE PLAN IS GENERATED)
            else if (state.proposal == null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 32,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Meal Plan',
                      style: AppTheme.fontStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let Gemini AI evaluate your household diet, pantry items, and cooking time limits to build an optimized 7-day culinary schedule.',
                      textAlign: TextAlign.center,
                      style: AppTheme.fontStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      key: const Key('generate_meal_plan_button'),
                      onPressed: () => controller.generatePlan(),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        'Generate 7-Day Plan with AI',
                        style: AppTheme.fontStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]

            // 3. GENERATED PROPOSAL DISPLAY
            else ...[
              // Week summary pill
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryEmerald,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI-Crafted Weekly Schedule',
                            style: AppTheme.fontStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.proposal!.weekSummary,
                            style: AppTheme.fontStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Saved & Active status banner
              if (state.isSaved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Plan Saved & Active — Your week is locked in!',
                          style: AppTheme.fontStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Meal cards
              ...state.proposal!.plannedMeals.map((meal) {
                final isSwappingThis =
                    state.isSwapping && state.swappingDay == meal.day;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMealCard(
                    context,
                    ref,
                    household.id,
                    meal,
                    isSwappingThis,
                    isIOS,
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    PlannedMealProposal meal,
    bool isSwappingThis,
    bool isIOS,
  ) {
    final content = Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${meal.day.toUpperCase()} • ${meal.mealType.toUpperCase()}',
                    style: AppTheme.fontStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryEmerald,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: isSwappingThis
                      ? null
                      : () =>
                          _showSwapMealSheet(context, ref, householdId, meal),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    'Swap',
                    style: AppTheme.fontStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.recipeTitle,
                    style: AppTheme.fontStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (meal.servings > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded, size: 14, color: AppTheme.secondaryAmberDark),
                        const SizedBox(width: 4),
                        Text(
                          '${meal.servings}',
                          style: AppTheme.fontStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryAmberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: AppTheme.secondaryAmberDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.reasonSummary,
                      style: AppTheme.fontStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    if (meal.recipeId.isNotEmpty) {
                      final servingsParam = meal.servings > 0 ? '?servings=${meal.servings}' : '';
                      context.push('/recipes/${meal.recipeId}$servingsParam');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View Recipe'),
                ),
              ],
            ),
          ],
        ),
        if (isSwappingThis)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: content,
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}
