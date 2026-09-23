import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/meal_plan/data/meal_plan_ai_service.dart';
import 'package:plate_pilot/features/meal_plan/domain/meal_plan_proposal_entity.dart';
import 'package:plate_pilot/features/meal_plan/presentation/screens/meal_plan_screen.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';

class FakeMealPlanAiService implements IMealPlanAiService {
  bool shouldFail = false;
  MealPlanProposalEntity? customProposal;

  @override
  Future<MealPlanProposalEntity> generateMealPlanProposal(
      String householdId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldFail) {
      throw Exception('Network timeout calling Gemini');
    }
    return customProposal ??
        const MealPlanProposalEntity(
          weekSummary: 'Balanced high-protein vegetarian meals.',
          plannedMeals: [
            PlannedMealProposal(
              day: 'monday',
              mealType: 'dinner',
              recipeId: 'rec_101',
              recipeTitle: 'Dal Tadka',
              reasonSummary: 'Quick 20-min dinner using pantry lentils.',
            ),
            PlannedMealProposal(
              day: 'tuesday',
              mealType: 'dinner',
              recipeId: 'rec_102',
              recipeTitle: 'Palak Paneer',
              reasonSummary: 'Uses fresh spinach expiring soon.',
            ),
          ],
        );
  }

  @override
  Future<MealSwapProposalEntity> requestMealSwap({
    required String householdId,
    required String targetDay,
    required String targetMealType,
    required String swapReason,
    String? currentPlanSummary,
  }) async {
    return const MealSwapProposalEntity(
      replacementRecipeId: 'rec_103',
      replacementRecipeTitle: 'Aloo Gobi Masala',
      reasonSummary: 'Replaced with a lighter comforting potato-cauliflower curry.',
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime.now();
  final testHousehold = HouseholdEntity(
    id: 'household-123',
    name: 'Sharma Family',
    ownerId: 'user-123',
    adultsCount: 2,
    childrenCount: 1,
    dietaryRestrictions: ['vegetarian'],
    weeklyBudget: 3500,
    createdAt: now,
    updatedAt: now,
  );

  group('MealPlanScreen Widget Tests', () {
    late FakeMealPlanAiService fakeAiService;

    setUp(() {
      fakeAiService = FakeMealPlanAiService();
    });

    Widget createScreen() {
      return ProviderScope(
        overrides: [
          currentUserHouseholdProvider
              .overrideWith((ref) => Future.value(testHousehold)),
          mealPlanAiServiceProvider.overrideWithValue(fakeAiService),
        ],
        child: const MaterialApp(
          home: MealPlanScreen(),
        ),
      );
    }

    testWidgets('renders empty state with Generate Plan button initially',
        (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Weekly Meal Plan'), findsOneWidget);
      expect(find.text('No Active Meal Plan'), findsOneWidget);
      expect(find.text('Generate 7-Day Plan with AI'), findsOneWidget);
    });

    testWidgets('triggers AI generation and displays meal cards on success',
        (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Tap generate button
      await tester.tap(find.text('Generate 7-Day Plan with AI'));
      await tester.pump(); // Start async work

      // Check loading state text
      expect(find.text('Gemini AI is crafting your week...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify generated cards
      expect(find.text('AI-Crafted Weekly Schedule'), findsOneWidget);
      expect(find.text('Balanced high-protein vegetarian meals.'), findsOneWidget);
      expect(find.text('Dal Tadka'), findsOneWidget);
      expect(find.text('Palak Paneer'), findsOneWidget);
      expect(find.text('Quick 20-min dinner using pantry lentils.'), findsOneWidget);
    });

    testWidgets('opens swap modal and replaces meal successfully',
        (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Generate initial plan
      await tester.tap(find.text('Generate 7-Day Plan with AI'));
      await tester.pumpAndSettle();

      expect(find.text('Dal Tadka'), findsOneWidget);

      // Tap first Swap button
      await tester.tap(find.text('Swap').first);
      await tester.pumpAndSettle();

      // Verify Swap modal sheet
      expect(find.text('Swap MONDAY'), findsOneWidget);
      expect(find.text('Need something lighter'), findsOneWidget);

      // Tap preset
      await tester.tap(find.text('Need something lighter'));
      await tester.pumpAndSettle();

      // Verifies replaced with Aloo Gobi Masala
      expect(find.text('Aloo Gobi Masala'), findsOneWidget);
      expect(find.text('Dal Tadka'), findsNothing);
    });

    testWidgets('displays error card when generation fails', (tester) async {
      fakeAiService.shouldFail = true;

      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate 7-Day Plan with AI'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network timeout calling Gemini'), findsOneWidget);
    });
  });
}
