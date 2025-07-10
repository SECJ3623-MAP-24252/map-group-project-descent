import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../data/models/meal_model.dart';
import '../../viewmodels/scanner_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../nutrition/edit_food_page.dart';

class FoodScanResultsPage extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> nutritionData;

  const FoodScanResultsPage({
    super.key,
    required this.imageFile,
    required this.nutritionData,
  });

  @override
  State<FoodScanResultsPage> createState() => _FoodScanResultsPageState();
}

class _FoodScanResultsPageState extends State<FoodScanResultsPage> {
  late Map<String, dynamic> _nutritionData;
  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _nutritionData = Map.from(widget.nutritionData);

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

  void _saveToMealPlan() async {
    final scannerViewModel = context.read<ScannerViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    if (authViewModel.currentUser != null) {
      try {
        await scannerViewModel.saveMealFromScan(
          userId: authViewModel.currentUser!.uid,
          nutritionData: _nutritionData,
          mealType: _selectedMealType,
          imageFile: widget.imageFile,
        );

        await homeViewModel.refreshTodaysMeals(authViewModel.currentUser!.uid);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success!'),
              content: Text(
                  '${_nutritionData['food_name']} has been added to your $_selectedMealType.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving meal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editNutrition() async {
    final meal = MealModel(
      id: '',
      userId: '',
      name: _nutritionData['food_name'] ?? 'Scanned Meal',
      description: _nutritionData['description'],
      calories: (_nutritionData['nutrition']['calories'] as num).toDouble(),
      protein: (_nutritionData['nutrition']['protein'] as num).toDouble(),
      carbs: (_nutritionData['nutrition']['carbs'] as num).toDouble(),
      fat: (_nutritionData['nutrition']['fat'] as num).toDouble(),
      timestamp: DateTime.now(),
      imageUrl:
          'data:image/jpeg;base64,${base64Encode(widget.imageFile.readAsBytesSync())}',
      mealType: _selectedMealType,
      ingredients:
          (_nutritionData['ingredients'] as List<dynamic>).map((ingredient) {
        return IngredientModel.fromMap(ingredient);
      }).toList(),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFoodPage(meal: meal),
      ),
    );

    if (result == true) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = _nutritionData['nutrition'] as Map<String, dynamic>;
    final ingredients = _nutritionData['ingredients'] as List<dynamic>;
    final confidence = ((_nutritionData['confidence'] as double) * 100).round();
    final source = _nutritionData['source'] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Results',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _editNutrition,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(widget.imageFile,
                    width: 200, height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _nutritionData['food_name'],
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$confidence% confidence | Source: $source',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Add to Meal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              items: _mealTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Nutrition Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _NutritionCard(nutrition: nutrition),
            const SizedBox(height: 24),
            const Text('Detected Ingredients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...ingredients.map((ingredient) =>
                _IngredientTile(ingredient: ingredient)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveToMealPlan,
              child: const Text('Add to Meal Plan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Map<String, dynamic> nutrition;
  const _NutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutritionItem(
                    label: 'Calories',
                    value: '${nutrition['calories']}',
                    unit: 'kcal'),
                _NutritionItem(
                    label: 'Protein',
                    value: '${nutrition['protein']}',
                    unit: 'g'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutritionItem(
                    label: 'Carbs', value: '${nutrition['carbs']}', unit: 'g'),
                _NutritionItem(
                    label: 'Fat', value: '${nutrition['fat']}', unit: 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _NutritionItem(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text('$value $unit',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Map<String, dynamic> ingredient;
  const _IngredientTile({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(ingredient['name'] ?? 'Unknown Ingredient'),
      subtitle: Text(
          '${ingredient['calories']} kcal, ${ingredient['serving_size_g']}g'),
    );
  }
}
