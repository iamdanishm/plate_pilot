class PantryItemEntity {
  final String id;
  final String householdId;
  final String? canonicalIngredientId;
  final String name;
  final double? quantity;
  final String? unit;
  final String? amountDescription;
  final String storageLocation; // 'pantry', 'fridge', 'freezer'
  final DateTime? expiresAt;
  final DateTime createdAt;

  const PantryItemEntity({
    required this.id,
    required this.householdId,
    this.canonicalIngredientId,
    required this.name,
    this.quantity,
    this.unit,
    this.amountDescription,
    required this.storageLocation,
    this.expiresAt,
    required this.createdAt,
  });

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final difference = expiresAt!.difference(DateTime.now()).inDays;
    return difference <= 3 && difference >= 0;
  }

  factory PantryItemEntity.fromJson(Map<String, dynamic> json) {
    return PantryItemEntity(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      canonicalIngredientId: json['canonical_ingredient_id'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      amountDescription: json['amount_description'] as String?,
      storageLocation: json['storage_location'] as String? ?? 'pantry',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'canonical_ingredient_id': canonicalIngredientId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'amount_description': amountDescription,
      'storage_location': storageLocation,
      'expires_at': expiresAt?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
