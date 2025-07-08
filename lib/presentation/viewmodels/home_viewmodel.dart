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
    if (userId == null) {
      print('HomeViewModel: No userId provided, clearing meals');
      clearMeals();
      return;
    }
    
    print('HomeViewModel: Loading meals for userId: $userId');
    print('HomeViewModel: Selected date: $_selectedDate');
    
    setState(ViewState.busy);
    
    try {
      // First, let's try to get ALL meals for this user to debug
      final allMeals = await _mealRepository.getAllMealsForUser(userId);
      print('HomeViewModel: Found ${allMeals.length} total meals for user');
      
      for (final meal in allMeals) {
        print('HomeViewModel: Meal - ${meal.name}, Date: ${meal.timestamp}, ID: ${meal.id}');
      }
      
      // Now get meals for the specific date
      _todaysMeals = await _mealRepository.getMealsForDate(userId, _selectedDate);
      print('HomeViewModel: Found ${_todaysMeals.length} meals for selected date');
      
      await _calculateNutritionSummary(userId);
      setState(ViewState.idle);
    } catch (e) {
      print('HomeViewModel: Error loading meals: $e');
      setError(e.toString());
    }
  }

  // Add this method to refresh meals without showing loading state
  Future<void> refreshTodaysMeals(String userId) async {
    try {
      print('HomeViewModel: Refreshing meals for userId: $userId');
      
      // Get all meals first for debugging
      final allMeals = await _mealRepository.getAllMealsForUser(userId);
      print('HomeViewModel: Refresh - Found ${allMeals.length} total meals');
      
      _todaysMeals = await _mealRepository.getMealsForDate(userId, _selectedDate);
      print('HomeViewModel: Refresh - Found ${_todaysMeals.length} meals for today');
      
      await _calculateNutritionSummary(userId);
      notifyListeners(); // Just notify listeners without changing state
    } catch (e) {
      print('HomeViewModel: Error refreshing meals: $e');
    }
  }

  Future<void> _calculateNutritionSummary(String userId) async {
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      print('HomeViewModel: Calculating nutrition from $startOfDay to $endOfDay');
      
      _todaysNutrition = await _mealRepository.getNutritionSummary(
        userId, 
        startOfDay, 
        endOfDay
      );
      
      print('HomeViewModel: Nutrition summary: $_todaysNutrition');
    } catch (e) {
      print('HomeViewModel: Error calculating nutrition summary: $e');
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

  // New method to clear meals, useful on logout
  void clearMeals() {
    _todaysMeals = [];
    _todaysNutrition = {
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
    };
    notifyListeners();
  }
}
