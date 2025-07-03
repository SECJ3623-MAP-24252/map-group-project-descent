import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_model.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'meals';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get meals collection reference
  CollectionReference get _mealsCollection => _firestore.collection(_collection);

  // Add a new meal
  Future<String> addMeal(MealModel meal) async {
    try {
      final docRef = await _mealsCollection.add(meal.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add meal: $e');
    }
  }

  // Update an existing meal
  Future<void> updateMeal(MealModel meal) async {
    try {
      await _mealsCollection.doc(meal.id).update(meal.toMap());
    } catch (e) {
      throw Exception('Failed to update meal: $e');
    }
  }

  // Delete a meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _mealsCollection.doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal: $e');
    }
  }

  // Get a single meal
  Future<MealModel?> getMeal(String mealId) async {
    try {
      final doc = await _mealsCollection.doc(mealId).get();
      if (doc.exists) {
        return MealModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get meal: $e');
    }
  }

  // Get all meals for the current user
  Stream<List<MealModel>> getUserMeals() {
    if (currentUser == null) return Stream.value([]);

    return _mealsCollection
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get meals for a specific date
  Stream<List<MealModel>> getMealsForDate(DateTime date) {
    if (currentUser == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _mealsCollection
        .where('userId', isEqualTo: currentUser!.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get meals by type for a specific date
  Stream<List<MealModel>> getMealsByTypeForDate(DateTime date, String mealType) {
    if (currentUser == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _mealsCollection
        .where('userId', isEqualTo: currentUser!.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .where('mealType', isEqualTo: mealType)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MealModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get daily nutrition summary
  Future<Map<String, double>> getDailyNutritionSummary(DateTime date) async {
    if (currentUser == null) return {};

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _mealsCollection
          .where('userId', isEqualTo: currentUser!.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var doc in snapshot.docs) {
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
      throw Exception('Failed to get daily nutrition summary: $e');
    }
  }
} 