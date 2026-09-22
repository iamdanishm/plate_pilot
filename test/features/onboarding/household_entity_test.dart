import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';

void main() {
  group('HouseholdEntity Domain Tests', () {
    test('serializes and deserializes preferredCuisines and cooking times correctly', () {
      final now = DateTime.now();
      final entity = HouseholdEntity(
        id: 'h_123',
        ownerId: 'user_456',
        name: 'Sharma Family',
        adultsCount: 3,
        childrenCount: 2,
        dietaryRestrictions: ['Vegetarian'],
        allergens: [
          {'id': 'peanuts', 'is_hard_constraint': true}
        ],
        preferredCuisines: ['South Indian', 'Gujarati'],
        maxWeekdayCookingTimeMinutes: 30,
        maxWeekendCookingTimeMinutes: 90,
        weeklyBudget: 5000.0,
        createdAt: now,
        updatedAt: now,
      );

      final json = entity.toJson();
      expect(json['id'], 'h_123');
      expect(json['preferred_cuisines'], ['South Indian', 'Gujarati']);
      expect(json['max_weekday_cooking_time_minutes'], 30);
      expect(json['max_weekend_cooking_time_minutes'], 90);
      expect(json['weekly_budget'], 5000.0);

      final restored = HouseholdEntity.fromJson(json);
      expect(restored.id, 'h_123');
      expect(restored.preferredCuisines, ['South Indian', 'Gujarati']);
      expect(restored.maxWeekdayCookingTimeMinutes, 30);
      expect(restored.maxWeekendCookingTimeMinutes, 90);
      expect(restored.weeklyBudget, 5000.0);
    });

    test('defaults preferredCuisines and cooking times when omitted', () {
      final json = {
        'id': 'h_default',
        'owner_id': 'u_1',
        'name': 'Default Household',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final entity = HouseholdEntity.fromJson(json);
      expect(entity.preferredCuisines, isEmpty);
      expect(entity.maxWeekdayCookingTimeMinutes, 45);
      expect(entity.maxWeekendCookingTimeMinutes, 60);
      expect(entity.adultsCount, 2);
      expect(entity.childrenCount, 0);
      expect(entity.weeklyBudget, 3500.0);
    });

    test('copyWith updates specified fields while preserving others', () {
      final now = DateTime.now();
      final original = HouseholdEntity(
        id: 'h_orig',
        ownerId: 'u_orig',
        name: 'Original',
        preferredCuisines: ['Punjabi'],
        maxWeekdayCookingTimeMinutes: 30,
        maxWeekendCookingTimeMinutes: 60,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        preferredCuisines: ['Punjabi', 'Bengali'],
        maxWeekdayCookingTimeMinutes: 40,
      );

      expect(updated.preferredCuisines, ['Punjabi', 'Bengali']);
      expect(updated.maxWeekdayCookingTimeMinutes, 40);
      expect(updated.maxWeekendCookingTimeMinutes, 60);
      expect(updated.name, 'Original');
    });
  });
}
