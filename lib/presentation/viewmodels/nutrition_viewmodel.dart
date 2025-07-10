
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
  DateTime get selectedDate => _weekDays.isNotEmpty ? _weekDays[_selectedDayIndex] : DateTime.now();

  NutritionViewModel(this._mealRepository) {
    _initializeWeekDays();
  }

  void _initializeWeekDays() {
    final now = DateTime.now();
    _weekDays = List.generate(7, (index) => now.subtract(Duration(days: 3 - index)));
  }

  Future<void> loadMealsForSelectedDay(String userId) async {
    setState(ViewState.busy);
    
    try {
      print('Loading meals for selected day: ${selectedDate.toString()}');
      _meals = await _mealRepository.getMealsForDate(userId, selectedDate);
      print('Loaded ${_meals.length} meals for selected day');
      setState(ViewState.idle);
    } catch (e) {
      print('Error loading meals for selected day: $e');
      setError(e.toString());
    }
  }

  Future<void> loadDailyMeals(DateTime date) async {
    setState(ViewState.busy);
    
    try {
      // For now, use a default user ID
      const userId = 'default_user'; // This should ideally come from AuthViewModel
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
      print('Deleting meal with ID: $mealId');
      
      if (mealId.isEmpty) {
        throw Exception('Meal ID is empty');
      }
      
      await _mealRepository.deleteMeal(mealId);
      print('Meal deleted successfully from database');
      
      // Refresh the appropriate list based on context
      if (userId != null) {
        await loadMealsForSelectedDay(userId);
      } else {
        // Fallback: reload current selected day meals
        final currentUserId = userId ?? 'default_user';
        await loadMealsForSelectedDay(currentUserId);
      }
      setState(ViewState.idle);
    } catch (e) {
      print('Error deleting meal: $e');
      setError(e.toString());
    }
  }

  Future<String> addMeal(MealModel meal) async {
    setState(ViewState.busy);
    
    try {
      print('Adding new meal: ${meal.name}');
      final mealId = await _mealRepository.createMeal(meal);
      print('Meal added successfully with ID: $mealId');
      setState(ViewState.idle);
      return mealId;
    } catch (e) {
      print('Error adding meal: $e');
      setError(e.toString());
      rethrow;
    }
  }

  Future<void> updateMeal(MealModel meal) async {
    setState(ViewState.busy);
    
    try {
      print('Updating meal: ${meal.id} - ${meal.name}');
      
      if (meal.id.isEmpty) {
        throw Exception('Cannot update meal: Meal ID is empty');
      }
      
      // Log meal details for debugging
      print('Meal details:');
      print('- ID: ${meal.id}');
      print('- Name: ${meal.name}');
      print('- Calories: ${meal.calories}');
      print('- Protein: ${meal.protein}');
      print('- Carbs: ${meal.carbs}');
      print('- Fat: ${meal.fat}');
      print('- Ingredients: ${meal.ingredients?.length ?? 0}');
      print('- Description: ${meal.description}');
      
      await _mealRepository.updateMeal(meal);
      print('Meal updated successfully in database');
      
      // Update the local meal in the list if it exists
      final mealIndex = _meals.indexWhere((m) => m.id == meal.id);
      if (mealIndex != -1) {
        _meals[mealIndex] = meal;
        print('Updated meal in local list at index $mealIndex');
      }
      
      setState(ViewState.idle);
    } catch (e) {
      print('Error updating meal in ViewModel: $e');
      setError(e.toString());
      rethrow;
    }
  }

  String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  // New method to clear meals, useful on logout
  void clearMeals() {
    _meals = [];
    _dailyMeals = [];
    notifyListeners();
  }
}
