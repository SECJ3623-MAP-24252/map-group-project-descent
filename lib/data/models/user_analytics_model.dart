import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the user's analytics data.
class UserAnalyticsModel {
  /// The unique identifier of the user.
  final String userId;
  /// The total number of calories consumed by the user.
  final double totalCalories;
  /// The total amount of protein consumed by the user.
  final double totalProtein;
  /// The total amount of carbohydrates consumed by the user.
  final double totalCarbs;
  /// The total amount of fat consumed by the user.
  final double totalFat;
  /// The total number of meals consumed by the user.
  final int totalMeals;
  /// The date and time the analytics data was last updated.
  final DateTime lastUpdated;

  /// Creates a new instance of the [UserAnalyticsModel] class.
  UserAnalyticsModel({
    required this.userId,
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.totalMeals = 0,
    required this.lastUpdated,
  });

  /// Creates a new instance of the [UserAnalyticsModel] class from a Firestore document.
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

  /// Converts this [UserAnalyticsModel] to a [Map] for Firestore.
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

  /// Creates a copy of this [UserAnalyticsModel] with the given fields updated.
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