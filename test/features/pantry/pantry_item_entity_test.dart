import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';
import 'package:plate_pilot/features/pantry/domain/canonical_ingredient_entity.dart';

void main() {
  group('PantryItemEntity Unit Tests', () {
    test('serializes and deserializes from json correctly', () {
      final now = DateTime.now();
      final item = PantryItemEntity(
        id: 'item-123',
        householdId: 'house-456',
        canonicalIngredientId: 'paneer',
        name: 'Fresh Paneer',
        quantity: 400.0,
        unit: 'g',
        amountDescription: null,
        storageLocation: 'fridge',
        expiresAt: DateTime(now.year, now.month, now.day + 2),
        createdAt: now,
      );

      final json = item.toJson();
      final fromJson = PantryItemEntity.fromJson(json);

      expect(fromJson.id, 'item-123');
      expect(fromJson.name, 'Fresh Paneer');
      expect(fromJson.quantity, 400.0);
      expect(fromJson.unit, 'g');
      expect(fromJson.storageLocation, 'fridge');
      expect(fromJson.isExpiringSoon, isTrue);
      expect(fromJson.isExpired, isFalse);
      expect(fromJson.formattedQuantity, '400 g');
    });

    test('correctly identifies expired, expiring soon, and stocked items', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final expiredItem = PantryItemEntity(
        id: '1',
        householdId: 'h1',
        name: 'Old Milk',
        storageLocation: 'fridge',
        expiresAt: today.subtract(const Duration(days: 2)),
        createdAt: now,
      );
      expect(expiredItem.isExpired, isTrue);
      expect(expiredItem.isExpiringSoon, isFalse);
      expect(expiredItem.expirationBadgeText, contains('Expired 2 days ago'));

      final expiresTodayItem = PantryItemEntity(
        id: '2',
        householdId: 'h1',
        name: 'Spinach',
        storageLocation: 'fridge',
        expiresAt: today,
        createdAt: now,
      );
      expect(expiresTodayItem.isExpired, isFalse);
      expect(expiresTodayItem.isExpiringSoon, isTrue);
      expect(expiresTodayItem.expirationBadgeText, 'Expires today');

      final expiresTomorrowItem = PantryItemEntity(
        id: '3',
        householdId: 'h1',
        name: 'Curd',
        storageLocation: 'fridge',
        expiresAt: today.add(const Duration(days: 1)),
        createdAt: now,
      );
      expect(expiresTomorrowItem.isExpired, isFalse);
      expect(expiresTomorrowItem.isExpiringSoon, isTrue);
      expect(expiresTomorrowItem.expirationBadgeText, 'Expires tomorrow');

      final stockedItem = PantryItemEntity(
        id: '4',
        householdId: 'h1',
        name: 'Rice',
        storageLocation: 'pantry',
        expiresAt: today.add(const Duration(days: 45)),
        createdAt: now,
      );
      expect(stockedItem.isExpired, isFalse);
      expect(stockedItem.isExpiringSoon, isFalse);
      expect(stockedItem.expirationBadgeText, '45 days left');

      final noExpiryItem = PantryItemEntity(
        id: '5',
        householdId: 'h1',
        name: 'Salt',
        storageLocation: 'pantry',
        expiresAt: null,
        createdAt: now,
      );
      expect(noExpiryItem.isExpired, isFalse);
      expect(noExpiryItem.isExpiringSoon, isFalse);
      expect(noExpiryItem.expirationBadgeText, 'Stocked');
    });

    test('formattedQuantity handles integers, decimals, and qualitative text', () {
      final item1 = PantryItemEntity(
        id: '1',
        householdId: 'h1',
        name: 'Apples',
        quantity: 5.0,
        unit: 'pcs',
        storageLocation: 'fridge',
        createdAt: DateTime.now(),
      );
      expect(item1.formattedQuantity, '5 pcs');

      final item2 = PantryItemEntity(
        id: '2',
        householdId: 'h1',
        name: 'Sugar',
        quantity: 1.5,
        unit: 'kg',
        storageLocation: 'pantry',
        createdAt: DateTime.now(),
      );
      expect(item2.formattedQuantity, '1.5 kg');

      final item3 = PantryItemEntity(
        id: '3',
        householdId: 'h1',
        name: 'Chutney',
        amountDescription: 'Half jar',
        storageLocation: 'fridge',
        createdAt: DateTime.now(),
      );
      expect(item3.formattedQuantity, 'Half jar');
    });

    test('copyWith updates fields without mutating original entity', () {
      final original = PantryItemEntity(
        id: 'item-1',
        householdId: 'h1',
        name: 'Tomatoes',
        quantity: 500,
        unit: 'g',
        storageLocation: 'fridge',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(quantity: 750, storageLocation: 'pantry');

      expect(original.quantity, 500);
      expect(original.storageLocation, 'fridge');
      expect(updated.quantity, 750);
      expect(updated.storageLocation, 'pantry');
      expect(updated.id, original.id);
      expect(updated.name, original.name);
    });
  });

  group('CanonicalIngredientEntity Unit Tests', () {
    test('calculates default expiration from shelf life', () {
      const canonical = CanonicalIngredientEntity(
        id: 'paneer',
        name: 'Paneer',
        category: 'dairy',
        defaultUnit: 'g',
        shelfLifeDays: 4,
        defaultStorage: 'fridge',
        allergenIds: ['dairy'],
      );

      final now = DateTime.now();
      final defaultExpiry = canonical.calculatedDefaultExpiration;
      final expectedDate = DateTime(now.year, now.month, now.day + 4);

      expect(defaultExpiry.year, expectedDate.year);
      expect(defaultExpiry.month, expectedDate.month);
      expect(defaultExpiry.day, expectedDate.day);
    });
  });
}
