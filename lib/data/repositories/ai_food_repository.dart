import 'dart:io';
import '../services/ai_food_service.dart';
import '../services/local_food_database.dart';

class AIFoodRepository {
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      return await AIFoodService.analyzeFoodImage(imageFile);
    } catch (e) {
      throw Exception('Failed to analyze food image: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> searchLocalFood(String foodName) async {
    try {
      return LocalFoodDatabase.searchFood(foodName);
    } catch (e) {
      throw Exception('Failed to search local food: ${e.toString()}');
    }
  }

  List<String> getAllLocalFoods() {
    return LocalFoodDatabase.getAllFoods();
  }
}
