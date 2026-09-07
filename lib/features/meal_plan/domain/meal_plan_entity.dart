class MealPlanEntity {
  final String id;
  final String householdId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'proposed', 'confirmed', 'completed', 'cancelled'
  final double? targetBudget;
  final double? estimatedCost;
  final String? notes;
  final List<MealPlanItemEntity> items;

  const MealPlanEntity({
    required this.id,
    required this.householdId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.targetBudget,
    this.estimatedCost,
    this.notes,
    this.items = const [],
  });

  factory MealPlanEntity.fromJson(
    Map<String, dynamic> json, {
    List<MealPlanItemEntity> items = const [],
  }) {
    return MealPlanEntity(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String? ?? 'proposed',
      targetBudget: (json['target_budget'] as num?)?.toDouble(),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'status': status,
      'target_budget': targetBudget,
      'estimated_cost': estimatedCost,
      'notes': notes,
    };
  }
}

class MealPlanItemEntity {
  final String id;
  final String mealPlanId;
  final String recipeId;
  final DateTime plannedDate;
  final String? mealType;
  final int servings;
  final List<String> reasonCodes;
  final bool isCompleted;

  const MealPlanItemEntity({
    required this.id,
    required this.mealPlanId,
    required this.recipeId,
    required this.plannedDate,
    this.mealType,
    required this.servings,
    required this.reasonCodes,
    required this.isCompleted,
  });

  factory MealPlanItemEntity.fromJson(Map<String, dynamic> json) {
    return MealPlanItemEntity(
      id: json['id'] as String,
      mealPlanId: json['meal_plan_id'] as String,
      recipeId: json['recipe_id'] as String,
      plannedDate: DateTime.parse(json['planned_date'] as String),
      mealType: json['meal_type'] as String?,
      servings: json['servings'] as int? ?? 2,
      reasonCodes: List<String>.from(json['reason_codes'] ?? []),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_plan_id': mealPlanId,
      'recipe_id': recipeId,
      'planned_date': plannedDate.toIso8601String().split('T').first,
      'meal_type': mealType,
      'servings': servings,
      'reason_codes': reasonCodes,
      'is_completed': isCompleted,
    };
  }
}
