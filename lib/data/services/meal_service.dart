import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's meals collection reference
  CollectionReference get _mealsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('meals');
  }

  // Add a new meal
  Future<void> addMeal({
    required String name,
    required List<String> items,
    required int calories,
    required String time,
    required String type,
    List<Map<String, dynamic>>? ingredients,
    String? imagePath,
  }) async {
    final mealData = {
      'name': name,
      'items': items,
      'calories': calories,
      'time': time,
      'type': type,
      'ingredients': ingredients ?? [],
      'imagePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _mealsCollection.add(mealData);
  }

  // Get meals for a specific date
  Stream<List<Map<String, dynamic>>> getMealsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _mealsCollection
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThan: endOfDay)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    });
  }

  // Update a meal
  Future<void> updateMeal(String mealId, Map<String, dynamic> updates) async {
    await _mealsCollection.doc(mealId).update(updates);
  }

  // Delete a meal
  Future<void> deleteMeal(String mealId) async {
    await _mealsCollection.doc(mealId).delete();
  }

  // Get meals by type (breakfast, lunch, dinner, snack)
  Stream<List<Map<String, dynamic>>> getMealsByType(String type) {
    return _mealsCollection
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    });
  }

  // Get total calories for a specific date
  Future<int> getTotalCaloriesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _mealsCollection
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThan: endOfDay)
        .get();

    int totalCalories = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalCalories += (data['calories'] as int? ?? 0);
    }
    return totalCalories;
  }
} 