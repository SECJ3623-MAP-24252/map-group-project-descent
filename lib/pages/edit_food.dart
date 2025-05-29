import 'package:flutter/material.dart';

class EditFoodPage extends StatefulWidget {
  const EditFoodPage({Key? key}) : super(key: key);

  @override
  State<EditFoodPage> createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  List<_Ingredient> ingredients = [
    _Ingredient('Avocado', '1', 'piece'),
    _Ingredient('Eggs', '2', 'piece'),
    _Ingredient('Spinach', '100', 'grams'),
    _Ingredient('Lime', '100', 'piece'),
    _Ingredient('Salad Dressing', '30', 'ml'),
  ];

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
      builder: (context) => _IngredientDialog(),
    );
    if (result != null) {
      setState(() {
        ingredients.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Food', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Salad Dish With Avocado and Eggs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Text('Nutrition value:', style: TextStyle(color: Colors.black38)),
                SizedBox(width: 12),
                Text('100g', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                SizedBox(width: 16),
                Text('457 Kcal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Meal Components:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Table header
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text('Ingredient', style: TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Amount', style: TextStyle(color: Colors.black54)),
                ),
                SizedBox(width: 40),
              ],
            ),
            Divider(),
            // Ingredient list
            Expanded(
              child: ListView.separated(
                itemCount: ingredients.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final ing = ingredients[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('- ${ing.name}'),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Text(ing.amount),
                            const SizedBox(width: 4),
                            Text(ing.unit, style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        onPressed: () => _editIngredient(index),
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
                  backgroundColor: Color(0xFFD6F36B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _addIngredient,
                child: const Text('Add Ingredient +', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF7A4D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {},
                    child: const Text('Save', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.white)),
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
  final List<String> units = ['piece', 'grams', 'ml'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    amountController = TextEditingController(text: widget.ingredient?.amount ?? '');
    unit = widget.ingredient?.unit ?? 'piece';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Ingredient Name'),
          ),
          TextField(
            controller: amountController,
            decoration: InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          DropdownButton<String>(
            value: unit,
            items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
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
            if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
              Navigator.pop(context, _Ingredient(nameController.text, amountController.text, unit));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({Key? key}) : super(key: key);

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  List<_Ingredient> ingredients = [];
  String foodName = '';

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
      builder: (context) => _IngredientDialog(),
    );
    if (result != null) {
      setState(() {
        ingredients.add(result);
      });
    }
  }

  int get totalWeight {
    int sum = 0;
    for (final ing in ingredients) {
      if ((ing.unit == 'grams' || ing.unit == 'ml') && int.tryParse(ing.amount) != null) {
        sum += int.parse(ing.amount);
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Food', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
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
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => foodName = val),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Nutrition value:', style: TextStyle(color: Colors.black38)),
                const SizedBox(width: 12),
                Text('${totalWeight}g', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                const Text('0 Kcal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Meal Components:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Table header
            Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text('Ingredient', style: TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Amount', style: TextStyle(color: Colors.black54)),
                ),
                SizedBox(width: 40),
              ],
            ),
            Divider(),
            // Ingredient list
            Expanded(
              child: ListView.separated(
                itemCount: ingredients.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final ing = ingredients[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('- ${ing.name}'),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Text(ing.amount),
                            const SizedBox(width: 4),
                            Text(ing.unit, style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        onPressed: () => _editIngredient(index),
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
                  backgroundColor: Color(0xFFD6F36B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _addIngredient,
                child: const Text('Add Ingredient +', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF7A4D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {},
                    child: const Text('Save', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.white)),
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
} 