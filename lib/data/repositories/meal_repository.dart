import 'package:cloud_firestore/cloud_firestore.dart';
import './analytics_repository.dart';
import '../models/meal_model.dart';

/// This class is a repository for the meal feature.
class MealRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsRepository _analyticsRepository = AnalyticsRepository();
  final String _collection = 'meals';

  /// Creates a new meal.
  ///
  /// The [meal] is the meal to be created.
  ///
  /// Returns the unique identifier of the created meal.
  Future<String> createMeal(MealModel meal) async {
    try {
      final docRef = await _firestore.collection(_collection).add(meal.toMap());
      await _analyticsRepository.updateAnalyticsWithNewMeal(meal.copyWith(id: docRef.id));
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create meal: $e');
    }
  }

  /// Gets a meal by its unique identifier.
  ///
  /// The [mealId] is the unique identifier of the meal.
  ///
  /// Returns a [MealModel] object, or null if the meal is not found.
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

  /// Updates an existing meal.
  ///
  /// The [meal] is the meal to be updated.
  Future<void> updateMeal(MealModel meal) async {
    try {
      final oldMeal = await getMealById(meal.id);
      if (oldMeal != null) {
        await _firestore
            .collection(_collection)
            .doc(meal.id)
            .update(meal.toMap());
        await _analyticsRepository.updateAnalyticsWithUpdatedMeal(
            oldMeal, meal);
      }
    } catch (e) {
      throw Exception('Failed to update meal: $e');
    }
  }

  /// Deletes a meal.
  ///
  /// The [mealId] is the unique identifier of the meal to be deleted.
  Future<void> deleteMeal(String mealId) async {
    try {
      final meal = await getMealById(mealId);
      if (meal != null) {
        await _firestore.collection(_collection).doc(mealId).delete();
        await _analyticsRepository.updateAnalyticsWithDeletedMeal(meal);
      }
    } catch (e) {
      throw Exception('Failed to delete meal: $e');
    }
  }

  /// Gets the meals for a specific date.
  ///
  /// The [userId] is the unique identifier of the user.
  /// The [date] is the date for which to get the meals.
  ///
  /// Returns a list of [MealModel] objects.
  Future<List<MealModel>> getMealsForDate(String userId, DateTime date) async {
    try {
      // Create start and end of day in UTC to match Firestore timestamps
      final startOfDay = DateTime.utc(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: false)
          .get();

      final meals =
          querySnapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList();

      return meals;
    } catch (e) {
      throw Exception('Failed to get meals for date: $e');
    }
  }

  /// Gets the meals in a date range.
  ///
  /// The [userId] is the unique identifier of the user.
  /// The [startDate] is the start of the date range.
  /// The [endDate] is the end of the date range.
  ///
  /// Returns a list of [MealModel] objects.
  Future<List<MealModel>> getMealsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get meals in date range: $e');
    }
  }

  /// Gets the nutrition summary for a date range.
  ///
  /// The [userId] is the unique identifier of the user.
  /// The [startDate] is the start of the date range.
  /// The [endDate] is the end of the date range.
  ///
  /// Returns a map of the nutrition summary.
  Future<Map<String, double>> getNutritionSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
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

  /// Gets all the meals for a user.
  ///
  /// The [userId] is the unique identifier of the user.
  ///
  /// Returns a list of [MealModel] objects.
  Future<List<MealModel>> getAllMealsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final meals =
          querySnapshot.docs.map((doc) => MealModel.fromFirestore(doc)).toList();

      return meals;
    } catch (e) {
      throw Exception('Failed to get all meals for user: $e');
    }
  }

  /// Gets the meals by meal type.
  ///
  /// The [userId] is the unique identifier of the user.
  /// The [mealType] is the type of the meal.
  ///
  /// Returns a list of [MealModel] objects.
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

  /// Searches for meals by name.
  ///
  /// The [userId] is the unique identifier of the user.
  /// The [searchTerm] is the search term.
  ///
  /// Returns a list of [MealModel] objects.
  Future<List<MealModel>> searchMealsByName(
    String userId,
    String searchTerm,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .startAt([searchTerm]).endAt(['$searchTerm\uf8ff']).get();

      return querySnapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search meals: $e');
    }
  }
}