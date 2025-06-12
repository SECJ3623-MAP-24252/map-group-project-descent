import 'package:flutter/material.dart';
import 'edit_food.dart'; // Ensure this import is correct based on your project structure

class DailyNutritionPage extends StatefulWidget {
  const DailyNutritionPage({Key? key}) : super(key: key);

  @override
  State<DailyNutritionPage> createState() => _DailyNutritionPageState();
}

class _DailyNutritionPageState extends State<DailyNutritionPage> {
  int selectedDayIndex = 2;
  final List<String> days = ['Aug 10', 'Aug 11', 'Aug 12', 'Aug 13', 'Aug 14'];
  late List<Map<String, dynamic>> entries = [
    {
      'name': 'Salad with eggs',
      'kcal': 294,
      'protein': 12,
      'fats': 22,
      'carbs': 42,
      'icon': Icons.egg_alt,
      'color': const Color(0xFFFFF3E0),
    },
    {
      'name': 'Avocado Dish',
      'kcal': 294,
      'protein': 13,
      'fats': 32,
      'carbs': 12,
      'icon': Icons.emoji_food_beverage,
      'color': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Pancakes',
      'kcal': 294,
      'protein': 12,
      'fats': 22,
      'carbs': 42,
      'icon': Icons.breakfast_dining,
      'color': const Color(0xFFFFEBEE),
    },
    {
      'name': 'Slice of Pineapple',
      'kcal': 294,
      'protein': 12,
      'fats': 22,
      'carbs': 42,
      'icon': Icons.local_pizza,
      'color': const Color(0xFFE1F5FE),
    },
  ];

  void _deleteEntry(int index) {
    setState(() {
      entries.removeAt(index);
    });
  }

  void _editEntry(int index) async {
    final editedFood = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFoodPage(), // Replace with actual edit logic or pass data
      ),
    );
    // Handle returned edited food if needed
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
        title: const Text('Daily Nutrition', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, i) {
                final selected = i == selectedDayIndex;
                return GestureDetector(
                  onTap: () => setState(() => selectedDayIndex = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFF7A4D) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        days[i],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                return Dismissible(
                  key: Key('$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.withOpacity(0.2),
                    child: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
                  ),
                  onDismissed: (direction) {
                    _deleteEntry(i);
                  },
                  child: GestureDetector(
                    onLongPress: () => _editEntry(i),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: entry['color'],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(entry['icon'], color: Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz, color: Colors.black),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editEntry(i);
                                    } else if (value == 'delete') {
                                      _deleteEntry(i);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                Text('${entry['kcal']} kcal - 100g',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _NutritionStat(value: entry['protein'], label: 'Protein', color: Colors.green),
                                _NutritionStat(value: entry['fats'], label: 'Fats', color: Colors.red),
                                _NutritionStat(value: entry['carbs'], label: 'Carbs', color: Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _NutritionStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 2),
        Text('g', style: TextStyle(color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }
}