import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/food_model.dart';
import '../models/meal_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // User Operations
  static Future<void> saveUser(UserModel user) async {
    if (user.uid == null) return;
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());
  }

  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update(data);
  }

  // Food Operations
  static Future<void> saveFood(FoodModel food) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(food.id)
        .set(food.toMap());
  }

  static Future<List<FoodModel>> getUserFoods() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foods')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user foods: $e');
      return [];
    }
  }

  static Future<List<FoodModel>> getFoodsByDate(DateTime date) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foods')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThan: endOfDay.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting foods by date: $e');
      return [];
    }
  }

  static Future<void> deleteFood(String foodId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .doc(foodId)
        .delete();
  }

  // Meal Operations
  static Future<void> saveMeal(MealModel meal) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap());
  }

  static Future<List<MealModel>> getUserMeals() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user meals: $e');
      return [];
    }
  }

  static Future<List<MealModel>> getMealsByDate(DateTime date) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .where('date', isEqualTo: dateString)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting meals by date: $e');
      return [];
    }
  }

  static Future<void> deleteMeal(String mealId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId)
        .delete();
  }

  // Nutrition Summary Operations
  static Future<Map<String, dynamic>> getNutritionSummary(DateTime date) async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final foods = await getFoodsByDate(date);
      final meals = await getMealsByDate(date);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;

      // Calculate from foods
      for (final food in foods) {
        totalCalories += food.calories;
        totalProtein += food.nutrition['protein'] ?? 0;
        totalCarbs += food.nutrition['carbs'] ?? 0;
        totalFat += food.nutrition['fat'] ?? 0;
        totalFiber += food.nutrition['fiber'] ?? 0;
        totalSugar += food.nutrition['sugar'] ?? 0;
      }

      // Calculate from meals
      for (final meal in meals) {
        totalCalories += meal.totalCalories;
        for (final food in meal.items) {
          totalProtein += food.nutrition['protein'] ?? 0;
          totalCarbs += food.nutrition['carbs'] ?? 0;
          totalFat += food.nutrition['fat'] ?? 0;
          totalFiber += food.nutrition['fiber'] ?? 0;
          totalSugar += food.nutrition['sugar'] ?? 0;
        }
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'fiber': totalFiber,
        'sugar': totalSugar,
        'date': date.toIso8601String(),
      };
    } catch (e) {
      print('Error getting nutrition summary: $e');
      return {};
    }
  }

  // User Preferences
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('settings')
        .set(preferences);
  }

  static Future<Map<String, dynamic>> getUserPreferences() async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings')
          .get();

      return doc.data() ?? {};
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }

  // Recent Foods (for quick access)
  static Future<void> saveRecentFood(FoodModel food) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recent_foods')
        .doc(food.id)
        .set({
          ...food.toMap(),
          'lastUsed': FieldValue.serverTimestamp(),
        });
  }

  static Future<List<FoodModel>> getRecentFoods({int limit = 10}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recent_foods')
          .orderBy('lastUsed', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recent foods: $e');
      return [];
    }
  }
} 