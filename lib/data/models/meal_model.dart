import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single ingredient in a meal.
class IngredientModel {
  /// The name of the ingredient.
  final String name;
  /// The weight of the ingredient.
  final String weight;
  /// The number of calories in the ingredient.
  final int calories;
  /// The amount of protein in the ingredient.
  final double? protein;
  /// The amount of carbohydrates in the ingredient.
  final double? carbs;
  /// The amount of fat in the ingredient.
  final double? fat;

  /// Creates a new instance of the [IngredientModel] class.
  IngredientModel({
    required this.name,
    required this.weight,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  /// Converts this [IngredientModel] to a [Map].
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weight': weight,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  /// Creates a new instance of the [IngredientModel] class from a [Map].
  factory IngredientModel.fromMap(Map<String, dynamic> map) {
    return IngredientModel(
      name: map['name'] ?? '',
      weight: map['weight'] ?? '0g',
      calories: (map['calories'] ?? 0).toInt(),
      protein: map['protein']?.toDouble(),
      carbs: map['carbs']?.toDouble(),
      fat: map['fat']?.toDouble(),
    );
  }
}

/// Represents a meal.
class MealModel {
  /// The unique identifier of the meal.
  final String id;
  /// The unique identifier of the user who created the meal.
  final String userId;
  /// The name of the meal.
  final String name;
  /// A description of the meal.
  final String? description;
  /// The number of calories in the meal.
  final double calories;
  /// The amount of protein in the meal.
  final double protein;
  /// The amount of carbohydrates in the meal.
  final double carbs;
  /// The amount of fat in the meal.
  final double fat;
  /// The date and time the meal was created.
  final DateTime timestamp;
  /// The URL of an image of the meal.
  final String? imageUrl; // Now stores base64 image data
  /// The type of meal (e.g., breakfast, lunch, dinner, snack).
  final String mealType; // breakfast, lunch, dinner, snack
  /// A map of additional nutrients in the meal.
  final Map<String, dynamic>? additionalNutrients;
  /// A list of ingredients in the meal.
  final List<IngredientModel>? ingredients; // Store individual ingredients
  /// The source of the meal data (e.g., 'ai_scan', 'manual').
  final String? scanSource; // 'ai_scan', 'manual', etc.

  /// Creates a new instance of the [MealModel] class.
  MealModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    this.imageUrl,
    required this.mealType,
    this.additionalNutrients,
    this.ingredients,
    this.scanSource,
  });

  /// Converts this [MealModel] to a [Map] for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl, // Fixed the field name
      'mealType': mealType,
      'additionalNutrients': additionalNutrients,
      'ingredients': ingredients?.map((ing) => ing.toMap()).toList(),
      'scanSource': scanSource,
    };
  }

  /// Creates a new instance of the [MealModel] class from a Firestore document.
  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<IngredientModel>? ingredientsList;
    if (data['ingredients'] != null) {
      ingredientsList = (data['ingredients'] as List)
          .map((ing) => IngredientModel.fromMap(ing as Map<String, dynamic>))
          .toList();
    }
    
    // Handle both imageUrl and imageUr1 (typo in your Firebase data)
    String? imageUrl = data['imageUrl'] ?? data['imageUr1'];
    
    final meal = MealModel(
      id: doc.id, // Use document ID
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: imageUrl,
      mealType: data['mealType'] ?? 'other',
      additionalNutrients: data['additionalNutrients'],
      ingredients: ingredientsList,
      scanSource: data['scanSource'],
    );
    
    return meal;
  }

  /// Creates a copy of this [MealModel] with the given fields updated.
  MealModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? timestamp,
    String? imageUrl,
    String? mealType,
    Map<String, dynamic>? additionalNutrients,
    List<IngredientModel>? ingredients,
    String? scanSource,
  }) {
    return MealModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      mealType: mealType ?? this.mealType,
      additionalNutrients: additionalNutrients ?? this.additionalNutrients,
      ingredients: ingredients ?? this.ingredients,
      scanSource: scanSource ?? this.scanSource,
    );
  }
}