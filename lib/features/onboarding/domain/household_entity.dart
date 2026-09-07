class HouseholdEntity {
  final String id;
  final String ownerId;
  final String name;
  final int adultsCount;
  final int childrenCount;
  final List<String> dietaryRestrictions;
  final List<Map<String, dynamic>> allergens;
  final double weeklyBudget;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HouseholdEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    this.adultsCount = 2,
    this.childrenCount = 0,
    this.dietaryRestrictions = const [],
    this.allergens = const [],
    this.weeklyBudget = 3500.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseholdEntity.fromJson(Map<String, dynamic> json) {
    return HouseholdEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String? ?? 'My Household',
      adultsCount: json['adults_count'] as int? ?? 2,
      childrenCount: json['children_count'] as int? ?? 0,
      dietaryRestrictions: List<String>.from(json['dietary_restrictions'] ?? []),
      allergens: List<Map<String, dynamic>>.from(json['allergens'] ?? []),
      weeklyBudget: (json['weekly_budget'] as num?)?.toDouble() ?? 3500.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'adults_count': adultsCount,
      'children_count': childrenCount,
      'dietary_restrictions': dietaryRestrictions,
      'allergens': allergens,
      'weekly_budget': weeklyBudget,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class HouseholdPreferencesEntity {
  final String householdId;
  final List<String> preferredCuisines;
  final int maxWeekdayCookingTimeMinutes;
  final int maxWeekendCookingTimeMinutes;
  final double weeklyBudget;
  final String currency;
  final List<String> availableEquipment;

  const HouseholdPreferencesEntity({
    required this.householdId,
    required this.preferredCuisines,
    required this.maxWeekdayCookingTimeMinutes,
    required this.maxWeekendCookingTimeMinutes,
    required this.weeklyBudget,
    required this.currency,
    required this.availableEquipment,
  });

  factory HouseholdPreferencesEntity.fromJson(Map<String, dynamic> json) {
    return HouseholdPreferencesEntity(
      householdId: json['household_id'] as String,
      preferredCuisines: List<String>.from(json['preferred_cuisines'] ?? []),
      maxWeekdayCookingTimeMinutes:
          json['max_weekday_cooking_time_minutes'] as int? ?? 45,
      maxWeekendCookingTimeMinutes:
          json['max_weekend_cooking_time_minutes'] as int? ?? 60,
      weeklyBudget: (json['weekly_budget'] as num?)?.toDouble() ?? 3000.0,
      currency: json['currency'] as String? ?? 'INR',
      availableEquipment: List<String>.from(json['available_equipment'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'household_id': householdId,
      'preferred_cuisines': preferredCuisines,
      'max_weekday_cooking_time_minutes': maxWeekdayCookingTimeMinutes,
      'max_weekend_cooking_time_minutes': maxWeekendCookingTimeMinutes,
      'weekly_budget': weeklyBudget,
      'currency': currency,
      'available_equipment': availableEquipment,
    };
  }
}
