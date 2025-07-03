import 'package:flutter/material.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/models/meal_model.dart';
import 'base_viewmodel.dart';

class NutritionViewModel extends BaseViewModel {
  final MealRepository _mealRepository;

  List<MealModel> _meals = [];
  List<MealModel> _dailyMeals = [];
  int _selectedDayIndex = 2; // Default to middle day
  List<DateTime> _weekDays = [];

  List<MealModel> get meals => _meals;
  List<MealModel> get dailyMeals => _dailyMeals;
  int get selectedDayIndex => _selectedDayIndex;
  List<DateTime> get weekDays => _weekDays;
  DateTime get selectedDate =>
      _weekDays.isNotEmpty ? _weekDays[_selectedDayIndex] : DateTime.now();

  NutritionViewModel(this._mealRepository) {
    _initializeWeekDays();
  }

  void _initializeWeekDays() {
    final now = DateTime.now();
    _weekDays = List.generate(
      7,
      (index) => now.subtract(Duration(days: 3 - index)),
    );
  }

  Future<void> loadMealsForSelectedDay(String userId) async {
    setState(ViewState.busy);

    try {
      _meals = await _mealRepository.getMealsForDate(userId, selectedDate);
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> loadDailyMeals(DateTime date) async {
    setState(ViewState.busy);

    try {
      // For now, use a default user ID
      const userId = 'default_user';
      _dailyMeals = await _mealRepository.getMealsForDate(userId, date);
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  void selectDay(int index, String userId) {
    _selectedDayIndex = index;
    notifyListeners();
    loadMealsForSelectedDay(userId);
  }

  Future<void> deleteMeal(String mealId, [String? userId]) async {
    setState(ViewState.busy);

    try {
      await _mealRepository.deleteMeal(mealId);
      // Refresh the appropriate list
      if (userId != null) {
        await loadMealsForSelectedDay(userId);
      } else {
        await loadDailyMeals(DateTime.now());
      }
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> addMeal(MealModel meal) async {
    setState(ViewState.busy);

    try {
      await _mealRepository.createMeal(meal);
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> updateMeal(MealModel meal) async {
    setState(ViewState.busy);

    try {
      await _mealRepository.updateMeal(meal);
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
