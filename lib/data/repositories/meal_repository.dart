import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_model.dart';
import '../services/firebase_service.dart';

class MealRepository {
  final FirebaseService _firebaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MealRepository(this._firebaseService);

  // Create a new meal
  Future<String> createMeal(MealModel meal) async {
    try {
      final docRef = await _firestore.collection('meals').add(meal.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create meal: ${e.toString()}');
    }
  }

  // Get meals for a specific user and date
  Future<List<MealModel>> getMealsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get meals: ${e.toString()}');
    }
  }

  // Update meal
  Future<void> updateMeal(MealModel meal) async {
    try {
      await _firestore.collection('meals').doc(meal.id).update(meal.toMap());
    } catch (e) {
      throw Exception('Failed to update meal: ${e.toString()}');
    }
  }

  // Delete meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _firestore.collection('meals').doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal: ${e.toString()}');
    }
  }

  // Get nutrition summary for date range
  Future<Map<String, double>> getNutritionSummary(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final doc in querySnapshot.docs) {
        final meal = MealModel.fromFirestore(doc);
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
      throw Exception('Failed to get nutrition summary: ${e.toString()}');
    }
  }
}
