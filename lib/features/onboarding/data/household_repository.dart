import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';

abstract class IHouseholdRepository {
  Future<HouseholdEntity?> getCurrentUserHousehold(String userId);
  Future<List<Map<String, dynamic>>> fetchMasterAllergens();
  Future<HouseholdEntity> createHouseholdWithProfile({
    required String userId,
    required String householdName,
    required int adultsCount,
    required int childrenCount,
    required List<String> dietaryRestrictions,
    required List<Map<String, dynamic>> allergens,
    required List<String> preferredCuisines,
    required int maxWeekdayCookingTime,
    required int maxWeekendCookingTime,
    required double weeklyBudget,
    required String currency,
  });
  Future<void> updateHouseholdMembers({
    required String householdId,
    required int adultsCount,
    required int childrenCount,
    List<String> dietaryRestrictions = const [],
  });
  Future<void> updateWeeklyBudget({
    required String householdId,
    required double weeklyBudget,
  });
}

class HouseholdRepository implements IHouseholdRepository {
  final supabase.SupabaseClient _client;

  HouseholdRepository(this._client);

  @override
  Future<HouseholdEntity?> getCurrentUserHousehold(String userId) async {
    final response = await _client
        .from('households')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final householdId = response['id'] as String;

    // Fetch related household configurations
    List<Map<String, dynamic>> members = [];
    Map<String, dynamic>? preferences;
    List<Map<String, dynamic>> allergens = [];

    try {
      final membersFuture = _client
          .from('household_members')
          .select()
          .eq('household_id', householdId);
      final preferencesFuture = _client
          .from('household_preferences')
          .select()
          .eq('household_id', householdId)
          .maybeSingle();
      final allergensFuture = _client
          .from('household_allergens')
          .select()
          .eq('household_id', householdId);

      final results = await Future.wait<dynamic>([
        membersFuture,
        preferencesFuture,
        allergensFuture,
      ]);

      members = List<Map<String, dynamic>>.from(results[0] as List);
      preferences = results[1] as Map<String, dynamic>?;
      allergens = List<Map<String, dynamic>>.from(results[2] as List);
    } catch (_) {
      // If related queries fail or in mocked environment, continue with defaults
    }

    int adults = 0;
    int children = 0;
    final dietaryRestrictions = <String>{};

    for (final member in members) {
      final name = member['name'] as String? ?? '';
      if (name.toLowerCase().startsWith('child')) {
        children++;
      } else {
        adults++;
      }
      final diets = member['dietary_restrictions'];
      if (diets is List) {
        for (final d in diets) {
          dietaryRestrictions.add(d.toString());
        }
      }
    }

    final double weeklyBudget =
        (preferences?['weekly_budget'] as num?)?.toDouble() ?? 3500.0;
    final List<Map<String, dynamic>> parsedAllergens = allergens
        .map((a) => {
              'allergen_id': a['allergen_id'],
              'custom_allergen': a['custom_allergen'],
              'is_hard_constraint': a['is_hard_constraint'] ?? true,
            })
        .toList();

    return HouseholdEntity(
      id: householdId,
      ownerId: response['owner_id'] as String,
      name: response['name'] as String? ?? 'My Household',
      adultsCount: adults > 0 ? adults : (response['adults_count'] as int? ?? 2),
      childrenCount: children > 0 ? children : (response['children_count'] as int? ?? 0),
      dietaryRestrictions: dietaryRestrictions.isNotEmpty
          ? dietaryRestrictions.toList()
          : List<String>.from(response['dietary_restrictions'] ?? []),
      allergens: parsedAllergens.isNotEmpty
          ? parsedAllergens
          : List<Map<String, dynamic>>.from(response['allergens'] ?? []),
      weeklyBudget: preferences != null
          ? weeklyBudget
          : (response['weekly_budget'] as num?)?.toDouble() ?? 3500.0,
      createdAt: DateTime.parse(response['created_at'] as String),
      updatedAt: DateTime.parse(response['updated_at'] as String),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMasterAllergens() async {
    final response = await _client.from('allergens').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Set<String>? _cachedValidAllergenIds;

  Future<Set<String>> _fetchKnownAllergenIds() async {
    if (_cachedValidAllergenIds != null && _cachedValidAllergenIds!.isNotEmpty) {
      return _cachedValidAllergenIds!;
    }
    try {
      final rows = await _client.from('allergens').select('id');
      _cachedValidAllergenIds = (rows as List)
          .map((r) => (r['id'] as String).toLowerCase())
          .toSet();
      return _cachedValidAllergenIds!;
    } catch (_) {
      return const {
        'peanuts',
        'peanut',
        'tree_nuts',
        'tree_nut',
        'dairy',
        'gluten',
        'soy',
        'seafood',
        'fish',
        'shellfish',
        'eggs',
        'egg',
        'mustard',
        'sesame',
      };
    }
  }

  @override
  Future<HouseholdEntity> createHouseholdWithProfile({
    required String userId,
    required String householdName,
    required int adultsCount,
    required int childrenCount,
    required List<String> dietaryRestrictions,
    required List<Map<String, dynamic>> allergens,
    required List<String> preferredCuisines,
    required int maxWeekdayCookingTime,
    required int maxWeekendCookingTime,
    required double weeklyBudget,
    required String currency,
  }) async {
    final effectiveUserId = userId.isNotEmpty
        ? userId
        : _client.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // 1. Insert household
    final householdData = await _client.from('households').insert({
      'owner_id': effectiveUserId,
      'name': householdName.trim().isEmpty ? 'My Household' : householdName.trim(),
    }).select().single();

    final householdId = householdData['id'] as String;

    // 2. Insert members
    final List<Map<String, dynamic>> membersToInsert = [];
    for (int i = 1; i <= adultsCount; i++) {
      membersToInsert.add({
        'household_id': householdId,
        'name': i == 1 ? 'Primary Member' : 'Adult $i',
        'dietary_restrictions': dietaryRestrictions,
      });
    }
    for (int i = 1; i <= childrenCount; i++) {
      membersToInsert.add({
        'household_id': householdId,
        'name': 'Child $i',
        'dietary_restrictions': dietaryRestrictions,
      });
    }

    if (membersToInsert.isNotEmpty) {
      await _client.from('household_members').insert(membersToInsert);
    }

    // 3. Insert preferences
    await _client.from('household_preferences').insert({
      'household_id': householdId,
      'preferred_cuisines': preferredCuisines,
      'max_weekday_cooking_time_minutes': maxWeekdayCookingTime,
      'max_weekend_cooking_time_minutes': maxWeekendCookingTime,
      'weekly_budget': weeklyBudget,
      'currency': currency,
      'available_equipment': ['Stove', 'Pressure Cooker', 'Pan', 'Mixer Grinder'],
    });

    // 4. Insert allergens
    if (allergens.isNotEmpty) {
      final knownIds = await _fetchKnownAllergenIds();
      final allergenRows = allergens.map((a) {
        final rawId = a['allergen_id']?.toString().trim();
        final custom = a['custom_allergen']?.toString().trim();
        final bool isKnownTaxonomy = rawId != null && knownIds.contains(rawId.toLowerCase());

        return {
          'household_id': householdId,
          'allergen_id': isKnownTaxonomy ? rawId : null,
          'custom_allergen': isKnownTaxonomy
              ? (custom != null && custom.isNotEmpty ? custom : null)
              : (custom != null && custom.isNotEmpty ? custom : rawId),
          'is_hard_constraint': a['is_hard_constraint'] ?? true,
        };
      }).toList();
      await _client.from('household_allergens').insert(allergenRows);
    }

    return HouseholdEntity(
      id: householdId,
      ownerId: effectiveUserId,
      name: householdData['name'] as String? ?? householdName,
      adultsCount: adultsCount,
      childrenCount: childrenCount,
      dietaryRestrictions: dietaryRestrictions,
      allergens: allergens,
      weeklyBudget: weeklyBudget,
      createdAt: DateTime.parse(householdData['created_at'] as String),
      updatedAt: DateTime.parse(householdData['updated_at'] as String),
    );
  }

  @override
  Future<void> updateHouseholdMembers({
    required String householdId,
    required int adultsCount,
    required int childrenCount,
    List<String> dietaryRestrictions = const [],
  }) async {
    // Delete existing members for household
    await _client
        .from('household_members')
        .delete()
        .eq('household_id', householdId);

    // Re-insert updated members
    final membersToInsert = <Map<String, dynamic>>[];
    for (int i = 1; i <= adultsCount; i++) {
      membersToInsert.add({
        'household_id': householdId,
        'name': i == 1 ? 'Primary Member' : 'Adult $i',
        'dietary_restrictions': dietaryRestrictions,
      });
    }
    for (int i = 1; i <= childrenCount; i++) {
      membersToInsert.add({
        'household_id': householdId,
        'name': 'Child $i',
        'dietary_restrictions': dietaryRestrictions,
      });
    }

    if (membersToInsert.isNotEmpty) {
      await _client.from('household_members').insert(membersToInsert);
    }
  }

  @override
  Future<void> updateWeeklyBudget({
    required String householdId,
    required double weeklyBudget,
  }) async {
    await _client.from('household_preferences').update({
      'weekly_budget': weeklyBudget,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('household_id', householdId);
  }
}

final householdRepositoryProvider = Provider<IHouseholdRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HouseholdRepository(client);
});

final currentUserHouseholdProvider = FutureProvider<HouseholdEntity?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;
  if (user == null) return null;

  final repository = ref.watch(householdRepositoryProvider);
  return repository.getCurrentUserHousehold(user.id);
});

final masterAllergensProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(householdRepositoryProvider);
  return repository.fetchMasterAllergens();
});

