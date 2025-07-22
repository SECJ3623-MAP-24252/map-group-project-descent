/// This class is a local database of food items and their nutritional information.
class LocalFoodDatabase {
  static const Map<String, Map<String, dynamic>> _foodDatabase = {
    'apple': {
      'calories': 52,
      'protein': 0.3,
      'carbs': 14.0,
      'fat': 0.2,
      'fiber': 2.4,
      'sugar': 10.4,
      'serving_size': '100g',
    },
    'banana': {
      'calories': 89,
      'protein': 1.1,
      'carbs': 23.0,
      'fat': 0.3,
      'fiber': 2.6,
      'sugar': 12.2,
      'serving_size': '100g',
    },
    'chicken breast': {
      'calories': 165,
      'protein': 31.0,
      'carbs': 0.0,
      'fat': 3.6,
      'fiber': 0.0,
      'sugar': 0.0,
      'serving_size': '100g',
    },
    'rice': {
      'calories': 130,
      'protein': 2.7,
      'carbs': 28.0,
      'fat': 0.3,
      'fiber': 0.4,
      'sugar': 0.1,
      'serving_size': '100g',
    },
    'broccoli': {
      'calories': 34,
      'protein': 2.8,
      'carbs': 7.0,
      'fat': 0.4,
      'fiber': 2.6,
      'sugar': 1.5,
      'serving_size': '100g',
    },
    'salmon': {
      'calories': 208,
      'protein': 25.4,
      'carbs': 0.0,
      'fat': 12.4,
      'fiber': 0.0,
      'sugar': 0.0,
      'serving_size': '100g',
    },
    'bread': {
      'calories': 265,
      'protein': 9.0,
      'carbs': 49.0,
      'fat': 3.2,
      'fiber': 2.7,
      'sugar': 5.0,
      'serving_size': '100g',
    },
    'egg': {
      'calories': 155,
      'protein': 13.0,
      'carbs': 1.1,
      'fat': 11.0,
      'fiber': 0.0,
      'sugar': 1.1,
      'serving_size': '100g',
    },
  };

  /// Search for food in local database
  ///
  /// The [foodName] is the name of the food to search for.
  ///
  /// Returns a map of the food's nutritional information, or null if the food is not found.
  static Map<String, dynamic>? searchFood(String foodName) {
    final cleanName = foodName.toLowerCase().trim();

    // Direct match
    if (_foodDatabase.containsKey(cleanName)) {
      return Map<String, dynamic>.from(_foodDatabase[cleanName]!);
    }

    // Partial match
    for (final entry in _foodDatabase.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return Map<String, dynamic>.from(entry.value);
      }
    }

    return null;
  }

  /// Get all available foods
  ///
  /// Returns a list of all the food names in the database.
  static List<String> getAllFoods() {
    return _foodDatabase.keys.toList();
  }

  /// Add new food to local database (for user customization)
  ///
  /// The [name] is the name of the food to add.
  /// The [nutrition] is a map of the food's nutritional information.
  static void addFood(String name, Map<String, dynamic> nutrition) {
    // In a real app, you'd save this to local storage or Firebase
    print('Would save $name with nutrition: $nutrition');
  }
}