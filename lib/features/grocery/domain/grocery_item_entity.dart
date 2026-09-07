class GroceryListEntity {
  final String id;
  final String householdId;
  final String? mealPlanId;
  final String status; // 'active', 'archived', 'completed'
  final double? totalEstimatedCost;
  final List<GroceryItemEntity> items;

  const GroceryListEntity({
    required this.id,
    required this.householdId,
    this.mealPlanId,
    required this.status,
    this.totalEstimatedCost,
    this.items = const [],
  });

  factory GroceryListEntity.fromJson(
    Map<String, dynamic> json, {
    List<GroceryItemEntity> items = const [],
  }) {
    return GroceryListEntity(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      mealPlanId: json['meal_plan_id'] as String?,
      status: json['status'] as String? ?? 'active',
      totalEstimatedCost: (json['total_estimated_cost'] as num?)?.toDouble(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'meal_plan_id': mealPlanId,
      'status': status,
      'total_estimated_cost': totalEstimatedCost,
    };
  }
}

class GroceryItemEntity {
  final String id;
  final String groceryListId;
  final String? canonicalIngredientId;
  final String name;
  final double? quantity;
  final String? unit;
  final String? amountDescription;
  final String category;
  final bool isPurchased;
  final double? estimatedPrice;

  const GroceryItemEntity({
    required this.id,
    required this.groceryListId,
    this.canonicalIngredientId,
    required this.name,
    this.quantity,
    this.unit,
    this.amountDescription,
    required this.category,
    required this.isPurchased,
    this.estimatedPrice,
  });

  factory GroceryItemEntity.fromJson(Map<String, dynamic> json) {
    return GroceryItemEntity(
      id: json['id'] as String,
      groceryListId: json['grocery_list_id'] as String,
      canonicalIngredientId: json['canonical_ingredient_id'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      amountDescription: json['amount_description'] as String?,
      category: json['category'] as String? ?? 'produce',
      isPurchased: json['is_purchased'] as bool? ?? false,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grocery_list_id': groceryListId,
      'canonical_ingredient_id': canonicalIngredientId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'amount_description': amountDescription,
      'category': category,
      'is_purchased': isPurchased,
      'estimated_price': estimatedPrice,
    };
  }
}
