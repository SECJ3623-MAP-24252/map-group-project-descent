import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Add this import for base64Encode
import 'package:provider/provider.dart';
import '../../viewmodels/scanner_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../nutrition/edit_food_page.dart'; // Import the correct edit page

class FoodScanResultsPage extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> nutritionData;

  const FoodScanResultsPage({
    Key? key,
    required this.imageFile,
    required this.nutritionData,
  }) : super(key: key);

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

        // Refresh home page meals immediately
        await homeViewModel.refreshTodaysMeals(authViewModel.currentUser!.uid);

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Success!'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_nutritionData['food_name']} has been added to your $_selectedMealType.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to scanner
                        Navigator.pop(context); // Go back to home
                      },
                      child: const Text('OK'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushNamed(context, '/nutrition');
                      },
                      child: const Text('View Nutrition'),
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
    // Pass the current nutritionData (which includes Gemini's name, description, and CalorieNinjas' nutrition)
    // to EditFoodPage as initialScanData.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditFoodPage(
              initialScanData: {
                ..._nutritionData,
                'mealType': _selectedMealType, // Pass selected meal type
                'imageUrl':
                    'data:image/jpeg;base64,${base64Encode(widget.imageFile.readAsBytesSync())}', // Pass image as base64
              },
            ),
      ),
    );

    if (result != null && result is bool && result) {
      // If EditFoodPage indicates a successful update, refresh data and pop back to home
      final authViewModel = context.read<AuthViewModel>();
      final homeViewModel = context.read<HomeViewModel>();
      if (authViewModel.currentUser != null) {
        await homeViewModel.refreshTodaysMeals(authViewModel.currentUser!.uid);
      }
      if (mounted) {
        Navigator.pop(context); // Pop back to scanner
        Navigator.pop(context); // Pop back to home
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
        title: const Text(
          'Scan Results',
          style: TextStyle(color: Colors.black),
        ),
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
            // Food Image
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(widget.imageFile, fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Food Name and Confidence
            Center(
              child: Column(
                children: [
                  Text(
                    _nutritionData['food_name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              confidence > 80
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$confidence% confidence',
                          style: TextStyle(
                            color:
                                confidence > 80 ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          source == 'gemini_calorieninjas'
                              ? 'AI Powered'
                              : source == 'local_database'
                              ? 'Local DB'
                              : 'Default',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Meal Type Selection
            const Text(
              'Add to Meal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMealType,
                  isExpanded: true,
                  items:
                      _mealTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMealType = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nutrition Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F36B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${nutrition['calories']} Calories',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total weight: ${_nutritionData['serving_size']}',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NutritionItem(
                        label: 'Protein',
                        value: '${nutrition['protein']}g',
                        color: Colors.blue,
                      ),
                      _NutritionItem(
                        label: 'Carbs',
                        value: '${nutrition['carbs']}g',
                        color: Colors.orange,
                      ),
                      _NutritionItem(
                        label: 'Fat',
                        value: '${nutrition['fat']}g',
                        color: Colors.red,
                      ),
                    ],
                  ),
                  if (nutrition['fiber'] != null && nutrition['fiber'] > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NutritionItem(
                          label: 'Fiber',
                          value: '${nutrition['fiber']}g',
                          color: Colors.green,
                        ),
                        _NutritionItem(
                          label: 'Sugar',
                          value: '${nutrition['sugar']}g',
                          color: Colors.purple,
                        ),
                        if (nutrition['sodium'] != null &&
                            nutrition['sodium'] > 0)
                          _NutritionItem(
                            label: 'Sodium',
                            value: '${nutrition['sodium']}g',
                            color: Colors.grey,
                          )
                        else
                          const SizedBox(),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detected Ingredients
            const Text(
              'Detected Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ingredients.map((ingredient) {
              final name = ingredient['name'] ?? 'Unknown';
              final weight = ingredient['weight'] ?? '0g';
              final calories = ingredient['calories']?.toString() ?? '0';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$calories cal',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      weight,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveToMealPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Add to $_selectedMealType',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Scan Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
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
  final Color color;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}
