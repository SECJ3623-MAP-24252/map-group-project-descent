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
      print('Creating meal in Firestore: ${meal.name}');
      final docRef = await _firestore.collection('meals').add(meal.toMap());
      print('Meal created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating meal in Firestore: $e');
      throw Exception('Failed to create meal: ${e.toString()}');
    }
  }

  // Get meals for a specific user and date
  Future<List<MealModel>> getMealsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('Getting meals for user $userId on ${date.toString()}');
      print('Date range: ${startOfDay.toString()} to ${endOfDay.toString()}');

      final querySnapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .orderBy('timestamp')
          .get();

      print('Found ${querySnapshot.docs.length} meals for the date');

      final meals = querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
      
      for (final meal in meals) {
        print('Loaded meal: ${meal.id} - ${meal.name} (${meal.calories} cal)');
      }
      
      return meals;
    } catch (e) {
      print('Error getting meals for date: $e');
      throw Exception('Failed to get meals: ${e.toString()}');
    }
  }

  // Get a specific meal by ID
  Future<MealModel?> getMealById(String mealId) async {
    try {
      print('Getting meal by ID: $mealId');
      
      if (mealId.isEmpty) {
        print('Meal ID is empty');
        return null;
      }
      
      final doc = await _firestore.collection('meals').doc(mealId).get();
      
      if (doc.exists) {
        print('Meal found: ${doc.id}');
        final meal = MealModel.fromFirestore(doc);
        print('Meal details: ${meal.name} - ${meal.calories} cal');
        return meal;
      } else {
        print('Meal not found with ID: $mealId');
        return null;
      }
    } catch (e) {
      print('Error getting meal by ID: $e');
      throw Exception('Failed to get meal: ${e.toString()}');
    }
  }

  // Update meal
  Future<void> updateMeal(MealModel meal) async {
    try {
      print('Updating meal in Firestore: ${meal.id} - ${meal.name}');
      
      if (meal.id.isEmpty) {
        throw Exception('Meal ID is required for update');
      }

      // Convert meal to map for Firestore
      final mealData = meal.toMap();
      print('Meal data to update: $mealData');

      // Update the document
      await _firestore.collection('meals').doc(meal.id).update(mealData);
      print('Meal updated successfully in Firestore');

      // Verify the update by reading the document back
      final updatedDoc = await _firestore.collection('meals').doc(meal.id).get();
      if (updatedDoc.exists) {
        final updatedMeal = MealModel.fromFirestore(updatedDoc);
        print('Verification: Updated meal name is now: ${updatedMeal.name}');
        print('Verification: Updated meal calories: ${updatedMeal.calories}');
        print('Verification: Updated meal ingredients: ${updatedMeal.ingredients?.length ?? 0}');
      } else {
        print('Warning: Could not verify meal update - document not found');
      }
      
    } catch (e) {
      print('Error updating meal in Firestore: $e');
      throw Exception('Failed to update meal: ${e.toString()}');
    }
  }

  // Delete meal
  Future<void> deleteMeal(String mealId) async {
    try {
      print('Deleting meal from Firestore: $mealId');
      
      if (mealId.isEmpty) {
        throw Exception('Meal ID is required for deletion');
      }
      
      // Check if meal exists before deleting
      final doc = await _firestore.collection('meals').doc(mealId).get();
      if (!doc.exists) {
        throw Exception('Meal not found with ID: $mealId');
      }
      
      await _firestore.collection('meals').doc(mealId).delete();
      print('Meal deleted successfully from Firestore');
    } catch (e) {
      print('Error deleting meal from Firestore: $e');
      throw Exception('Failed to delete meal: ${e.toString()}');
    }
  }

  // Get nutrition summary for date range
  Future<Map<String, double>> getNutritionSummary(String userId, DateTime startDate, DateTime endDate) async {
    try {
      print('Getting nutrition summary for user $userId from ${startDate.toString()} to ${endDate.toString()}');
      
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

      print('Found ${querySnapshot.docs.length} meals for nutrition summary');

      for (final doc in querySnapshot.docs) {
        final meal = MealModel.fromFirestore(doc);
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFat += meal.fat;
        print('Added meal to summary: ${meal.name} - ${meal.calories} cal');
      }

      final summary = {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
      
      print('Nutrition summary: $summary');
      return summary;
    } catch (e) {
      print('Error getting nutrition summary: $e');
      throw Exception('Failed to get nutrition summary: ${e.toString()}');
    }
  }
}
