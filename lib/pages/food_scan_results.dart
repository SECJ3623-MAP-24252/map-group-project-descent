import 'package:flutter/material.dart';
import 'dart:io';
import 'edit_food.dart';

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

  @override
  void initState() {
    super.initState();
    _nutritionData = Map.from(widget.nutritionData);
  }

  void _saveToMealPlan() {
    // Here you would save the food item to Firebase
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success!'),
            content: Text(
              '${_nutritionData['food_name']} has been added to your meal plan.',
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
            ],
          ),
    );
  }

  void _editNutrition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNutritionPage(nutritionData: _nutritionData),
      ),
    );

    if (result != null) {
      setState(() {
        _nutritionData = result;
      });
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

            const SizedBox(height: 32),

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
                    child: const Text(
                      'Add to Meal Plan',
                      style: TextStyle(
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

// Keep the EditNutritionPage class from the previous implementation
class EditNutritionPage extends StatefulWidget {
  final Map<String, dynamic> nutritionData;

  const EditNutritionPage({Key? key, required this.nutritionData})
    : super(key: key);

  @override
  State<EditNutritionPage> createState() => _EditNutritionPageState();
}

class _EditNutritionPageState extends State<EditNutritionPage> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _servingSizeController;

  @override
  void initState() {
    super.initState();
    final nutrition = widget.nutritionData['nutrition'] as Map<String, dynamic>;

    _nameController = TextEditingController(
      text: widget.nutritionData['food_name'],
    );
    _caloriesController = TextEditingController(
      text: nutrition['calories'].toString(),
    );
    _proteinController = TextEditingController(
      text: nutrition['protein'].toString(),
    );
    _carbsController = TextEditingController(
      text: nutrition['carbs'].toString(),
    );
    _fatController = TextEditingController(text: nutrition['fat'].toString());
    _servingSizeController = TextEditingController(
      text: widget.nutritionData['serving_size'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedData = Map<String, dynamic>.from(widget.nutritionData);
    updatedData['food_name'] = _nameController.text;
    updatedData['serving_size'] = _servingSizeController.text;
    updatedData['nutrition'] = {
      'calories': int.tryParse(_caloriesController.text) ?? 0,
      'protein': double.tryParse(_proteinController.text) ?? 0.0,
      'carbs': double.tryParse(_carbsController.text) ?? 0.0,
      'fat': double.tryParse(_fatController.text) ?? 0.0,
      'fiber': updatedData['nutrition']['fiber'] ?? 0.0,
      'sugar': updatedData['nutrition']['sugar'] ?? 0.0,
      'sodium': updatedData['nutrition']['sodium'] ?? 0.0,
    };

    Navigator.pop(context, updatedData);
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
        title: const Text(
          'Edit Nutrition',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('Food Name', _nameController),
                    const SizedBox(height: 16),
                    _buildTextField('Serving Size', _servingSizeController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Calories',
                      _caloriesController,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Protein (g)',
                      _proteinController,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Carbs (g)',
                      _carbsController,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Fat (g)', _fatController, isNumber: true),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
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
                      'Cancel',
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
