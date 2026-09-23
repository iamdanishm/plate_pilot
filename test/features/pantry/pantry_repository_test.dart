import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/pantry/data/pantry_repository.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('PantryRepository Unit Tests', () {
    late SupabaseClient mockClient;
    late PantryRepository repository;

    setUp(() {
      mockClient = SupabaseClient(
        'https://mock.supabase.co',
        'mock-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      repository = PantryRepository(mockClient);
    });

    test('getPantryItems returns empty list when householdId is empty or default', () async {
      final itemsEmpty = await repository.getPantryItems('');
      expect(itemsEmpty, isEmpty);

      final itemsDefault = await repository.getPantryItems('default');
      expect(itemsDefault, isEmpty);
    });

    test('getPantryItems throws descriptive exception on network/database failure', () async {
      expect(
        () async => await repository.getPantryItems('household-123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch pantry items'),
        )),
      );
    });

    test('addPantryItem throws descriptive exception when Supabase is unreachable', () async {
      expect(
        () async => await repository.addPantryItem(
          householdId: 'h1',
          name: 'Paneer',
          storageLocation: 'fridge',
          quantity: 250,
          unit: 'g',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to add pantry item'),
        )),
      );
    });

    test('updatePantryItem throws descriptive exception on error', () async {
      final item = PantryItemEntity(
        id: 'item-1',
        householdId: 'h1',
        name: 'Paneer',
        storageLocation: 'fridge',
        createdAt: DateTime.now(),
      );

      expect(
        () async => await repository.updatePantryItem(item),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to update pantry item'),
        )),
      );
    });

    test('deletePantryItem throws descriptive exception on error', () async {
      expect(
        () async => await repository.deletePantryItem('item-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to delete pantry item'),
        )),
      );
    });

    test('searchCanonicalIngredients throws descriptive exception on error', () async {
      expect(
        () async => await repository.searchCanonicalIngredients('onion'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to search canonical ingredients'),
        )),
      );
    });
  });
}
