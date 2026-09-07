class RecipeEntity {
  final String id;
  final String title;
  final String? description;
  final String? cuisine;
  final String? mealType;
  final String? course;
  final String? diet;
  final int? servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? totalTimeMinutes;
  final String? difficulty;
  final List<String> dietaryProperties;
  final List<RecipeStepEntity> instructions;
  final List<RecipeIngredientEntity> ingredients;
  final String? imageUrl;
  final String? sourceUrl;
  final String? source;
  final String? sourceRecipeId;
  final String? sourceHash;
  final bool isPublic;

  const RecipeEntity({
    required this.id,
    required this.title,
    this.description,
    this.cuisine,
    this.mealType,
    this.course,
    this.diet,
    this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.totalTimeMinutes,
    this.difficulty,
    this.dietaryProperties = const [],
    this.instructions = const [],
    this.ingredients = const [],
    this.imageUrl,
    this.sourceUrl,
    this.source,
    this.sourceRecipeId,
    this.sourceHash,
    this.isPublic = true,
  });

  int get computedTotalTimeMinutes =>
      totalTimeMinutes ?? ((prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0));

  factory RecipeEntity.fromJson(
    Map<String, dynamic> json, {
    List<RecipeIngredientEntity> ingredients = const [],
  }) {
    var rawInstructions = json['instructions'];
    List<RecipeStepEntity> steps = [];
    if (rawInstructions is List) {
      steps = rawInstructions
          .map((s) => RecipeStepEntity.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (rawInstructions is Map && rawInstructions['steps'] is List) {
      steps = (rawInstructions['steps'] as List)
          .map((s) => RecipeStepEntity.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return RecipeEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      cuisine: json['cuisine'] as String?,
      mealType: json['meal_type'] as String?,
      course: json['course'] as String?,
      diet: json['diet'] as String?,
      servings: (json['servings'] as num?)?.toInt() ??
          int.tryParse(json['servings']?.toString() ?? ''),
      prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt() ??
          int.tryParse(json['prep_time_minutes']?.toString() ?? ''),
      cookTimeMinutes: (json['cook_time_minutes'] as num?)?.toInt() ??
          int.tryParse(json['cook_time_minutes']?.toString() ?? ''),
      totalTimeMinutes: (json['total_time_minutes'] as num?)?.toInt() ??
          int.tryParse(json['total_time_minutes']?.toString() ?? ''),
      difficulty: json['difficulty'] as String?,
      dietaryProperties: List<String>.from(json['dietary_properties'] ?? []),
      instructions: steps,
      ingredients: ingredients,
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      source: json['source'] as String?,
      sourceRecipeId: json['source_recipe_id'] as String?,
      sourceHash: json['source_hash'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cuisine': cuisine,
      'meal_type': mealType,
      'course': course,
      'diet': diet,
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'total_time_minutes': totalTimeMinutes,
      'difficulty': difficulty,
      'dietary_properties': dietaryProperties,
      'instructions': instructions.map((s) => s.toJson()).toList(),
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'source': source,
      'source_recipe_id': sourceRecipeId,
      'source_hash': sourceHash,
      'is_public': isPublic,
    };
  }
}

class RecipeStepEntity {
  final int step;
  final String text;

  const RecipeStepEntity({
    required this.step,
    required this.text,
  });

  factory RecipeStepEntity.fromJson(Map<String, dynamic> json) {
    return RecipeStepEntity(
      step: json['step'] as int? ?? 1,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'text': text,
    };
  }
}

class RecipeIngredientEntity {
  final String id;
  final String recipeId;
  final String? canonicalIngredientId;
  final String rawText;
  final String? ingredientName;
  final double? quantity;
  final String? unit;
  final String? amountDescription;
  final String? preparation;
  final bool isOptional;

  const RecipeIngredientEntity({
    required this.id,
    required this.recipeId,
    this.canonicalIngredientId,
    required this.rawText,
    this.ingredientName,
    this.quantity,
    this.unit,
    this.amountDescription,
    this.preparation,
    this.isOptional = false,
  });

  factory RecipeIngredientEntity.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientEntity(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      canonicalIngredientId: json['canonical_ingredient_id'] as String?,
      rawText: json['raw_text'] as String,
      ingredientName: json['ingredient_name'] as String?,
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toDouble()
          : (json['quantity'] != null
              ? double.tryParse(json['quantity'].toString())
              : null),
      unit: json['unit'] as String?,
      amountDescription: json['amount_description'] as String?,
      preparation: json['preparation'] as String?,
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'canonical_ingredient_id': canonicalIngredientId,
      'raw_text': rawText,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'amount_description': amountDescription,
      'preparation': preparation,
      'is_optional': isOptional,
    };
  }
}
