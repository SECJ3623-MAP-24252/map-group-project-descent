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
    if (userId == null) return;
    
    setState(ViewState.busy);
    
    try {
      _todaysMeals = await _mealRepository.getMealsForDate(userId, _selectedDate);
      await _calculateNutritionSummary(userId);
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  // Add this method to refresh meals without showing loading state
  Future<void> refreshTodaysMeals(String userId) async {
    try {
      _todaysMeals = await _mealRepository.getMealsForDate(userId, _selectedDate);
      await _calculateNutritionSummary(userId);
      notifyListeners(); // Just notify listeners without changing state
    } catch (e) {
      print('Error refreshing meals: $e');
    }
  }

  Future<void> _calculateNutritionSummary(String userId) async {
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      _todaysNutrition = await _mealRepository.getNutritionSummary(
        userId, 
        startOfDay, 
        endOfDay
      );
    } catch (e) {
      print('Error calculating nutrition summary: $e');
      _todaysNutrition = {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
      };
    }
  }

  Future<void> deleteMeal(String mealId, String userId) async {
    setState(ViewState.busy);
    
    try {
      await _mealRepository.deleteMeal(mealId);
      await refreshTodaysMeals(userId); // Use refresh instead of full reload
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> selectDate(DateTime date, String userId) async {
    _selectedDate = date;
    notifyListeners();
    await loadTodaysMeals(userId);
  }

  double getCalorieProgress() {
    return (totalCalories / AppConstants.dailyCalorieGoal).clamp(0.0, 1.0);
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
