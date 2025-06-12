import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? imageUrl;
  final String mealType; // breakfast, lunch, dinner, snack
  final Map<String, dynamic>? additionalNutrients;

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
  });

  // Convert MealModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'mealType': mealType,
      'additionalNutrients': additionalNutrients,
    };
  }

  // Create MealModel from Firestore document
  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      mealType: data['mealType'] ?? 'other',
      additionalNutrients: data['additionalNutrients'],
    );
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
    );
  }
} 