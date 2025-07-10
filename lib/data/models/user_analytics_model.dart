import 'package:cloud_firestore/cloud_firestore.dart';

class UserAnalyticsModel {
  final String userId;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int totalMeals;
  final DateTime lastUpdated;

  UserAnalyticsModel({
    required this.userId,
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.totalMeals = 0,
    required this.lastUpdated,
  });

  factory UserAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserAnalyticsModel(
      userId: doc.id,
      totalCalories: (data['totalCalories'] ?? 0).toDouble(),
      totalProtein: (data['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (data['totalCarbs'] ?? 0).toDouble(),
      totalFat: (data['totalFat'] ?? 0).toDouble(),
      totalMeals: data['totalMeals'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalMeals': totalMeals,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  UserAnalyticsModel copyWith({
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    int? totalMeals,
    DateTime? lastUpdated,
  }) {
    return UserAnalyticsModel(
      userId: userId,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalMeals: totalMeals ?? this.totalMeals,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
