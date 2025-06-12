import 'package:flutter/material.dart';

class EditFoodPage extends StatefulWidget {
  final Map<String, dynamic>? foodData;

  const EditFoodPage({Key? key, this.foodData}) : super(key: key);

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  List<_Ingredient> ingredients = [];
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;

  @override
  void initState() {
    super.initState();

    if (widget.foodData != null) {
      // Editing existing food
      _foodNameController = TextEditingController(
        text: widget.foodData!['name'],
      );
      _caloriesController = TextEditingController(
        text: widget.foodData!['calories'].toString(),
      );

      // Convert items to ingredients
      final items = widget.foodData!['items'] as List<String>;
      ingredients =
          items.map((item) => _Ingredient(item, '100', 'grams')).toList();
    } else {
      // Creating new food
      _foodNameController = TextEditingController();
      _caloriesController = TextEditingController();
      ingredients = [
        _Ingredient('Avocado', '1', 'piece'),
        _Ingredient('Eggs', '2', 'piece'),
        _Ingredient('Spinach', '100', 'grams'),
        _Ingredient('Lime', '1', 'piece'),
        _Ingredient('Salad Dressing', '30', 'ml'),
      ];
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
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

  void _saveMeal() {
    if (_foodNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    // In a real app, you would save this to Firebase
    final mealData = {
      'name': _foodNameController.text,
      'items': ingredients.map((ing) => ing.name).toList(),
      'calories': int.tryParse(_caloriesController.text) ?? 0,
      'time': TimeOfDay.now().format(context),
      'ingredients':
          ingredients
              .map(
                (ing) => {
                  'name': ing.name,
                  'amount': ing.amount,
                  'unit': ing.unit,
                },
              )
              .toList(),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_foodNameController.text} saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, mealData);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodData != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Food' : 'Add Food',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {
              // Show more options
              showModalBottomSheet(
                context: context,
                builder:
                    (context) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Scan Food'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/scanner');
                            },
                          ),
                          if (isEditing)
                            ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: const Text(
                                'Delete Meal',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Food name input
            TextField(
              controller: _foodNameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 16),
            // Calories input
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Calories',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
                suffixText: 'cal',
              ),
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
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Meal Components:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Table header
            Row(
              children: const [
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
            // Ingredient list
            Expanded(
              child: ListView.separated(
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
                    onPressed: _saveMeal,
                    child: Text(
                      isEditing ? 'Update' : 'Save',
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
    int sum = 0;
    for (final ing in ingredients) {
      if ((ing.unit == 'grams' || ing.unit == 'ml') &&
          int.tryParse(ing.amount) != null) {
        sum += int.parse(ing.amount);
      }
    }
    return sum;
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

// Keep the AddFoodPage class the same but update the constructor
class AddFoodPage extends StatefulWidget {
  const AddFoodPage({Key? key}) : super(key: key);

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  @override
  Widget build(BuildContext context) {
    return const EditFoodPage(); // Reuse the same widget
  }
}
