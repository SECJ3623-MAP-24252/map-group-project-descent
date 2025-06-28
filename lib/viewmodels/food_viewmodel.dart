import 'dart:io';
import '../models/food_model.dart';
import '../models/meal_model.dart';
import '../services/ai_food_service.dart';
import '../services/local_food_database.dart';
import 'base_viewmodel.dart';

class FoodViewModel extends BaseViewModel {
  final AIFoodService _aiFoodService = AIFoodService();
  final LocalFoodDatabase _localDatabase = LocalFoodDatabase();
  
  List<MealModel> _todaysMeals = [];
  List<FoodModel> _recentFoods = [];
  double _totalCalories = 0;

  List<MealModel> get todaysMeals => _todaysMeals;
  List<FoodModel> get recentFoods => _recentFoods;
  double get totalCalories => _totalCalories;

  FoodViewModel() {
    _loadTodaysMeals();
  }

  Future<void> _loadTodaysMeals() async {
    try {
      setLoading(true);
      // In a real app, this would load from Firebase/local storage
      // For now, using sample data
      _todaysMeals = [
        MealModel(
          id: '1',
          name: 'Breakfast',
          items: [],
          totalCalories: 320,
          time: '8:30 AM',
          date: DateTime.now(),
        ),
        MealModel(
          id: '2',
          name: 'Lunch',
          items: [],
          totalCalories: 450,
          time: '12:30 PM',
          date: DateTime.now(),
        ),
      ];
      _calculateTotalCalories();
      notifyListeners();
    } catch (e) {
      setError('Failed to load meals');
    } finally {
      setLoading(false);
    }
  }

  Future<FoodModel?> analyzeFoodImage(File imageFile) async {
    try {
      setLoading(true);
      setError(null);

      final nutritionData = await AIFoodService.analyzeFoodImage(imageFile);
      
      if (nutritionData.isNotEmpty) {
        final food = FoodModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nutritionData['food_name'] ?? 'Unknown Food',
          mealType: _getCurrentMealType(),
          calories: (nutritionData['nutrition']?['calories'] ?? 0).toDouble(),
          nutrition: nutritionData['nutrition'] ?? {},
          ingredients: List<String>.from(nutritionData['ingredients'] ?? []),
          servingSize: nutritionData['serving_size'] ?? '1 serving',
          source: nutritionData['source'] ?? 'ai_scan',
          imagePath: imageFile.path,
          timestamp: DateTime.now(),
          confidence: nutritionData['confidence']?.toDouble(),
        );

        _addFoodToMeal(food);
        return food;
      }
      
      return null;
    } catch (e) {
      setError('Failed to analyze food image: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<List<FoodModel>> searchFoods(String query) async {
    try {
      setLoading(true);
      setError(null);

      final results = <FoodModel>[];
      final allFoods = LocalFoodDatabase.getAllFoods();
      
      for (final foodName in allFoods) {
        if (foodName.toLowerCase().contains(query.toLowerCase())) {
          final nutritionData = LocalFoodDatabase.searchFood(foodName);
          if (nutritionData != null) {
            final food = FoodModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: foodName,
              mealType: _getCurrentMealType(),
              calories: (nutritionData['calories'] ?? 0).toDouble(),
              nutrition: nutritionData,
              ingredients: [foodName],
              servingSize: nutritionData['serving_size'] ?? '100g',
              source: 'local_database',
              timestamp: DateTime.now(),
            );
            results.add(food);
          }
        }
      }
      
      return results;
    } catch (e) {
      setError('Failed to search foods');
      return [];
    } finally {
      setLoading(false);
    }
  }

  void addFoodToMeal(FoodModel food, String mealType) {
    try {
      final updatedFood = food.copyWith(mealType: mealType);
      _addFoodToMeal(updatedFood);
    } catch (e) {
      setError('Failed to add food to meal');
    }
  }

  void _addFoodToMeal(FoodModel food) {
    // Find the meal for the current time
    final mealType = food.mealType;
    final existingMealIndex = _todaysMeals.indexWhere((meal) => meal.name == mealType);
    
    if (existingMealIndex != -1) {
      // Update existing meal
      final existingMeal = _todaysMeals[existingMealIndex];
      final updatedItems = List<FoodModel>.from(existingMeal.items)..add(food);
      final updatedMeal = existingMeal.copyWith(
        items: updatedItems,
        totalCalories: existingMeal.totalCalories + food.calories,
      );
      _todaysMeals[existingMealIndex] = updatedMeal;
    } else {
      // Create new meal
      final newMeal = MealModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: mealType,
        items: [food],
        totalCalories: food.calories,
        time: _getCurrentTime(),
        date: DateTime.now(),
      );
      _todaysMeals.add(newMeal);
    }

    _calculateTotalCalories();
    _addToRecentFoods(food);
    notifyListeners();
  }

  void removeFoodFromMeal(String mealId, String foodId) {
    final mealIndex = _todaysMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex != -1) {
      final meal = _todaysMeals[mealIndex];
      final foodIndex = meal.items.indexWhere((food) => food.id == foodId);
      
      if (foodIndex != -1) {
        final removedFood = meal.items[foodIndex];
        final updatedItems = List<FoodModel>.from(meal.items)..removeAt(foodIndex);
        final updatedMeal = meal.copyWith(
          items: updatedItems,
          totalCalories: meal.totalCalories - removedFood.calories,
        );
        
        if (updatedItems.isEmpty) {
          _todaysMeals.removeAt(mealIndex);
        } else {
          _todaysMeals[mealIndex] = updatedMeal;
        }
        
        _calculateTotalCalories();
        notifyListeners();
      }
    }
  }

  void _calculateTotalCalories() {
    _totalCalories = _todaysMeals.fold(0.0, (sum, meal) => sum + meal.totalCalories);
  }

  void _addToRecentFoods(FoodModel food) {
    _recentFoods.insert(0, food);
    if (_recentFoods.length > 10) {
      _recentFoods = _recentFoods.take(10).toList();
    }
  }

  String _getCurrentMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 16) return 'Lunch';
    if (hour < 21) return 'Dinner';
    return 'Snack';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void clearTodaysMeals() {
    _todaysMeals.clear();
    _totalCalories = 0;
    notifyListeners();
  }
} 