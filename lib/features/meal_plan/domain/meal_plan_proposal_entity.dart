class PlannedMealProposal {
  final String day;
  final String mealType;
  final String recipeId;
  final String recipeTitle;
  final String reasonSummary;
  final int servings;

  const PlannedMealProposal({
    required this.day,
    required this.mealType,
    required this.recipeId,
    required this.recipeTitle,
    required this.reasonSummary,
    this.servings = 2,
  });

  PlannedMealProposal copyWith({
    String? day,
    String? mealType,
    String? recipeId,
    String? recipeTitle,
    String? reasonSummary,
    int? servings,
  }) {
    return PlannedMealProposal(
      day: day ?? this.day,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      reasonSummary: reasonSummary ?? this.reasonSummary,
      servings: servings ?? this.servings,
    );
  }

  factory PlannedMealProposal.fromJson(Map<String, dynamic> json) {
    return PlannedMealProposal(
      day: json['day'] as String? ?? 'monday',
      mealType: json['meal_type'] as String? ?? 'dinner',
      recipeId: json['recipe_id'] as String? ?? '',
      recipeTitle: json['recipe_title'] as String? ?? '',
      reasonSummary: json['reason_summary'] as String? ?? '',
      servings: json['servings'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'meal_type': mealType,
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
      'reason_summary': reasonSummary,
      'servings': servings,
    };
  }
}

class MealPlanProposalEntity {
  final String weekSummary;
  final List<PlannedMealProposal> plannedMeals;

  const MealPlanProposalEntity({
    required this.weekSummary,
    required this.plannedMeals,
  });

  factory MealPlanProposalEntity.fromJson(Map<String, dynamic> json) {
    final rawDays = json['planned_days'];
    List<PlannedMealProposal> meals = [];
    if (rawDays is List) {
      meals = rawDays
          .map((m) => PlannedMealProposal.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return MealPlanProposalEntity(
      weekSummary: json['week_summary'] as String? ?? 'Your 7-day meal plan',
      plannedMeals: meals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_summary': weekSummary,
      'planned_days': plannedMeals.map((m) => m.toJson()).toList(),
    };
  }
}

class MealSwapProposalEntity {
  final String replacementRecipeId;
  final String replacementRecipeTitle;
  final String reasonSummary;

  const MealSwapProposalEntity({
    required this.replacementRecipeId,
    required this.replacementRecipeTitle,
    required this.reasonSummary,
  });

  factory MealSwapProposalEntity.fromJson(Map<String, dynamic> json) {
    return MealSwapProposalEntity(
      replacementRecipeId: json['replacement_recipe_id'] as String? ?? '',
      replacementRecipeTitle: json['replacement_recipe_title'] as String? ?? '',
      reasonSummary: json['reason_summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'replacement_recipe_id': replacementRecipeId,
      'replacement_recipe_title': replacementRecipeTitle,
      'reason_summary': reasonSummary,
    };
  }
}
