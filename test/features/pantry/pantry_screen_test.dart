import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/pantry/data/pantry_repository.dart';
import 'package:plate_pilot/features/pantry/domain/canonical_ingredient_entity.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';
import 'package:plate_pilot/features/pantry/presentation/screens/pantry_screen.dart';

class FakePantryRepoForScreen implements IPantryRepository {
  List<PantryItemEntity> items = [];

  @override
  Future<List<PantryItemEntity>> getPantryItems(String householdId) async {
    return List.from(items);
  }

  @override
  Future<PantryItemEntity> addPantryItem({
    required String householdId,
    required String name,
    String? canonicalIngredientId,
    double? quantity,
    String? unit,
    String? amountDescription,
    required String storageLocation,
    DateTime? expiresAt,
  }) async {
    final newItem = PantryItemEntity(
      id: 'item-${DateTime.now().microsecondsSinceEpoch}',
      householdId: householdId,
      name: name,
      canonicalIngredientId: canonicalIngredientId,
      quantity: quantity,
      unit: unit,
      amountDescription: amountDescription,
      storageLocation: storageLocation,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
    items.add(newItem);
    return newItem;
  }

  @override
  Future<PantryItemEntity> updatePantryItem(PantryItemEntity item) async {
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      items[idx] = item;
    }
    return item;
  }

  @override
  Future<void> deletePantryItem(String itemId) async {
    items.removeWhere((i) => i.id == itemId);
  }

  @override
  Future<List<CanonicalIngredientEntity>> searchCanonicalIngredients(
    String query, {
    int limit = 10,
  }) async {
    return [
      const CanonicalIngredientEntity(
        id: 'paneer',
        name: 'Fresh Paneer',
        category: 'dairy',
        defaultUnit: 'g',
        shelfLifeDays: 4,
        defaultStorage: 'fridge',
      ),
    ];
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const householdId = 'household-123';
  final now = DateTime.now();
  final testHousehold = HouseholdEntity(
    id: householdId,
    name: 'Sharma Family',
    ownerId: 'user-123',
    adultsCount: 2,
    childrenCount: 1,
    dietaryRestrictions: ['vegetarian'],
    weeklyBudget: 3500,
    createdAt: now,
    updatedAt: now,
  );

  group('PantryScreen Widget Tests', () {
    late FakePantryRepoForScreen fakeRepo;

    setUp(() {
      fakeRepo = FakePantryRepoForScreen();
      fakeRepo.items = [
        PantryItemEntity(
          id: '1',
          householdId: householdId,
          name: 'Basmati Rice',
          quantity: 2.0,
          unit: 'kg',
          storageLocation: 'pantry',
          expiresAt: now.add(const Duration(days: 60)),
          createdAt: now,
        ),
        PantryItemEntity(
          id: '2',
          householdId: householdId,
          name: 'Fresh Paneer',
          quantity: 400,
          unit: 'g',
          storageLocation: 'fridge',
          expiresAt: now.add(const Duration(days: 2)), // Expiring soon
          createdAt: now,
        ),
        PantryItemEntity(
          id: '3',
          householdId: householdId,
          name: 'Frozen Peas',
          quantity: 500,
          unit: 'g',
          storageLocation: 'freezer',
          expiresAt: now.add(const Duration(days: 90)),
          createdAt: now,
        ),
      ];
    });

    Widget createScreen() {
      return ProviderScope(
        overrides: [
          pantryRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserHouseholdProvider.overrideWith((ref) => Future.value(testHousehold)),
        ],
        child: const MaterialApp(
          home: PantryScreen(),
        ),
      );
    }

    testWidgets('renders pantry screen with dynamic filter chips and items', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Pantry & Fridge'), findsOneWidget);

      // Verify dynamic count chips
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Fridge (1)'), findsOneWidget);
      expect(find.text('Pantry (1)'), findsOneWidget);
      expect(find.text('Freezer (1)'), findsOneWidget);
      expect(find.text('Expiring Soon (1)'), findsOneWidget);

      // Verify item cards
      expect(find.text('Basmati Rice'), findsOneWidget);
      expect(find.text('Fresh Paneer'), findsOneWidget);
      expect(find.text('Frozen Peas'), findsOneWidget);

      // Verify formatted subtitle and badge
      expect(find.text('2 kg • PANTRY'), findsOneWidget);
      expect(find.text('Expires in 2 days'), findsOneWidget);

      // Verify FAB
      expect(find.byKey(const Key('add_pantry_item_fab')), findsOneWidget);
    });

    testWidgets('filters items when filter chips are clicked', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Click on Fridge (1)
      await tester.tap(find.text('Fridge (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Fresh Paneer'), findsOneWidget);
      expect(find.text('Basmati Rice'), findsNothing);
      expect(find.text('Frozen Peas'), findsNothing);

      // Click on Freezer (1)
      await tester.tap(find.text('Freezer (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Frozen Peas'), findsOneWidget);
      expect(find.text('Fresh Paneer'), findsNothing);

      // Click on Expiring Soon (1)
      await tester.tap(find.text('Expiring Soon (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Fresh Paneer'), findsOneWidget);
      expect(find.text('Frozen Peas'), findsNothing);
    });

    testWidgets('search bar filters items by name', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Toggle search bar
      await tester.tap(find.byKey(const Key('pantry_search_toggle_button')));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byKey(const Key('pantry_search_field')), 'Rice');
      await tester.pumpAndSettle();

      expect(find.text('Basmati Rice'), findsOneWidget);
      expect(find.text('Fresh Paneer'), findsNothing);
      expect(find.text('Frozen Peas'), findsNothing);
    });

    testWidgets('inline quantity stepper updates quantity', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Tap the [+] button for Basmati Rice
      final addButtons = find.byIcon(Icons.add_rounded);
      expect(addButtons, findsWidgets);

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Verifies quantity increased to 3 kg
      expect(find.text('3 kg • PANTRY'), findsOneWidget);
    });

    testWidgets('dismissible swipe deletes item and shows undo snackbar', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Basmati Rice'), findsOneWidget);

      // Swipe item 1
      await tester.drag(find.text('Basmati Rice'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Item should be removed from view
      expect(find.text('Basmati Rice'), findsNothing);

      // SnackBar with Undo should appear
      expect(find.text('Removed "Basmati Rice"'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo to restore
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Basmati Rice'), findsOneWidget);
    });

    testWidgets('opens Add Item sheet and adds new ingredient', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byKey(const Key('add_pantry_item_fab')));
      await tester.pumpAndSettle();

      // Verify sheet opened
      expect(find.text('Add Pantry Item'), findsOneWidget);

      // Enter item name
      await tester.enterText(
        find.byKey(const Key('add_pantry_item_name_field')),
        'Ginger',
      );
      await tester.pumpAndSettle();

      // Scroll to submit button and tap
      await tester.ensureVisible(find.byKey(const Key('add_pantry_item_submit_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_pantry_item_submit_button')));
      await tester.pumpAndSettle();

      // Verify sheet dismissed and new item in list
      expect(find.text('Add Pantry Item'), findsNothing);
      expect(find.text('Ginger'), findsOneWidget);
    });

    testWidgets('shows empty state when no items match search query', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Toggle search bar
      await tester.tap(find.byKey(const Key('pantry_search_toggle_button')));
      await tester.pumpAndSettle();

      // Search non-existent query
      await tester.enterText(find.byKey(const Key('pantry_search_field')), 'Zucchini');
      await tester.pumpAndSettle();

      expect(find.text('No items match your filter'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      // Tap Reset Filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Basmati Rice'), findsOneWidget);
    });
  });
}
