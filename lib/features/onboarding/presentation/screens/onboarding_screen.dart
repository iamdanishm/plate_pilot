import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/core/theme/glass_container.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/presentation/controllers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<String> _dietOptions = const [
    'vegetarian',
    'non_vegetarian',
    'eggetarian',
    'vegan',
    'jain',
    'sattvic',
  ];

  final List<Map<String, String>> _allergyOptions = const [
    {'id': 'dairy', 'name': 'Dairy / Milk'},
    {'id': 'gluten', 'name': 'Gluten / Wheat'},
    {'id': 'peanuts', 'name': 'Peanuts'},
    {'id': 'tree_nuts', 'name': 'Tree Nuts'},
    {'id': 'soy', 'name': 'Soy'},
    {'id': 'egg', 'name': 'Eggs'},
    {'id': 'fish', 'name': 'Fish'},
    {'id': 'shellfish', 'name': 'Shellfish'},
    {'id': 'mustard', 'name': 'Mustard'},
  ];

  final List<String> _cuisineOptions = const [
    'North Indian',
    'South Indian',
    'Gujarati',
    'Punjabi',
    'Maharashtrian',
    'Bengali',
    'Rajasthani',
    'Andhra',
    'Kerala',
    'Continental',
    'Chinese',
  ];

  Future<void> _handleFinish() async {
    final user = ref.read(authRepositoryProvider).currentUser ??
        ref.read(authControllerProvider).value;
    final userId = user?.id ?? '00000000-0000-0000-0000-000000000000';

    final result = await ref
        .read(onboardingControllerProvider.notifier)
        .submitOnboarding(userId);

    if (result != null && mounted) {
      ref.invalidate(currentUserHouseholdProvider);
      if (GoRouter.maybeOf(context) != null) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Setup Household (${state.currentStep + 1}/4)',
          style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: controller.previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: LinearProgressIndicator(
                value: (state.currentStep + 1) / 4,
                backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                borderRadius: BorderRadius.circular(8),
                minHeight: 6,
              ),
            ),

            // Error banner if submit failed
            if (state.errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: isIOS
                    ? GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: _buildCurrentStep(state, controller),
                      )
                    : Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildCurrentStep(state, controller),
                        ),
                      ),
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (state.currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isSubmitting ? null : controller.previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (state.currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              if (state.currentStep < 3) {
                                controller.nextStep();
                              } else {
                                _handleFinish();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              state.currentStep == 3 ? 'Save & Start Planning' : 'Continue',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(OnboardingFormState state, OnboardingController controller) {
    switch (state.currentStep) {
      case 0:
        return _buildHouseholdCompositionStep(state, controller);
      case 1:
        return _buildDietaryAndAllergiesStep(state, controller);
      case 2:
        return _buildCookingTimesAndCuisinesStep(state, controller);
      case 3:
        return _buildBudgetStep(state, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Household Composition
  Widget _buildHouseholdCompositionStep(OnboardingFormState state, OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Household Profile',
          style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Tell us about your home so we can calculate meal portions accurately.',
          style: AppTheme.fontStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextFormField(
          initialValue: state.householdName,
          decoration: const InputDecoration(
            labelText: 'Household Name',
            hintText: 'e.g. Sharma Family',
            prefixIcon: Icon(Icons.home_outlined),
          ),
          onChanged: controller.setHouseholdName,
        ),
        const SizedBox(height: 24),
        _buildCounterRow(
          title: 'Adults (12+ yrs)',
          subtitle: 'Full portion sizing',
          value: state.adultsCount,
          onIncrement: () => controller.setAdultsCount(state.adultsCount + 1),
          onDecrement: () => controller.setAdultsCount(state.adultsCount - 1),
        ),
        const Divider(height: 32),
        _buildCounterRow(
          title: 'Children (Under 12)',
          subtitle: 'Adjusted portion sizing',
          value: state.childrenCount,
          onIncrement: () => controller.setChildrenCount(state.childrenCount + 1),
          onDecrement: () => controller.setChildrenCount(state.childrenCount - 1),
        ),
      ],
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.fontStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: AppTheme.fontStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.remove_rounded),
              onPressed: value > 0 ? onDecrement : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$value', style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add_rounded),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  // Step 1: Diets & Allergens
  Widget _buildDietaryAndAllergiesStep(OnboardingFormState state, OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diet & Safety',
          style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'PlatePilot strictly excludes allergens and prioritizes your dietary preferences.',
          style: AppTheme.fontStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text('Primary Diet', style: AppTheme.fontStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dietOptions.map((diet) {
            final isSelected = state.selectedDiets.contains(diet);
            return FilterChip(
              label: Text(diet.replaceAll('_', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (_) => controller.toggleDiet(diet),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Allergens & Exclusions', style: AppTheme.fontStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Tap to select items to strictly exclude from your meal plans.', style: AppTheme.fontStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allergyOptions.map((opt) {
            final id = opt['id']!;
            final name = opt['name']!;
            final isSelected = state.selectedAllergens.containsKey(id);
            return FilterChip(
              avatar: isSelected ? const Icon(Icons.shield_rounded, size: 16) : null,
              label: Text(name),
              selected: isSelected,
              onSelected: (_) => controller.toggleAllergen(id, isHard: true),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 2: Cooking Times & Cuisines
  Widget _buildCookingTimesAndCuisinesStep(OnboardingFormState state, OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cooking Habits',
          style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Set weekday vs weekend time budgets and your favorite culinary styles.',
          style: AppTheme.fontStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Text(
          'Max Weekday Cooking Time: ${state.maxWeekdayCookingTime} mins',
          style: AppTheme.fontStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: state.maxWeekdayCookingTime.toDouble(),
          min: 15,
          max: 90,
          divisions: 5,
          label: '${state.maxWeekdayCookingTime}m',
          onChanged: (val) => controller.setCookingTimes(weekday: val.toInt()),
        ),
        const SizedBox(height: 16),
        Text(
          'Max Weekend Cooking Time: ${state.maxWeekendCookingTime} mins',
          style: AppTheme.fontStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: state.maxWeekendCookingTime.toDouble(),
          min: 30,
          max: 120,
          divisions: 6,
          label: '${state.maxWeekendCookingTime}m',
          onChanged: (val) => controller.setCookingTimes(weekend: val.toInt()),
        ),
        const SizedBox(height: 20),
        Text('Preferred Cuisines', style: AppTheme.fontStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cuisineOptions.map((c) {
            final isSelected = state.selectedCuisines.contains(c);
            return FilterChip(
              label: Text(c),
              selected: isSelected,
              onSelected: (_) => controller.toggleCuisine(c),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 3: Budget & Currency
  Widget _buildBudgetStep(OnboardingFormState state, OnboardingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Grocery Budget',
          style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'PlatePilot optimizes ingredient shopping to keep your estimated totals within budget.',
          style: AppTheme.fontStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Text(
                '₹${state.weeklyBudget.toInt()}',
                style: AppTheme.fontStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              Text(
                'estimated per week',
                style: AppTheme.fontStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: state.weeklyBudget,
          min: 1000,
          max: 10000,
          divisions: 18,
          label: '₹${state.weeklyBudget.toInt()}',
          onChanged: controller.setBudget,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: AppTheme.primaryEmerald),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ingredient re-use across the week and pantry deductions will help reduce waste and stay under budget.',
                  style: AppTheme.fontStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
