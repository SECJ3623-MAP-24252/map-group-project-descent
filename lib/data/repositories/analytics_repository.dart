import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_model.dart';
import '../models/user_analytics_model.dart';

class AnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_analytics';

  Future<UserAnalyticsModel?> getAnalytics(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserAnalyticsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Handle errors, e.g., log them
      return null;
    }
  }

  Future<void> updateAnalyticsWithNewMeal(MealModel meal) async {
    final docRef = _firestore.collection(_collection).doc(meal.userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        // Create new analytics document
        final newAnalytics = UserAnalyticsModel(
          userId: meal.userId,
          totalCalories: meal.calories,
          totalProtein: meal.protein,
          totalCarbs: meal.carbs,
          totalFat: meal.fat,
          totalMeals: 1,
          lastUpdated: DateTime.now(),
        );
        transaction.set(docRef, newAnalytics.toMap());
      } else {
        // Update existing analytics document
        final currentAnalytics = UserAnalyticsModel.fromFirestore(snapshot);
        final updatedAnalytics = currentAnalytics.copyWith(
          totalCalories: currentAnalytics.totalCalories + meal.calories,
          totalProtein: currentAnalytics.totalProtein + meal.protein,
          totalCarbs: currentAnalytics.totalCarbs + meal.carbs,
          totalFat: currentAnalytics.totalFat + meal.fat,
          totalMeals: currentAnalytics.totalMeals + 1,
          lastUpdated: DateTime.now(),
        );
        transaction.update(docRef, updatedAnalytics.toMap());
      }
    });
  }

  Future<void> updateAnalyticsWithDeletedMeal(MealModel meal) async {
    final docRef = _firestore.collection(_collection).doc(meal.userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        final currentAnalytics = UserAnalyticsModel.fromFirestore(snapshot);
        final updatedAnalytics = currentAnalytics.copyWith(
          totalCalories: (currentAnalytics.totalCalories - meal.calories).clamp(0.0, double.infinity),
          totalProtein: (currentAnalytics.totalProtein - meal.protein).clamp(0.0, double.infinity),
          totalCarbs: (currentAnalytics.totalCarbs - meal.carbs).clamp(0.0, double.infinity),
          totalFat: (currentAnalytics.totalFat - meal.fat).clamp(0.0, double.infinity),
          totalMeals: (currentAnalytics.totalMeals - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
        transaction.update(docRef, updatedAnalytics.toMap());
      }
    });
  }

  Future<void> updateAnalyticsWithUpdatedMeal(
      MealModel oldMeal, MealModel newMeal) async {
    final docRef = _firestore.collection(_collection).doc(newMeal.userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        final currentAnalytics = UserAnalyticsModel.fromFirestore(snapshot);
        final updatedAnalytics = currentAnalytics.copyWith(
          totalCalories:
              (currentAnalytics.totalCalories - oldMeal.calories + newMeal.calories).clamp(0.0, double.infinity),
          totalProtein:
              (currentAnalytics.totalProtein - oldMeal.protein + newMeal.protein).clamp(0.0, double.infinity),
          totalCarbs:
              (currentAnalytics.totalCarbs - oldMeal.carbs + newMeal.carbs).clamp(0.0, double.infinity),
          totalFat: (currentAnalytics.totalFat - oldMeal.fat + newMeal.fat).clamp(0.0, double.infinity),
          lastUpdated: DateTime.now(),
        );
        transaction.update(docRef, updatedAnalytics.toMap());
      }
    });
  }

  Future<void> recalculateAnalytics(String userId) async {
    final mealsSnapshot = await _firestore
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .get();

    if (mealsSnapshot.docs.isEmpty) {
      // No meals, so no analytics
      await _firestore.collection(_collection).doc(userId).delete();
      return;
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int totalMeals = mealsSnapshot.docs.length;

    for (final doc in mealsSnapshot.docs) {
      final meal = MealModel.fromFirestore(doc);
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    }

    final analytics = UserAnalyticsModel(
      userId: userId,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalMeals: totalMeals,
      lastUpdated: DateTime.now(),
    );

    await _firestore.collection(_collection).doc(userId).set(analytics.toMap());
  }
}
