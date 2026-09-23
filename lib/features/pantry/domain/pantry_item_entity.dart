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

  /// Days until expiration relative to the beginning of today (calendar-day based).
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    return expiryDate.difference(today).inDays;
  }

  /// Whether this item has passed its expiration date.
  bool get isExpired {
    final days = daysUntilExpiration;
    if (days == null) return false;
    return days < 0;
  }

  /// Whether this item will expire within the next 3 days (inclusive of today).
  bool get isExpiringSoon {
    final days = daysUntilExpiration;
    if (days == null) return false;
    return days >= 0 && days <= 3;
  }

  /// Human-readable quantity representation (e.g. "400 g", "1.5 kg", or "to taste").
  String get formattedQuantity {
    if (quantity != null) {
      final formattedNum = quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toStringAsFixed(1);
      final unitStr = unit != null && unit!.isNotEmpty ? ' $unit' : '';
      return '$formattedNum$unitStr';
    }
    if (amountDescription != null && amountDescription!.isNotEmpty) {
      return amountDescription!;
    }
    return '';
  }

  /// Status badge label for the UI (e.g. "Expired", "Expires today", "Expires in 2 days", "Stocked").
  String get expirationBadgeText {
    final days = daysUntilExpiration;
    if (days == null) return 'Stocked';
    if (days < 0) {
      final pastDays = days.abs();
      return pastDays == 1 ? 'Expired yesterday' : 'Expired $pastDays days ago';
    }
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 3) return 'Expires in $days days';
    return '$days days left';
  }

  PantryItemEntity copyWith({
    String? id,
    String? householdId,
    String? canonicalIngredientId,
    String? name,
    double? quantity,
    String? unit,
    String? amountDescription,
    String? storageLocation,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return PantryItemEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      canonicalIngredientId:
          canonicalIngredientId ?? this.canonicalIngredientId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      amountDescription: amountDescription ?? this.amountDescription,
      storageLocation: storageLocation ?? this.storageLocation,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
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
