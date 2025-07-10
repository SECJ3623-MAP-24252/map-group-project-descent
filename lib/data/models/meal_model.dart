import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientModel {
  final String name;
  final String weight;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  IngredientModel({
    required this.name,
    required this.weight,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

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

class MealModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;
  final String? imageUrl; // Now stores base64 image data
  final String mealType; // breakfast, lunch, dinner, snack
  final Map<String, dynamic>? additionalNutrients;
  final List<IngredientModel>? ingredients; // Store individual ingredients
  final String? scanSource; // 'ai_scan', 'manual', etc.

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

  // Convert MealModel to Map for Firestore
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

  // Create MealModel from Firestore document
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

  // Create a copy of MealModel with updated fields
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
