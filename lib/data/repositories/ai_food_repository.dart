import 'dart:io';
import '../services/ai_food_service.dart';
import '../services/local_food_database.dart';

/// This class is a repository for the AI food analysis feature.
class AIFoodRepository {
  /// Analyzes a food image and returns the nutritional information.
  ///
  /// The [imageFile] is the image of the food to be analyzed.
  ///
  /// Returns a [Map] containing the nutritional information of the food.
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      return await AIFoodService.analyzeFoodImage(imageFile);
    } catch (e) {
      throw Exception('Failed to analyze food image: ${e.toString()}');
    }
  }

  /// Searches for a food in the local database.
  ///
  /// The [foodName] is the name of the food to be searched.
  ///
  /// Returns a [Map] containing the nutritional information of the food, or null if the food is not found.
  Future<Map<String, dynamic>?> searchLocalFood(String foodName) async {
    try {
      return LocalFoodDatabase.searchFood(foodName);
    } catch (e) {
      throw Exception('Failed to search local food: ${e.toString()}');
    }
  }

  /// Returns a list of all the foods in the local database.
  List<String> getAllLocalFoods() {
    return LocalFoodDatabase.getAllFoods();
  }
}