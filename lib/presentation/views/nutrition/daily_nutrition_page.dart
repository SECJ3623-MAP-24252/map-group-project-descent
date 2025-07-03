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
  int selectedDayIndex = 3; // Start with today (middle of the week)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final nutritionViewModel = context.read<NutritionViewModel>();
      final userId = authViewModel.currentUser?.uid;
      
      if (userId != null) {
        nutritionViewModel.selectDay(selectedDayIndex, userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NutritionViewModel, AuthViewModel>(
      builder: (context, nutritionViewModel, authViewModel, child) {
        final meals = nutritionViewModel.meals;
        final weekDays = nutritionViewModel.weekDays;
        final userId = authViewModel.currentUser?.uid;
        
        // Calculate total calories for the selected day
        final totalCalories = meals.fold<double>(0.0, (sum, meal) => sum + meal.calories).round();
        final selectedDayName = nutritionViewModel.formatDate(nutritionViewModel.selectedDate);

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
                  if (userId != null) {
                    nutritionViewModel.selectDay(selectedDayIndex, userId);
                  }
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
                  itemCount: weekDays.length,
                  itemBuilder: (context, i) {
                    final selected = i == selectedDayIndex;
                    final date = weekDays[i];
                    final formattedDate = nutritionViewModel.formatDate(date);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedDayIndex = i);
                        if (userId != null) {
                          nutritionViewModel.selectDay(i, userId);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFFF7A4D) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            formattedDate,
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
              
              // Calorie Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  '${selectedDayName}\'s calories consumed: $totalCalories kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Loading or meals list
              Expanded(
                child: nutritionViewModel.isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : meals.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.no_meals,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No meals recorded for this day',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: meals.length,
                            itemBuilder: (context, i) {
                              final meal = meals[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                color: _getMealColor(i),
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
                                            child: Icon(_getMealIcon(meal.mealType), color: Colors.orange),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  meal.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Text(
                                                  meal.mealType,
                                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_horiz, color: Colors.black),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                final result = await Navigator.pushNamed(context, '/edit-food', arguments: meal);
                                                if (result == true) {
                                                  // Refresh meals if edit was successful
                                                  if (userId != null) {
                                                    nutritionViewModel.selectDay(selectedDayIndex, userId);
                                                  }
                                                }
                                              } else if (value == 'delete') {
                                                final userId = authViewModel.currentUser?.uid;
                                                if (userId != null) {
                                                  nutritionViewModel.deleteMeal(meal.id, userId);
                                                }
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
                                          Text(
                                            '${meal.calories.toInt()} kcal',
                                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${meal.timestamp.hour}:${meal.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(color: Colors.black54, fontSize: 13),
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
