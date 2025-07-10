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
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  List<_Ingredient> ingredients = [];
  late TextEditingController _foodNameController;
  late TextEditingController _descriptionController;
  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    _descriptionController = TextEditingController();

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
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final nutritionData = await _calculateNutritionFromIngredients();
      if (!mounted) return;

      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: You must be logged in to save a meal.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isCalculating = false);
        return;
      }
      final userId = authViewModel.currentUser!.uid;

      final ingredientModels = ingredients
          .map((ing) => IngredientModel(
                name: ing.name,
                weight: '${ing.amount}${ing.unit}',
                calories: 0,
              ))
          .toList();

      final meal = MealModel(
        id: '',
        userId: userId,
        name: _foodNameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        calories: (nutritionData['calories'] ?? 0).toDouble(),
        protein: (nutritionData['protein'] ?? 0).toDouble(),
        carbs: (nutritionData['carbs'] ?? 0).toDouble(),
        fat: (nutritionData['fat'] ?? 0).toDouble(),
        timestamp: DateTime.now(),
        mealType: _selectedMealType,
        ingredients: ingredientModels,
        scanSource: 'manual',
      );

      final nutritionViewModel = context.read<NutritionViewModel>();
      await nutritionViewModel.addMeal(meal);

      if (mounted) {
        final homeViewModel = context.read<HomeViewModel>();
        await homeViewModel.refreshTodaysMeals(userId);

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
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  Future<Map<String, int>> _calculateNutritionFromIngredients() async {
    if (ingredients.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    final ingredientsString =
        ingredients.map((ing) => '${ing.amount}${ing.unit} ${ing.name}').join(', ');
    final nutritionData = await _getNutritionFromAPI(ingredientsString);

    return nutritionData ?? _getApproximateNutrition();
  }

  Future<Map<String, int>?> _getNutritionFromAPI(
      String ingredientsString) async {
    final apiKey = APIConfig.getApiKey('calorieninjas');
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse('https://api.calorieninjas.com/v1/nutrition');
      final response = await http.get(
        uri.replace(queryParameters: {'query': ingredientsString}),
        headers: {'X-Api-Key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['items'] != null && data['items'] is List) {
          final items = data['items'] as List;
          double totalCalories = 0.0,
              totalProtein = 0.0,
              totalCarbs = 0.0,
              totalFat = 0.0;

          for (final item in items) {
            if (item is Map<String, dynamic>) {
              totalCalories += (item['calories'] ?? 0).toDouble();
              totalProtein += (item['protein_g'] ?? 0).toDouble();
              totalCarbs +=
                  (item['carbohydrates_total_g'] ?? 0).toDouble();
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
    } catch (e) {
      print('Error calling CalorieNinjas API: $e');
    }
    return null;
  }

  Map<String, int> _getApproximateNutrition() {
    double totalCalories = 0,
        totalProtein = 0,
        totalCarbs = 0,
        totalFat = 0;

    for (final ingredient in ingredients) {
      final amount = double.tryParse(ingredient.amount) ?? 0;
      final nutrition = _getApproximateNutritionForIngredient(
          ingredient.name, amount, ingredient.unit);
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
      String foodName, double amount, String unit) {
    const nutritionPer100g = <String, Map<String, double>>{
      'chicken': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      'rice': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'broccoli': {'calories': 34.0, 'protein': 2.8, 'carbs': 7.0, 'fat': 0.4},
      'apple': {'calories': 52.0, 'protein': 0.3, 'carbs': 14.0, 'fat': 0.2},
      'banana': {'calories': 89.0, 'protein': 1.1, 'carbs': 23.0, 'fat': 0.3},
      'egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
    };
    final key = foodName.toLowerCase();
    final baseNutrition = nutritionPer100g[key] ??
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
            TextField(
              controller: _foodNameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _mealTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Meal Components:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ingredients.isEmpty
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
                        return ListTile(
                          title: Text(ing.name),
                          subtitle: Text('${ing.amount} ${ing.unit}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editIngredient(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _addIngredient,
                child: const Text('Add Ingredient +'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isCalculating ? null : _saveMeal,
              child: _isCalculating
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Add to $_selectedMealType'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
  String unit = 'grams';
  final List<String> units = ['grams', 'piece', 'ml', 'cup', 'tablespoon'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    amountController =
        TextEditingController(text: widget.ingredient?.amount ?? '');
    unit = widget.ingredient?.unit ?? 'grams';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
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
            items: units
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
