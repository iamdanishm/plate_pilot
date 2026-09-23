import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/features/home/data/home_repository.dart';
import 'package:plate_pilot/features/pantry/data/pantry_repository.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';

final pantryStorageFilterProvider = StateProvider<String>((ref) => 'All');
final pantrySearchQueryProvider = StateProvider<String>((ref) => '');

class PantryController extends StateNotifier<AsyncValue<List<PantryItemEntity>>> {
  final IPantryRepository _repository;
  final Ref _ref;
  final String _householdId;

  PantryController(this._repository, this._ref, this._householdId)
      : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    if (_householdId.isEmpty || _householdId == 'default') {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getPantryItems(_householdId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem({
    required String name,
    String? canonicalIngredientId,
    double? quantity,
    String? unit,
    String? amountDescription,
    required String storageLocation,
    DateTime? expiresAt,
  }) async {
    try {
      final newItem = await _repository.addPantryItem(
        householdId: _householdId,
        name: name,
        canonicalIngredientId: canonicalIngredientId,
        quantity: quantity,
        unit: unit,
        amountDescription: amountDescription,
        storageLocation: storageLocation,
        expiresAt: expiresAt,
      );

      final currentList = state.asData?.value ?? [];
      state = AsyncValue.data([newItem, ...currentList]);
      _ref.invalidate(homePantryCountProvider(_householdId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateItemQuantity(PantryItemEntity item, double newQuantity) async {
    final updated = item.copyWith(quantity: newQuantity);
    final currentList = state.asData?.value ?? [];
    
    // Optimistic update
    state = AsyncValue.data(
      currentList.map((i) => i.id == item.id ? updated : i).toList(),
    );

    try {
      final saved = await _repository.updatePantryItem(updated);
      state = AsyncValue.data(
        (state.asData?.value ?? [])
            .map((i) => i.id == item.id ? saved : i)
            .toList(),
      );
    } catch (e, st) {
      // Revert if failed
      state = AsyncValue.data(currentList);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    final currentList = state.asData?.value ?? [];
    // Optimistic delete
    state = AsyncValue.data(currentList.where((i) => i.id != itemId).toList());

    try {
      await _repository.deletePantryItem(itemId);
      _ref.invalidate(homePantryCountProvider(_householdId));
    } catch (e, st) {
      // Revert on error
      state = AsyncValue.data(currentList);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> restoreItem(PantryItemEntity item) async {
    try {
      final restored = await _repository.addPantryItem(
        householdId: _householdId,
        name: item.name,
        canonicalIngredientId: item.canonicalIngredientId,
        quantity: item.quantity,
        unit: item.unit,
        amountDescription: item.amountDescription,
        storageLocation: item.storageLocation,
        expiresAt: item.expiresAt,
      );
      final currentList = state.asData?.value ?? [];
      state = AsyncValue.data([restored, ...currentList]);
      _ref.invalidate(homePantryCountProvider(_householdId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final pantryControllerProvider = StateNotifierProvider.family.autoDispose<
    PantryController, AsyncValue<List<PantryItemEntity>>, String>((ref, householdId) {
  final repo = ref.watch(pantryRepositoryProvider);
  return PantryController(repo, ref, householdId);
});

final filteredPantryListProvider =
    Provider.family.autoDispose<AsyncValue<List<PantryItemEntity>>, String>(
        (ref, householdId) {
  final pantryAsync = ref.watch(pantryControllerProvider(householdId));
  final filter = ref.watch(pantryStorageFilterProvider);
  final query = ref.watch(pantrySearchQueryProvider).trim().toLowerCase();

  return pantryAsync.whenData((items) {
    return items.where((item) {
      // Storage location / status filter
      if (filter == 'Pantry' && item.storageLocation.toLowerCase() != 'pantry') {
        return false;
      }
      if (filter == 'Fridge' && item.storageLocation.toLowerCase() != 'fridge') {
        return false;
      }
      if (filter == 'Freezer' &&
          item.storageLocation.toLowerCase() != 'freezer') {
        return false;
      }
      if (filter == 'Expiring Soon' && !item.isExpiringSoon) {
        return false;
      }

      // Search query
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query)) {
        return false;
      }

      return true;
    }).toList();
  });
});

final pantryCountsProvider =
    Provider.family.autoDispose<Map<String, int>, String>((ref, householdId) {
  final pantryAsync = ref.watch(pantryControllerProvider(householdId));
  final items = pantryAsync.asData?.value ?? [];

  int all = items.length;
  int pantry = 0;
  int fridge = 0;
  int freezer = 0;
  int expiringSoon = 0;

  for (final item in items) {
    final loc = item.storageLocation.toLowerCase();
    if (loc == 'pantry') pantry++;
    if (loc == 'fridge') fridge++;
    if (loc == 'freezer') freezer++;
    if (item.isExpiringSoon) expiringSoon++;
  }

  return {
    'All': all,
    'Fridge': fridge,
    'Pantry': pantry,
    'Freezer': freezer,
    'Expiring Soon': expiringSoon,
  };
});
