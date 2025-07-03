import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../viewmodels/nutrition_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../../data/models/meal_model.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/repositories/ai_food_repository.dart';
import '../../../data/services/api_config.dart';

class EditFoodPage extends StatefulWidget {
  final MealModel? meal; // For existing meals
  final Map<String, dynamic>? initialScanData; // For scanned, unsaved meals

  const EditFoodPage({Key? key, this.meal, this.initialScanData})
    : assert(
        meal != null || initialScanData != null,
        'Either meal or initialScanData must be provided',
      ),
      super(key: key);

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  List<_Ingredient> ingredients = [];
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController
  _descriptionController; // New controller for description
  late MealModel
  _meal; // This will hold the current state of the meal being edited
  bool _isCalculating = false;
  bool _isLoading = false;
  bool _hasChanges = false; // Track if ingredients or description have changed

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _descriptionController =
        TextEditingController(); // Initialize new controller

    if (widget.initialScanData != null) {
      print('Initializing EditFoodPage with scanned data.');
      _meal = _createMealModelFromScanData(widget.initialScanData!);
      _populateFields();
      _hasChanges =
          true; // Mark as changed to trigger recalculation on save if needed
    } else if (widget.meal != null) {
      print('Initializing EditFoodPage with existing meal data.');
      _meal = widget.meal!;
      _loadMealData(); // Load fresh data for existing meal
    } else {
      // This case should ideally not be reached due to the assert, but as a fallback
      print('Error: Neither meal nor initialScanData provided. Using default.');
      _meal = MealModel(
        id: '',
        userId: '',
        name: 'New Meal',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        timestamp: DateTime.now(),
        mealType: 'Snack',
      );
      _populateFields();
    }
  }

  // Helper to create a temporary MealModel from scan data
  MealModel _createMealModelFromScanData(Map<String, dynamic> scanData) {
    final nutrition = scanData['nutrition'] as Map<String, dynamic>;
    final ingredientsData = scanData['ingredients'] as List<dynamic>;

    final List<IngredientModel> ingredientModels =
        ingredientsData.map((ing) {
          return IngredientModel.fromMap(ing as Map<String, dynamic>);
        }).toList();

    return MealModel(
      id: '', // No ID yet, as it's not saved to DB
      userId: '', // Will be set on save
      name: scanData['food_name'] ?? 'Unknown Meal',
      description: scanData['description'] ?? 'No description available.',
      calories: (nutrition['calories'] ?? 0).toDouble(),
      protein: (nutrition['protein'] ?? 0).toDouble(),
      carbs: (nutrition['carbs'] ?? 0).toDouble(),
      fat: (nutrition['fat'] ?? 0).toDouble(),
      timestamp: DateTime.now(),
      imageUrl: scanData['imageUrl'], // If image is passed
      mealType:
          scanData['mealType'] ?? 'Snack', // Default or passed from scan page
      ingredients: ingredientModels,
      scanSource: scanData['source'] ?? 'ai_scan',
    );
  }

  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load fresh meal data from database
      final mealRepository = getIt<MealRepository>();
      final freshMeal = await mealRepository.getMealById(_meal.id);

      if (freshMeal != null) {
        _meal = freshMeal;
        print('Loaded fresh meal data: ${_meal.id} - ${_meal.name}');
      } else {
        print(
          'Could not load fresh meal data, using existing meal from arguments',
        );
      }

      _populateFields();
    } catch (e) {
      print('Error loading meal data: $e');
      _populateFields(); // Fallback to existing meal data
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields() {
    _foodNameController.text = _meal.name;
    _caloriesController.text = _meal.calories.round().toString();
    _proteinController.text = _meal.protein.round().toString();
    _carbsController.text = _meal.carbs.round().toString();
    _fatController.text = _meal.fat.round().toString();
    _descriptionController.text =
        _meal.description ?? ''; // Populate description

    // Clear existing ingredients
    ingredients.clear();

    // Load from stored ingredients (from scanned meals)
    if (_meal.ingredients != null && _meal.ingredients!.isNotEmpty) {
      print(
        'Loading ingredients from stored ingredients: ${_meal.ingredients!.length}',
      );
      for (final ingredient in _meal.ingredients!) {
        // Parse weight to get amount and unit
        final weightMatch = RegExp(
          r'^(\d+(?:\.\d+)?)\s*(\w+)$',
        ).firstMatch(ingredient.weight);
        if (weightMatch != null) {
          final amount = weightMatch.group(1)!;
          final unit = weightMatch.group(2)!;
          final ing = _Ingredient(ingredient.name, amount, unit);
          ingredients.add(ing);
        } else {
          // Fallback
          final ing = _Ingredient(ingredient.name, '1', 'piece');
          ingredients.add(ing);
        }
      }
    }
    // Fallback: Parse ingredients from description (for manually added meals)
    else if (_meal.description != null && _meal.description!.isNotEmpty) {
      print('Parsing description for ingredients: ${_meal.description}');

      final parts = _meal.description!.split(', ');
      for (final part in parts) {
        final trimmedPart = part.trim();
        if (trimmedPart.isNotEmpty) {
          // Try to parse "amount unit name" format
          final match = RegExp(
            r'^(\d+(?:\.\d+)?)\s*(\w+)\s+(.+)$',
          ).firstMatch(trimmedPart);
          if (match != null) {
            final amount = match.group(1)!;
            final unit = match.group(2)!;
            final name = match.group(3)!.trim();
            final ing = _Ingredient(name, amount, unit);
            ingredients.add(ing);
            print('Parsed ingredient: $name, $amount $unit');
          } else {
            // Fallback: treat the whole part as ingredient name
            final ing = _Ingredient(trimmedPart, '1', 'piece');
            ingredients.add(ing);
            print('Fallback ingredient: $trimmedPart');
          }
        }
      }
    }

    // If no ingredients found, create one from the meal name
    if (ingredients.isEmpty) {
      final ing = _Ingredient(_meal.name, '1', 'serving');
      ingredients.add(ing);
      print('Created default ingredient from meal name: ${_meal.name}');
    }

    print('Total ingredients loaded: ${ingredients.length}');
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _descriptionController.dispose(); // Dispose new controller
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
        ingredients.add(result);
        _hasChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingredient added. Click "Update Meal" to recalculate nutrition.',
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ingredient removed. Click "Update Meal" to recalculate nutrition.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateMeal() async {
    if (_foodNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    final nutritionViewModel = context.read<NutritionViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    try {
      setState(() {
        _isCalculating = true;
      });

      print('Starting meal update process...');
      print('Meal ID: ${_meal.id}');
      print('Original meal name: ${_meal.name}');
      print('New meal name: ${_foodNameController.text}');
      print('Number of ingredients: ${ingredients.length}');

      // If there are changes to ingredients, recalculate nutrition with ALL current ingredients
      // This will update _caloriesController, _proteinController, etc.
      if (_hasChanges && ingredients.isNotEmpty) {
        print(
          'Recalculating nutrition due to ingredient/description changes...',
        );
        await _recalculateNutritionFromAPI();
      }

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

      print('Creating updated meal object...');
      final updatedMeal = _meal.copyWith(
        name: _foodNameController.text,
        description:
            _descriptionController.text, // Use description from controller
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        ingredients: ingredientModels,
        // If it's a new meal from scan, set userId and scanSource
        userId: _meal.id.isEmpty ? userId : _meal.userId,
        scanSource:
            _meal.id.isEmpty
                ? (_meal.scanSource ?? 'manual')
                : _meal.scanSource,
        mealType:
            _meal.id.isEmpty ? (_meal.mealType ?? 'Snack') : _meal.mealType,
      );

      print('Updated meal details:');
      print('- ID: ${updatedMeal.id}');
      print('- Name: ${updatedMeal.name}');
      print('- Description: ${updatedMeal.description}');
      print('- Calories: ${updatedMeal.calories}');
      print('- Ingredients: ${updatedMeal.ingredients?.length ?? 0}');

      // If it's a new meal (from scan), add it. Otherwise, update.
      if (_meal.id.isEmpty) {
        print('Adding new meal to database...');
        final newMealId = await nutritionViewModel.addMeal(updatedMeal);
        _meal = updatedMeal.copyWith(
          id: newMealId,
        ); // Update local meal with new ID
        print('New meal added with ID: $newMealId');
      } else {
        print('Updating existing meal in database...');
        await nutritionViewModel.updateMeal(updatedMeal);
        print('Database update completed successfully');
      }

      // Update local meal reference
      _meal = updatedMeal;
      _hasChanges = false;

      // Refresh both home page and nutrition page meals
      print('Refreshing UI data...');
      await homeViewModel.refreshTodaysMeals(userId);
      await nutritionViewModel.loadMealsForSelectedDay(userId);
      print('UI refresh completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_foodNameController.text} updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Small delay to ensure user sees the success message
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate successful update
      }
    } catch (e) {
      print('Error updating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating meal: $e'),
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

  void _deleteMeal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Meal'),
            content: Text('Are you sure you want to delete "${_meal.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        print('Deleting meal: ${_meal.id} - ${_meal.name}');

        final nutritionViewModel = context.read<NutritionViewModel>();
        final authViewModel = context.read<AuthViewModel>();
        final homeViewModel = context.read<HomeViewModel>();
        final userId = authViewModel.currentUser?.uid ?? 'default_user';

        await nutritionViewModel.deleteMeal(_meal.id, userId);
        print('Meal deleted successfully from database');

        // Refresh both home page and nutrition page meals
        await homeViewModel.refreshTodaysMeals(userId);
        await nutritionViewModel.loadMealsForSelectedDay(userId);
        print('UI refreshed after deletion');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to daily nutrition page after deletion
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/nutrition', // Redirect to daily nutrition page
            (route) => false,
          );
        }
      } catch (e) {
        print('Error deleting meal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting meal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildMealImage() {
    if (_meal.imageUrl != null && _meal.imageUrl!.startsWith('data:image')) {
      try {
        final base64String = _meal.imageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        );
      } catch (e) {
        print('Error decoding meal image: $e');
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Loading...',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed:
                _meal.id.isNotEmpty
                    ? _deleteMeal
                    : null, // Only allow delete for saved meals
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Show meal image if available
            _buildMealImage(),

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
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              minLines: 1,
              onChanged:
                  (_) => setState(
                    () => _hasChanges = true,
                  ), // Mark changes if description is edited
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
                      suffixText: 'cal',
                    ),
                    readOnly: true, // Make read-only
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    readOnly: true, // Make read-only
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    readOnly: true, // Make read-only
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    readOnly: true, // Make read-only
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Nutrition value:',
                  style: TextStyle(color: Colors.black38),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_getTotalWeight()}g',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_caloriesController.text.isEmpty ? 0 : _caloriesController.text} Kcal',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isCalculating) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
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

            // Ingredients List with proper constraints
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight:
                    MediaQuery.of(context).size.height *
                    0.3, // Max 30% of screen height
              ),
              child:
                  ingredients.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No ingredients found.\nTap "Add Ingredient" to add some.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
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

            const SizedBox(height: 16),
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
                    onPressed: _isCalculating ? null : _updateMeal,
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
                            : const Text(
                              'Update Meal',
                              style: TextStyle(fontSize: 16),
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
            const SizedBox(height: 20), // Extra padding at bottom
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

  // Recalculate nutrition using ALL current ingredients
  Future<void> _recalculateNutritionFromAPI() async {
    if (ingredients.isEmpty) {
      setState(() {
        _caloriesController.text = '0';
        _proteinController.text = '0';
        _carbsController.text = '0';
        _fatController.text = '0';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ingredients to calculate nutrition.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Format ALL current ingredients for API call
      final ingredientsString = ingredients
          .map((ing) => '${ing.amount}${ing.unit} ${ing.name}')
          .join(', ');

      print('Recalculating nutrition for ALL ingredients: $ingredientsString');

      final nutritionData = await _getNutritionFromAPI(ingredientsString);

      if (nutritionData != null) {
        setState(() {
          _caloriesController.text = nutritionData['calories'].toString();
          _proteinController.text = nutritionData['protein'].toString();
          _carbsController.text = nutritionData['carbs'].toString();
          _fatController.text = nutritionData['fat'].toString();
        });

        print(
          'Nutrition recalculated: ${nutritionData['calories']} cal, ${nutritionData['protein']}g protein',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition values recalculated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not recalculate nutrition data from API.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error recalculating nutrition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recalculating nutrition: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _hasChanges = false; // Reset flag
      });
    }
  }

  Future<Map<String, dynamic>?> _getNutritionFromAPI(
    String ingredientsString,
  ) async {
    try {
      // Use CalorieNinjas API directly
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

      print('CalorieNinjas API response: ${response.statusCode}');

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
      } else {
        print('CalorieNinjas API error: ${response.body}');
      }
    } catch (e) {
      print('Error calling CalorieNinjas API: $e');
    }
    return null;
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
  final List<String> units = [
    'piece',
    'grams',
    'ml',
    'cup',
    'tablespoon',
    'serving',
  ]; // Added 'serving'

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
