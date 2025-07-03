import 'package:flutter/material.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/models/meal_model.dart';
import '../../core/constants/app_constants.dart';
import 'base_viewmodel.dart';

class HomeViewModel extends BaseViewModel {
  final MealRepository _mealRepository;

  List<MealModel> _todaysMeals = [];
  Map<String, double> _todaysNutrition = {};
  DateTime _selectedDate = DateTime.now();

  List<MealModel> get todaysMeals => _todaysMeals;
  Map<String, double> get todaysNutrition => _todaysNutrition;
  DateTime get selectedDate => _selectedDate;

  int get totalCalories => _todaysNutrition['calories']?.round() ?? 0;
  double get proteinGrams => _todaysNutrition['protein'] ?? 0;
  double get carbsGrams => _todaysNutrition['carbs'] ?? 0;
  double get fatGrams => _todaysNutrition['fat'] ?? 0;

  HomeViewModel(this._mealRepository);

  Future<void> loadTodaysMeals([String? userId]) async {
    setState(ViewState.busy);

    try {
      // For now, use a default user ID if none provided
      final uid = userId ?? 'default_user';
      _todaysMeals = await _mealRepository.getMealsForDate(uid, _selectedDate);
      await _calculateNutritionSummary(uid);
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> _calculateNutritionSummary(String userId) async {
    try {
      _todaysNutrition = await _mealRepository.getNutritionSummary(
        userId,
        _selectedDate,
        _selectedDate.add(const Duration(days: 1)),
      );
    } catch (e) {
      print('Error calculating nutrition summary: $e');
    }
  }

  Future<void> deleteMeal(String mealId, String userId) async {
    setState(ViewState.busy);

    try {
      await _mealRepository.deleteMeal(mealId);
      await loadTodaysMeals(userId); // Refresh the list
    } catch (e) {
      setError(e.toString());
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  double getCalorieProgress() {
    return totalCalories / AppConstants.dailyCalorieGoal;
  }

  List<Map<String, dynamic>> getWeekDays() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 3 - index));
      return {
        'day': _getDayName(date.weekday),
        'date': date.day.toString(),
        'fullDate': date,
      };
    });
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
