class AppConstants {
  // App Colors
  static const int primaryColor = 0xFFD6F36B;
  static const int secondaryColor = 0xFFFF7A4D;
  static const int backgroundColor = 0xFFFFFFFF;
  static const int textColor = 0xFF000000;
  static const int textLightColor = 0xFF666666;

  // Meal Types
  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch', 
    'Dinner',
    'Snack'
  ];

  // API Configuration
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';
  static const String calorieNinjasApiUrl = 'https://api.calorieninjas.com/v1/nutrition';

  // Local Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String recentFoodsKey = 'recent_foods';
  static const String todaysMealsKey = 'todays_meals';

  // Default Values
  static const double defaultCalorieGoal = 2000.0;
  static const String defaultServingSize = '100g';
  static const double defaultConfidence = 0.8;

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String apiError = 'API error. Please try again.';
  static const String cameraError = 'Camera error. Please check permissions.';
  static const String unknownError = 'An unknown error occurred.';
} 