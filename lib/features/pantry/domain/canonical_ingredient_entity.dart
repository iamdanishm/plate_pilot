class CanonicalIngredientEntity {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;
  final int shelfLifeDays;
  final String defaultStorage; // 'pantry', 'fridge', 'freezer'
  final List<String> allergenIds;

  const CanonicalIngredientEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.shelfLifeDays,
    required this.defaultStorage,
    this.allergenIds = const [],
  });

  /// Calculates a default expiration date based on shelf life days from today.
  DateTime get calculatedDefaultExpiration {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + shelfLifeDays);
  }

  factory CanonicalIngredientEntity.fromJson(Map<String, dynamic> json) {
    var rawAllergens = json['allergen_ids'];
    List<String> allergens = [];
    if (rawAllergens is List) {
      allergens = rawAllergens.map((e) => e.toString()).toList();
    }

    return CanonicalIngredientEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'other',
      defaultUnit: json['default_unit'] as String? ?? 'g',
      shelfLifeDays: json['shelf_life_days'] as int? ?? 7,
      defaultStorage: json['default_storage'] as String? ?? 'pantry',
      allergenIds: allergens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'default_unit': defaultUnit,
      'shelf_life_days': shelfLifeDays,
      'default_storage': defaultStorage,
      'allergen_ids': allergenIds,
    };
  }
}
