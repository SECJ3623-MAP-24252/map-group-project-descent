import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_model.dart';

class MealRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'meals';

  // Create a new meal
  Future<String> createMeal(MealModel meal) async {
    try {
      final docRef = await _firestore.collection(_collection).add(meal.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create meal: $e');
    }
  }

  // Get meal by ID
  Future<MealModel?> getMealById(String mealId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(mealId).get();
      if (doc.exists) {
        return MealModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get meal: $e');
    }
  }

  // Update an existing meal
  Future<void> updateMeal(MealModel meal) async {
    try {
      await _firestore.collection(_collection).doc(meal.id).update(meal.toMap());
    } catch (e) {
      throw Exception('Failed to update meal: $e');
    }
  }

  // Delete a meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _firestore.collection(_collection).doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal: $e');
    }
  }

  // Get meals for a specific date
  Future<List<MealModel>> getMealsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get meals for date: $e');
    }
  }

  // Get meals in a date range
  Future<List<MealModel>> getMealsInDateRange(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get meals in date range: $e');
    }
  }

  // Get nutrition summary for a date range
  Future<Map<String, double>> getNutritionSummary(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final meals = await getMealsInDateRange(userId, startDate, endDate);
      
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final meal in meals) {
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFat += meal.fat;
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
    } catch (e) {
      throw Exception('Failed to get nutrition summary: $e');
    }
  }

  // Get all meals for a user
  Future<List<MealModel>> getAllMealsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all meals for user: $e');
    }
  }

  // Get meals by meal type
  Future<List<MealModel>> getMealsByType(String userId, String mealType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('mealType', isEqualTo: mealType)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get meals by type: $e');
    }
  }

  // Search meals by name
  Future<List<MealModel>> searchMealsByName(String userId, String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .startAt([searchTerm])
          .endAt([searchTerm + '\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search meals: $e');
    }
  }
}
