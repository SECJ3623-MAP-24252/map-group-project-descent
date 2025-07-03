import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/nutrition_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DailyNutritionPage extends StatefulWidget {
  const DailyNutritionPage({Key? key}) : super(key: key);

  @override
  State<DailyNutritionPage> createState() => _DailyNutritionPageState();
}

class _DailyNutritionPageState extends State<DailyNutritionPage> {
  int selectedDayIndex = 2;
  final List<String> days = ['Aug 10', 'Aug 11', 'Aug 12', 'Aug 13', 'Aug 14'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionViewModel>().loadDailyMeals(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NutritionViewModel, AuthViewModel>(
      builder: (context, nutritionViewModel, authViewModel, child) {
        final meals = nutritionViewModel.dailyMeals;

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
              'Daily Nutrition',
              style: TextStyle(color: Colors.black),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () {
                  nutritionViewModel.loadDailyMeals(DateTime.now());
                },
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? const Color(0xFFFF7A4D)
                                  : const Color(0xFFF5F5F5),
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
                  itemCount: meals.length,
                  itemBuilder: (context, i) {
                    final meal = meals[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: _getMealColor(i),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    _getMealIcon(meal.mealType),
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    meal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_horiz,
                                    color: Colors.black,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.pushNamed(
                                        context,
                                        '/edit-food',
                                        arguments: meal,
                                      );
                                    } else if (value == 'delete') {
                                      nutritionViewModel.deleteMeal(meal.id);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${meal.calories.toInt()} kcal - 100g',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _NutritionStat(
                                  value: meal.protein.toInt(),
                                  label: 'Protein',
                                  color: Colors.green,
                                ),
                                _NutritionStat(
                                  value: meal.fat.toInt(),
                                  label: 'Fats',
                                  color: Colors.red,
                                ),
                                _NutritionStat(
                                  value: meal.carbs.toInt(),
                                  label: 'Carbs',
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getMealColor(int index) {
    final colors = [
      const Color(0xFFFFF3E0),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFEBEE),
      const Color(0xFFE1F5FE),
    ];
    return colors[index % colors.length];
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.emoji_food_beverage;
    }
  }
}

class _NutritionStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _NutritionStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$value',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 2),
        Text('g', style: TextStyle(color: color)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }
}
