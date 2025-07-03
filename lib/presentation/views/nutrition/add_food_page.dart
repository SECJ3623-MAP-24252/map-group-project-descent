import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../viewmodels/nutrition_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../../data/models/meal_model.dart';
import '../../../data/services/api_config.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({Key? key}) : super(key: key);

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  List<_Ingredient> ingredients = [];
  late TextEditingController _foodNameController;
  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();

    // Auto-select meal type based on time
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = 'Breakfast';
    } else if (hour < 16) {
      _selectedMealType = 'Lunch';
    } else if (hour < 21) {
      _selectedMealType = 'Dinner';
    } else {
      _selectedMealType = 'Snack';
    }

    ingredients = [];
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  void _editIngredient(int index) async {
    final result = await showDialog<_Ingredient>(
      context: context,
      builder: (context) => _IngredientDialog(ingredient: ingredients[index]),
    );
    if (result != null) {
      setState(() {
        ingredients[index] = result;
      });
    }
  }

  void _addIngredient() async {
    final result = await showDialog<_Ingredient>(
      context: context,
      builder: (context) => const _IngredientDialog(),
    );
    if (result != null) {
      setState(() {
        ingredients.add(result);
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
    });
  }

  void _saveMeal() async {
    if (_foodNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    final nutritionViewModel = context.read<NutritionViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    try {
      setState(() {
        _isCalculating = true;
      });

      // Calculate nutrition from ingredients using API
      final nutritionData = await _calculateNutritionFromIngredients();

      final userId = authViewModel.currentUser?.uid ?? 'default_user';

      // Convert ingredients to IngredientModel list
      final ingredientModels =
          ingredients.map((ing) {
            return IngredientModel(
              name: ing.name,
              weight: '${ing.amount}${ing.unit}',
              calories: 0, // Could calculate this if needed
            );
          }).toList();

      final meal = MealModel(
        id: '', // Empty for new meal
        userId: userId,
        name: _foodNameController.text,
        description: ingredients
            .map((ing) => '${ing.amount} ${ing.unit} ${ing.name}')
            .join(', '),
        calories: (nutritionData['calories'] ?? 0).toDouble(),
        protein: (nutritionData['protein'] ?? 0).toDouble(),
        carbs: (nutritionData['carbs'] ?? 0).toDouble(),
        fat: (nutritionData['fat'] ?? 0).toDouble(),
        timestamp: DateTime.now(),
        mealType: _selectedMealType,
        ingredients: ingredientModels,
        scanSource: 'manual',
      );

      await nutritionViewModel.addMeal(meal);

      // Refresh home page meals immediately
      await homeViewModel.refreshTodaysMeals(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_foodNameController.text} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<Map<String, int>> _calculateNutritionFromIngredients() async {
    if (ingredients.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    try {
      // Format ingredients for API call
      final ingredientsString = ingredients
          .map((ing) => '${ing.amount}${ing.unit} ${ing.name}')
          .join(', ');

      print('Calculating nutrition for ingredients: $ingredientsString');

      final nutritionData = await _getNutritionFromAPI(ingredientsString);

      if (nutritionData != null) {
        return nutritionData;
      } else {
        // Fallback to approximate calculation
        return _getApproximateNutrition();
      }
    } catch (e) {
      print('Error calculating nutrition: $e');
      // Fallback to approximate calculation
      return _getApproximateNutrition();
    }
  }

  Future<Map<String, int>?> _getNutritionFromAPI(
    String ingredientsString,
  ) async {
    try {
      final apiKey = APIConfig.getApiKey('calorieninjas');
      if (apiKey == null || apiKey.isEmpty) {
        print('CalorieNinjas API key not configured');
        return null;
      }

      final uri = Uri.parse('https://api.calorieninjas.com/v1/nutrition');

      final response = await http.get(
        uri.replace(queryParameters: {'query': ingredientsString}),
        headers: {'X-Api-Key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['items'] != null && data['items'] is List) {
          final items = data['items'] as List;

          if (items.isNotEmpty) {
            double totalCalories = 0.0;
            double totalProtein = 0.0;
            double totalCarbs = 0.0;
            double totalFat = 0.0;

            for (final item in items) {
              if (item is Map<String, dynamic>) {
                totalCalories += (item['calories'] ?? 0).toDouble();
                totalProtein += (item['protein_g'] ?? 0).toDouble();
                totalCarbs += (item['carbohydrates_total_g'] ?? 0).toDouble();
                totalFat += (item['fat_total_g'] ?? 0).toDouble();
              }
            }

            return {
              'calories': totalCalories.round(),
              'protein': totalProtein.round(),
              'carbs': totalCarbs.round(),
              'fat': totalFat.round(),
            };
          }
        }
      }
    } catch (e) {
      print('Error calling CalorieNinjas API: $e');
    }
    return null;
  }

  Map<String, int> _getApproximateNutrition() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final ingredient in ingredients) {
      final amount = double.tryParse(ingredient.amount) ?? 0;
      final nutrition = _getApproximateNutritionForIngredient(
        ingredient.name,
        amount,
        ingredient.unit,
      );

      totalCalories += (nutrition['calories'] as num).toDouble();
      totalProtein += (nutrition['protein'] as num).toDouble();
      totalCarbs += (nutrition['carbs'] as num).toDouble();
      totalFat += (nutrition['fat'] as num).toDouble();
    }

    return {
      'calories': totalCalories.round(),
      'protein': totalProtein.round(),
      'carbs': totalCarbs.round(),
      'fat': totalFat.round(),
    };
  }

  Map<String, double> _getApproximateNutritionForIngredient(
    String foodName,
    double amount,
    String unit,
  ) {
    final nutritionPer100g = <String, Map<String, double>>{
      'chicken': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      'rice': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'broccoli': {'calories': 34.0, 'protein': 2.8, 'carbs': 7.0, 'fat': 0.4},
      'apple': {'calories': 52.0, 'protein': 0.3, 'carbs': 14.0, 'fat': 0.2},
      'banana': {'calories': 89.0, 'protein': 1.1, 'carbs': 23.0, 'fat': 0.3},
      'egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
    };

    final key = foodName.toLowerCase();
    final baseNutrition =
        nutritionPer100g[key] ??
        {'calories': 50.0, 'protein': 2.0, 'carbs': 10.0, 'fat': 1.0};

    double grams = amount;
    if (unit == 'piece') grams = amount * 100;
    if (unit == 'cup') grams = amount * 200;
    if (unit == 'ml') grams = amount;

    final multiplier = grams / 100;

    return {
      'calories': baseNutrition['calories']! * multiplier,
      'protein': baseNutrition['protein']! * multiplier,
      'carbs': baseNutrition['carbs']! * multiplier,
      'fat': baseNutrition['fat']! * multiplier,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Food', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            TextField(
              controller: _foodNameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 16),

            // Meal Type Selection
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items:
                  _mealTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Nutrition info display (calculated automatically)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F36B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD6F36B).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrition Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Total weight:',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getTotalWeight()}g',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Calories and macros will be calculated automatically when you save the meal.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Meal Components:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ingredient',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                SizedBox(width: 80),
              ],
            ),
            const Divider(),
            Expanded(
              child:
                  ingredients.isEmpty
                      ? const Center(
                        child: Text(
                          'No ingredients added yet.\nTap "Add Ingredient" to start.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                      : ListView.separated(
                        itemCount: ingredients.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final ing = ingredients[index];
                          return Row(
                            children: [
                              Expanded(flex: 2, child: Text('• ${ing.name}')),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Text(ing.amount),
                                    const SizedBox(width: 4),
                                    Text(
                                      ing.unit,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editIngredient(index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
                          );
                        },
                      ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFD6F36B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _addIngredient,
                child: const Text(
                  'Add Ingredient +',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isCalculating ? null : _saveMeal,
                    child:
                        _isCalculating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'Add to $_selectedMealType',
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  int _getTotalWeight() {
    double totalWeight = 0.0;

    for (final ing in ingredients) {
      final amount = double.tryParse(ing.amount) ?? 0;

      // Convert different units to grams
      switch (ing.unit.toLowerCase()) {
        case 'grams':
        case 'g':
          totalWeight += amount;
          break;
        case 'ml':
        case 'milliliters':
          totalWeight += amount; // Assume 1ml = 1g for liquids
          break;
        case 'cup':
          totalWeight += amount * 240; // 1 cup ≈ 240g
          break;
        case 'tablespoon':
        case 'tbsp':
          totalWeight += amount * 15; // 1 tbsp ≈ 15g
          break;
        case 'teaspoon':
        case 'tsp':
          totalWeight += amount * 5; // 1 tsp ≈ 5g
          break;
        case 'piece':
        case 'pieces':
          totalWeight += amount * 100; // Assume 1 piece ≈ 100g
          break;
        case 'serving':
          totalWeight += amount * 150; // Assume 1 serving ≈ 150g
          break;
        default:
          totalWeight += amount * 50; // Default fallback
          break;
      }
    }

    return totalWeight.round();
  }
}

class _Ingredient {
  String name;
  String amount;
  String unit;
  _Ingredient(this.name, this.amount, this.unit);
}

class _IngredientDialog extends StatefulWidget {
  final _Ingredient? ingredient;
  const _IngredientDialog({this.ingredient});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  late TextEditingController nameController;
  late TextEditingController amountController;
  String unit = 'piece';
  final List<String> units = ['piece', 'grams', 'ml', 'cup', 'tablespoon'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    amountController = TextEditingController(
      text: widget.ingredient?.amount ?? '',
    );
    unit = widget.ingredient?.unit ?? 'piece';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Ingredient Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: unit,
            decoration: const InputDecoration(labelText: 'Unit'),
            items:
                units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
            onChanged: (val) => setState(() => unit = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty &&
                amountController.text.isNotEmpty) {
              Navigator.pop(
                context,
                _Ingredient(nameController.text, amountController.text, unit),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
