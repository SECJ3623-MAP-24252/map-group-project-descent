/// This class contains the application-wide constants.
class AppConstants {
  /// The name of the application.
  static const String appName = 'Nutrition Tracker';
  /// The daily calorie goal for the user.
  static const int dailyCalorieGoal = 2000;
  /// The daily protein goal for the user in grams.
  static const double proteinGoal = 150.0;
  /// The daily carbohydrates goal for the user in grams.
  static const double carbsGoal = 250.0;
  /// The daily fat goal for the user in grams.
  static const double fatGoal = 65.0;
  
  // Colors
  /// The primary green color used in the application.
  static const int primaryGreen = 0xFFD6F36B;
  /// The primary orange color used in the application.
  static const int primaryOrange = 0xFFFF7A4D;
  
  // Meal types
  /// A list of meal types that the user can select from.
  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch', 
    'Dinner',
    'Snack'
  ];
}