import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/pantry/data/pantry_repository.dart';
import 'package:plate_pilot/features/pantry/domain/canonical_ingredient_entity.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';
import 'package:plate_pilot/features/pantry/presentation/controllers/pantry_controller.dart';

class FakePantryRepository implements IPantryRepository {
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
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
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
        name: 'Paneer',
        category: 'dairy',
        defaultUnit: 'g',
        shelfLifeDays: 4,
        defaultStorage: 'fridge',
      ),
    ];
  }
}

void main() {
  group('PantryController & Filter Tests', () {
    const householdId = 'household-123';
    late FakePantryRepository fakeRepo;
    late ProviderContainer container;
    final now = DateTime.now();

    setUp(() {
      fakeRepo = FakePantryRepository();
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
          name: 'Paneer',
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

      container = ProviderContainer(
        overrides: [
          pantryRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loads initial items for current household', () async {
      await container.read(pantryControllerProvider(householdId).notifier).loadItems();
      final state = container.read(pantryControllerProvider(householdId)).asData!.value;
      expect(state.length, 3);
      expect(state[0].name, 'Basmati Rice');
    });

    test('pantryCountsProvider calculates correct counts for each category', () async {
      await container.read(pantryControllerProvider(householdId).notifier).loadItems();
      final counts = container.read(pantryCountsProvider(householdId));

      expect(counts['All'], 3);
      expect(counts['Pantry'], 1);
      expect(counts['Fridge'], 1);
      expect(counts['Freezer'], 1);
      expect(counts['Expiring Soon'], 1);
    });

    test('filters list by storage location and expiring soon', () async {
      await container.read(pantryControllerProvider(householdId).notifier).loadItems();

      // Filter: Fridge
      container.read(pantryStorageFilterProvider.notifier).state = 'Fridge';
      var filtered = container.read(filteredPantryListProvider(householdId)).asData!.value;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Paneer');

      // Filter: Expiring Soon
      container.read(pantryStorageFilterProvider.notifier).state = 'Expiring Soon';
      filtered = container.read(filteredPantryListProvider(householdId)).asData!.value;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Paneer');

      // Filter: Freezer
      container.read(pantryStorageFilterProvider.notifier).state = 'Freezer';
      filtered = container.read(filteredPantryListProvider(householdId)).asData!.value;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Frozen Peas');

      // Search Query filter
      container.read(pantryStorageFilterProvider.notifier).state = 'All';
      container.read(pantrySearchQueryProvider.notifier).state = 'rice';
      filtered = container.read(filteredPantryListProvider(householdId)).asData!.value;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Basmati Rice');
    });

    test('addItem, updateItemQuantity, and deleteItem perform correctly', () async {
      await container.read(pantryControllerProvider(householdId).notifier).loadItems();
      final controller = container.read(pantryControllerProvider(householdId).notifier);

      // 1. Add item
      await controller.addItem(
        name: 'Tomatoes',
        quantity: 1.0,
        unit: 'kg',
        storageLocation: 'fridge',
      );

      var items = container.read(pantryControllerProvider(householdId)).asData!.value;
      expect(items.length, 4);
      expect(items.first.name, 'Tomatoes');

      // 2. Update quantity
      final itemToUpdate = items.first;
      await controller.updateItemQuantity(itemToUpdate, 2.0);

      items = container.read(pantryControllerProvider(householdId)).asData!.value;
      expect(items.first.quantity, 2.0);

      // 3. Delete item
      await controller.deleteItem(itemToUpdate.id);
      items = container.read(pantryControllerProvider(householdId)).asData!.value;
      expect(items.length, 3);
      expect(items.any((i) => i.id == itemToUpdate.id), isFalse);
    });
  });
}
