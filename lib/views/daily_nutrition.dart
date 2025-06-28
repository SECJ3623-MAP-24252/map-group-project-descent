import 'package:flutter/material.dart';
import 'food_entry_detail.dart';

class DailyNutritionPage extends StatefulWidget {
  const DailyNutritionPage({Key? key}) : super(key: key);

  @override
  State<DailyNutritionPage> createState() => _DailyNutritionPageState();
}

class _DailyNutritionPageState extends State<DailyNutritionPage> {
  int selectedDayIndex = 2;
  final List<String> days = ['Aug 10', 'Aug 11', 'Aug 12', 'Aug 13', 'Aug 14'];
  final List<Map<String, dynamic>> entries = [
    {
      'name': 'Salad with eggs',
      'kcal': 294,
      'protein': 12,
      'fats': 22,
      'carbs': 42,
      'icon': Icons.egg_alt,
      'color': Color(0xFFFFF3E0),
      'imageUrl': 'https://plantbasedwithamy.com/wp-content/uploads/2022/04/looking-for-salad-recipes-with-hardboiled-eggs-how-about-an-easy-chopped-salad-recipe-this-will-become-one-of-your-fave-vegetarian-recipes-lunch-ideas-ad-eggenthusiast-eggnutrition-eggs-lunch-salad-choppedsalad-vegetarian-dinner-plantbased-1.jpg.webp',
    },
    {
      'name': 'Avocado Dish',
      'kcal': 294,
      'protein': 13,
      'fats': 32,
      'carbs': 12,
      'icon': Icons.emoji_food_beverage,
      'color': Color(0xFFE8F5E9),
      'imageUrl': 'https://gran.luchito.com/wp-content/uploads/2018/09/Guacamole_2-1.jpeg',
    },
    {
      'name': 'Pancakes',
      'kcal': 294,
      'protein': 12,
      'fats': 22,
      'carbs': 42,
      'icon': Icons.breakfast_dining,
      'color': Color(0xFFFFEBEE),
      'imageUrl': 'https://www.allrecipes.com/thmb/WqWggh6NwG-r8PoeA3OfW908FUY=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/21014-Good-old-Fashioned-Pancakes-mfs_001-1fa26bcdedc345f182537d95b6cf92d8.jpg',
    },
    {
      'name': 'Slice of Pineapple',
      'kcal': 294,
      'protein': 12,
      'fats': 22,
      'carbs': 42,
      'icon': Icons.local_pizza,
      'color': Color(0xFFE1F5FE),
      'imageUrl': 'https://assets.clevelandclinic.org/transform/LargeFeatureImage/8e5f4b64-5210-4bb7-aaeb-402affc17d3d/BenefitsOfPineapple-955346588-770x533-1_jpgs',
    },
  ];

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
        title: const Text('Daily Nutrition', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
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
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Color(0xFFFF7A4D) : Color(0xFFF5F5F5),
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: entry['color'],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodEntryDetailPage(entry: entry),
                        ),
                      );
                    },
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_horiz, color: Colors.black),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    // TODO: Navigate to edit page
                                  } else if (value == 'delete') {
                                    // TODO: Delete entry
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Text('${entry['kcal']} kcal - 100g', style: TextStyle(color: Colors.black54, fontSize: 13)),
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
        Text(label, style: TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }
} 