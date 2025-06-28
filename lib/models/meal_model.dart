import 'food_model.dart';

class MealModel {
  final String id;
  final String name;
  final List<FoodModel> items;
  final double totalCalories;
  final String time;
  final DateTime date;

  MealModel({
    required this.id,
    required this.name,
    required this.items,
    required this.totalCalories,
    required this.time,
    required this.date,
  });

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => FoodModel.fromMap(item))
          .toList() ?? [],
      totalCalories: (map['totalCalories'] ?? 0).toDouble(),
      time: map['time'] ?? '',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'totalCalories': totalCalories,
      'time': time,
      'date': date.toIso8601String(),
    };
  }

  MealModel copyWith({
    String? id,
    String? name,
    List<FoodModel>? items,
    double? totalCalories,
    String? time,
    DateTime? date,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
      time: time ?? this.time,
      date: date ?? this.date,
    );
  }
} 