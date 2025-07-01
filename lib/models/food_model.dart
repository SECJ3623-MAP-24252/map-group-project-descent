class FoodModel {
  final String id;
  final String name;
  final String mealType;
  final double calories;
  final Map<String, dynamic> nutrition;
  final List<String> ingredients;
  final String servingSize;
  final String source;
  final String? imagePath;
  final DateTime timestamp;
  final double? confidence;

  FoodModel({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.nutrition,
    required this.ingredients,
    required this.servingSize,
    required this.source,
    this.imagePath,
    required this.timestamp,
    this.confidence,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      mealType: map['mealType'] ?? '',
      calories: (map['calories'] ?? 0).toDouble(),
      nutrition: Map<String, dynamic>.from(map['nutrition'] ?? {}),
      ingredients: List<String>.from(map['ingredients'] ?? []),
      servingSize: map['servingSize'] ?? '',
      source: map['source'] ?? '',
      imagePath: map['imagePath'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      confidence: map['confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType,
      'calories': calories,
      'nutrition': nutrition,
      'ingredients': ingredients,
      'servingSize': servingSize,
      'source': source,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
    };
  }

  FoodModel copyWith({
    String? id,
    String? name,
    String? mealType,
    double? calories,
    Map<String, dynamic>? nutrition,
    List<String>? ingredients,
    String? servingSize,
    String? source,
    String? imagePath,
    DateTime? timestamp,
    double? confidence,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      nutrition: nutrition ?? this.nutrition,
      ingredients: ingredients ?? this.ingredients,
      servingSize: servingSize ?? this.servingSize,
      source: source ?? this.source,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
    );
  }
} 