import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../viewmodels/nutrition_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../../data/models/meal_model.dart';

import '../../../data/services/api_config.dart';

class EditFoodPage extends StatefulWidget {
  final MealModel meal;

  const EditFoodPage({
    super.key,
    required this.meal,
  });

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _descriptionController;
  late MealModel _meal;
  final List<_Ingredient> _ingredients = [];
  bool _isCalculating = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
    _foodNameController = TextEditingController(text: _meal.name);
    _caloriesController =
        TextEditingController(text: _meal.calories.round().toString());
    _proteinController =
        TextEditingController(text: _meal.protein.round().toString());
    _carbsController =
        TextEditingController(text: _meal.carbs.round().toString());
    _fatController = TextEditingController(text: _meal.fat.round().toString());
    _descriptionController = TextEditingController(text: _meal.description ?? '');

    if (_meal.ingredients != null) {
      for (var ingredient in _meal.ingredients!) {
        final weightMatch =
            RegExp(r'^(\d+(?:\.\d+)?)\s*(\w+)').firstMatch(ingredient.weight);
        if (weightMatch != null) {
          _ingredients.add(
            _Ingredient(
              ingredient.name,
              weightMatch.group(1)!,
              weightMatch.group(2)!,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _editIngredient(int index) async {
    final result = await showDialog<_Ingredient>(
      context: context,
      builder: (context) => _IngredientDialog(ingredient: _ingredients[index]),
    );
    if (result != null) {
      setState(() {
        _ingredients[index] = result;
        _hasChanges = true;
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
        _ingredients.add(result);
        _hasChanges = true;
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _updateMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    if (_hasChanges) {
      await _recalculateNutrition();
    }

    final updatedMeal = _meal.copyWith(
      name: _foodNameController.text,
      description: _descriptionController.text,
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      ingredients: _ingredients
          .map(
            (e) => IngredientModel(
              name: e.name,
              weight: '${e.amount}${e.unit}',
              calories: 0,
            ),
          )
          .toList(),
    );

    final nutritionViewModel = context.read<NutritionViewModel>();
    await nutritionViewModel.updateMeal(updatedMeal);

    if (mounted) {
      final homeViewModel = context.read<HomeViewModel>();
      final authViewModel = context.read<AuthViewModel>();
      await homeViewModel.refreshTodaysMeals(authViewModel.currentUser!.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }

    setState(() {
      _isCalculating = false;
    });
  }

  Future<void> _recalculateNutrition() async {
    final ingredientsString =
        _ingredients.map((e) => '${e.amount}${e.unit} ${e.name}').join(', ');
    final nutrition = await _getNutritionFromAPI(ingredientsString);
    if (nutrition != null) {
      setState(() {
        _caloriesController.text = nutrition['calories'].toString();
        _proteinController.text = nutrition['protein'].toString();
        _carbsController.text = nutrition['carbs'].toString();
        _fatController.text = nutrition['fat'].toString();
      });
    }
  }

  Future<Map<String, int>?> _getNutritionFromAPI(
      String ingredientsString) async {
    final apiKey = APIConfig.getApiKey('calorieninjas');
    if (apiKey == null) return null;

    final response = await http.get(
      Uri.parse(
          'https://api.calorieninjas.com/v1/nutrition?query=$ingredientsString'),
      headers: {'X-Api-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var item in data['items']) {
        totalCalories += item['calories'];
        totalProtein += item['protein_g'];
        totalCarbs += item['carbohydrates_total_g'];
        totalFat += item['fat_total_g'];
      }

      return {
        'calories': totalCalories.round(),
        'protein': totalProtein.round(),
        'carbs': totalCarbs.round(),
        'fat': totalFat.round(),
      };
    }
    return null;
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
        title: const Text('Edit Food', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _foodNameController,
                      decoration: const InputDecoration(labelText: 'Food Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a food name' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration:
                                const InputDecoration(labelText: 'Calories'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            decoration:
                                const InputDecoration(labelText: 'Protein (g)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            decoration:
                                const InputDecoration(labelText: 'Carbs (g)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            decoration:
                                const InputDecoration(labelText: 'Fat (g)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Ingredients',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return ListTile(
                          title: Text(ingredient.name),
                          subtitle:
                              Text('${ingredient.amount} ${ingredient.unit}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editIngredient(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Ingredient'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isCalculating ? null : _updateMeal,
                      child: _isCalculating
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Update Meal'),
                    ),
                  ],
                ),
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
  String unit = 'g';
  final List<String> units = ['g', 'ml', 'piece', 'cup', 'tbsp', 'tsp'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    amountController =
        TextEditingController(text: widget.ingredient?.amount ?? '');
    unit = widget.ingredient?.unit ?? 'g';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
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
                units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
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
