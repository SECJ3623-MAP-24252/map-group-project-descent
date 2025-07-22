import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/models/meal_model.dart';
import '../../core/constants/app_constants.dart';
import 'base_viewmodel.dart';

/// This class is a view model for the home screen.
class HomeViewModel extends BaseViewModel {
  final MealRepository _mealRepository;
  final UserRepository _userRepository;
  
  UserModel? _user;
  List<MealModel> _todaysMeals = [];
  Map<String, double> _todaysNutrition = {};
  DateTime _selectedDate = DateTime.now();
  
  /// The current user.
  UserModel? get user => _user;
  /// The list of meals for the selected date.
  List<MealModel> get todaysMeals => _todaysMeals;
  /// The nutrition summary for the selected date.
  Map<String, double> get todaysNutrition => _todaysNutrition;
  /// The currently selected date.
  DateTime get selectedDate => _selectedDate;
  
  /// The total calories for the selected date.
  int get totalCalories => _todaysNutrition['calories']?.round() ?? 0;
  /// The total protein for the selected date.
  double get proteinGrams => _todaysNutrition['protein'] ?? 0;
  /// The total carbs for the selected date.
  double get carbsGrams => _todaysNutrition['carbs'] ?? 0;
  /// The total fat for the selected date.
  double get fatGrams => _todaysNutrition['fat'] ?? 0;

  /// Creates a new instance of the [HomeViewModel] class.
  HomeViewModel(this._mealRepository, this._userRepository);

  /// Loads the initial data for the home screen.
  ///
  /// The [userId] is the unique identifier of the user.
  Future<void> loadInitialData(String userId) async {
    setState(ViewState.busy);
    await Future.wait([
      loadTodaysMeals(userId),
      loadUserData(userId),
    ]);
    setState(ViewState.idle);
  }

  /// Loads the user data.
  ///
  /// The [userId] is the unique identifier of the user.
  Future<void> loadUserData(String userId) async {
    try {
      _user = await _userRepository.getUserData(userId);
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Loads the meals for the selected date.
  ///
  /// The [userId] is the unique identifier of the user.
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

  /// Refreshes the meals for the selected date.
  ///
  /// The [userId] is the unique identifier of the user.
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

  /// Calculates the nutrition summary for the selected date.
  ///
  /// The [userId] is the unique identifier of the user.
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

  /// Deletes a meal.
  ///
  /// The [mealId] is the unique identifier of the meal to delete.
  /// The [userId] is the unique identifier of the user.
  Future<void> deleteMeal(String mealId, String userId) async {
    setState(ViewState.busy);
    
    try {
      await _mealRepository.deleteMeal(mealId);
      await refreshTodaysMeals(userId); // Use refresh instead of full reload
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Selects a date.
  ///
  /// The [date] is the date to select.
  /// The [userId] is the unique identifier of the user.
  Future<void> selectDate(DateTime date, String userId) async {
    _selectedDate = date;
    notifyListeners();
    await loadTodaysMeals(userId);
  }

  /// Gets the calorie progress.
  ///
  /// Returns the calorie progress as a value between 0.0 and 1.0.
  double getCalorieProgress() {
    final goal = _user?.calorieGoal ?? AppConstants.dailyCalorieGoal;
    if (goal == 0) return 0.0;
    return (totalCalories / goal).clamp(0.0, 1.0);
  }

  /// Gets the days of the week.
  ///
  /// Returns a list of maps, where each map represents a day of the week.
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

  /// Gets the name of the day of the week.
  ///
  /// The [weekday] is the day of the week, where 1 is Monday and 7 is Sunday.
  ///
  /// Returns the name of the day of the week.
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Clears the meals.
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