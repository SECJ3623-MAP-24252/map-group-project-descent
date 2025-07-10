import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/nutrition_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DailyNutritionPage extends StatefulWidget {
  const DailyNutritionPage({super.key});

  @override
  State<DailyNutritionPage> createState() => _DailyNutritionPageState();
}

class _DailyNutritionPageState extends State<DailyNutritionPage> {
  int selectedDayIndex = 3; // Start with today
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authViewModel = context.watch<AuthViewModel>();
    final nutritionViewModel = context.read<NutritionViewModel>();
    final newUserId = authViewModel.currentUser?.uid;

    if (newUserId != null && newUserId != _currentUserId) {
      _currentUserId = newUserId;
      // Use a post-frame callback to avoid calling setState during a build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          nutritionViewModel.selectDay(selectedDayIndex, _currentUserId!);
        }
      });
    } else if (newUserId == null && _currentUserId != null) {
      _currentUserId = null;
      nutritionViewModel.clearMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NutritionViewModel, AuthViewModel>(
      builder: (context, nutritionViewModel, authViewModel, child) {
        final userId = authViewModel.currentUser?.uid;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                floating: true,
                elevation: 1,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text('Daily Nutrition',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black54),
                    onPressed: () {
                      if (userId != null) {
                        nutritionViewModel.selectDay(selectedDayIndex, userId);
                      }
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70.0),
                  child: _buildDateSelector(nutritionViewModel, userId),
                ),
              ),
              _buildBody(nutritionViewModel, authViewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(NutritionViewModel viewModel, String? userId) {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.weekDays.length,
        itemBuilder: (context, i) {
          final selected = i == selectedDayIndex;
          final date = viewModel.weekDays[i];
          final dayName = DateFormat('E').format(date); // e.g., Mon
          final dayNumber = DateFormat('d').format(date); // e.g., 12

          return GestureDetector(
            onTap: () {
              setState(() => selectedDayIndex = i);
              if (userId != null) {
                viewModel.selectDay(i, userId);
              }
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF7A4D) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
      NutritionViewModel nutritionViewModel, AuthViewModel authViewModel) {
    if (nutritionViewModel.isBusy) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final meals = nutritionViewModel.meals;
    if (meals.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_meals_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text('No meals recorded',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final totalCalories =
        meals.fold<double>(0.0, (sum, meal) => sum + meal.calories).round();
    final totalProtein =
        meals.fold<double>(0.0, (sum, meal) => sum + meal.protein).round();
    final totalFat =
        meals.fold<double>(0.0, (sum, meal) => sum + meal.fat).round();
    final totalCarbs =
        meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs).round();

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          _buildSummaryCard(
              totalCalories, totalProtein, totalFat, totalCarbs),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(
              'Meals for ${nutritionViewModel.formatDate(nutritionViewModel.selectedDate)}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...meals.map((meal) =>
              _buildMealCard(meal, nutritionViewModel, authViewModel)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      int calories, int protein, int fat, int carbs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Consumption',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    '$calories',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7A4D)),
                  ),
                  const Text('kcal',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              _buildMacroStat('Protein', protein, Colors.green),
              _buildMacroStat('Fat', fat, Colors.red),
              _buildMacroStat('Carbs', carbs, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '${value}g',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMealCard(dynamic meal, NutritionViewModel nutritionViewModel,
      AuthViewModel authViewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${meal.mealType} • ${DateFormat('h:mm a').format(meal.timestamp.toLocal())}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) async {
                  final userId = authViewModel.currentUser?.uid;
                  if (value == 'edit') {
                    final result = await Navigator.pushNamed(context, '/edit-food',
                        arguments: meal);
                    if (result == true && userId != null) {
                      nutritionViewModel.selectDay(selectedDayIndex, userId);
                    }
                  } else if (value == 'delete' && userId != null) {
                    nutritionViewModel.deleteMeal(meal.id, userId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutritionStat(
                  'Calories', '${meal.calories.toInt()} kcal', Colors.orange),
              _buildNutritionStat(
                  'Protein', '${meal.protein.toInt()}g', Colors.green),
              _buildNutritionStat('Fat', '${meal.fat.toInt()}g', Colors.red),
              _buildNutritionStat(
                  'Carbs', '${meal.carbs.toInt()}g', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.emoji_food_beverage_outlined;
    }
  }
}
