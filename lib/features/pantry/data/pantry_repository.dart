import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/pantry/domain/canonical_ingredient_entity.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';

abstract class IPantryRepository {
  Future<List<PantryItemEntity>> getPantryItems(String householdId);

  Future<PantryItemEntity> addPantryItem({
    required String householdId,
    required String name,
    String? canonicalIngredientId,
    double? quantity,
    String? unit,
    String? amountDescription,
    required String storageLocation,
    DateTime? expiresAt,
  });

  Future<PantryItemEntity> updatePantryItem(PantryItemEntity item);

  Future<void> deletePantryItem(String itemId);

  Future<List<CanonicalIngredientEntity>> searchCanonicalIngredients(
    String query, {
    int limit = 10,
  });
}

class PantryRepository implements IPantryRepository {
  final supabase.SupabaseClient _client;

  PantryRepository(this._client);

  @override
  Future<List<PantryItemEntity>> getPantryItems(String householdId) async {
    if (householdId.isEmpty || householdId == 'default') return [];

    try {
      final response = await _client
          .from('pantry_items')
          .select()
          .eq('household_id', householdId)
          .order('expires_at', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PantryItemEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pantry items: $e');
    }
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
    try {
      final payload = <String, dynamic>{
        'household_id': householdId,
        'name': name.trim(),
        'storage_location': storageLocation,
      };

      if (canonicalIngredientId != null && canonicalIngredientId.isNotEmpty) {
        payload['canonical_ingredient_id'] = canonicalIngredientId;
      }
      if (quantity != null) {
        payload['quantity'] = quantity;
      }
      if (unit != null && unit.isNotEmpty) {
        payload['unit'] = unit;
      }
      if (amountDescription != null && amountDescription.isNotEmpty) {
        payload['amount_description'] = amountDescription;
      }
      if (expiresAt != null) {
        payload['expires_at'] = expiresAt.toIso8601String().split('T').first;
      }

      final response = await _client
          .from('pantry_items')
          .insert(payload)
          .select()
          .single();

      return PantryItemEntity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add pantry item: $e');
    }
  }

  @override
  Future<PantryItemEntity> updatePantryItem(PantryItemEntity item) async {
    try {
      final payload = <String, dynamic>{
        'name': item.name.trim(),
        'storage_location': item.storageLocation,
        'quantity': item.quantity,
        'unit': item.unit,
        'amount_description': item.amountDescription,
        'canonical_ingredient_id': item.canonicalIngredientId,
        'expires_at': item.expiresAt?.toIso8601String().split('T').first,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('pantry_items')
          .update(payload)
          .eq('id', item.id)
          .select()
          .single();

      return PantryItemEntity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update pantry item: $e');
    }
  }

  @override
  Future<void> deletePantryItem(String itemId) async {
    try {
      await _client.from('pantry_items').delete().eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to delete pantry item: $e');
    }
  }

  @override
  Future<List<CanonicalIngredientEntity>> searchCanonicalIngredients(
    String query, {
    int limit = 10,
  }) async {
    try {
      final trimmed = query.trim();
      var dbQuery = _client.from('canonical_ingredients').select();

      if (trimmed.isNotEmpty) {
        dbQuery = dbQuery.or('name.ilike.%$trimmed%,id.ilike.%$trimmed%');
      }

      final response = await dbQuery.limit(limit);
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((item) =>
              CanonicalIngredientEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search canonical ingredients: $e');
    }
  }
}

final pantryRepositoryProvider = Provider<IPantryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PantryRepository(client);
});
