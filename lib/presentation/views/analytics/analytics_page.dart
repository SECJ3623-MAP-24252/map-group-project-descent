import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/models/meal_model.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final MealRepository _mealRepository = getIt<MealRepository>();
  List<MealModel> _meals = [];
  bool _isLoading = true;
  String _selectedPeriod = '7 days';
  final List<String> _periods = ['7 days', '30 days', '90 days'];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final userId = authViewModel.currentUser?.uid ?? 'default_user';

      final days =
          _selectedPeriod == '7 days'
              ? 7
              : _selectedPeriod == '30 days'
              ? 30
              : 90;
      final startDate = DateTime.now().subtract(Duration(days: days));
      final endDate = DateTime.now();

      _meals = await _mealRepository.getMealsInDateRange(
        userId,
        startDate,
        endDate,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadAnalyticsData();
            },
            itemBuilder:
                (context) =>
                    _periods.map((period) {
                      return PopupMenuItem(value: period, child: Text(period));
                    }).toList(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6F36B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Showing data for last $_selectedPeriod',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Calorie trend chart
                    _buildCalorieTrendChart(),
                    const SizedBox(height: 24),

                    // Macro breakdown pie chart
                    _buildMacroBreakdownChart(),
                    const SizedBox(height: 24),

                    // Meal type distribution
                    _buildMealTypeDistribution(),
                    const SizedBox(height: 24),

                    // Weekly average
                    _buildWeeklyAverage(),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCards() {
    final totalCalories = _meals.fold<double>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final avgCalories = _meals.isEmpty ? 0 : totalCalories / _getDaysInPeriod();
    final totalMeals = _meals.length;
    final avgMeals = _meals.isEmpty ? 0 : totalMeals / _getDaysInPeriod();

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Calories',
            '${totalCalories.round()}',
            'cal',
            Colors.orange,
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg/Day',
            '${avgCalories.round()}',
            'cal',
            Colors.blue,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calorie Intake Trend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.now().subtract(
                          Duration(days: _getDaysInPeriod() - value.toInt()),
                        );
                        return Text(
                          DateFormat('M/d').format(date),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getCalorieSpots(),
                    isCurved: true,
                    color: const Color(0xFFFF7A4D),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF7A4D).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBreakdownChart() {
    final totalProtein = _meals.fold<double>(
      0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = _meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
    final totalFat = _meals.fold<double>(0, (sum, meal) => sum + meal.fat);
    final total = totalProtein + totalCarbs + totalFat;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'No macro data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macro Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalProtein,
                          title: '${((totalProtein / total) * 100).round()}%',
                          color: Colors.red,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: totalCarbs,
                          title: '${((totalCarbs / total) * 100).round()}%',
                          color: Colors.green,
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: totalFat,
                          title: '${((totalFat / total) * 100).round()}%',
                          color: Colors.purple,
                          radius: 60,
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      'Protein',
                      '${totalProtein.round()}g',
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      'Carbs',
                      '${totalCarbs.round()}g',
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      'Fat',
                      '${totalFat.round()}g',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeDistribution() {
    final mealTypeCounts = <String, int>{};
    for (final meal in _meals) {
      mealTypeCounts[meal.mealType] = (mealTypeCounts[meal.mealType] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...mealTypeCounts.entries.map((entry) {
            final percentage =
                (_meals.isEmpty ? 0 : (entry.value / _meals.length) * 100)
                    .round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getMealTypeColor(entry.key),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${entry.value} ($percentage%)',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeeklyAverage() {
    final weeklyCalories =
        _meals.fold<double>(0, (sum, meal) => sum + meal.calories) /
        (_getDaysInPeriod() / 7);
    final weeklyMeals = _meals.length / (_getDaysInPeriod() / 7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F36B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6F36B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Averages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${weeklyCalories.round()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text(
                    'Calories/Week',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${weeklyMeals.round()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'Meals/Week',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  List<FlSpot> _getCalorieSpots() {
    final dailyCalories = <int, double>{};
    final days = _getDaysInPeriod();

    // Initialize all days with 0 calories
    for (int i = 0; i < days; i++) {
      dailyCalories[i] = 0;
    }

    // Calculate calories for each day
    for (final meal in _meals) {
      final daysDiff = DateTime.now().difference(meal.timestamp).inDays;
      final dayIndex = days - daysDiff - 1;
      if (dayIndex >= 0 && dayIndex < days) {
        dailyCalories[dayIndex] =
            (dailyCalories[dayIndex] ?? 0) + meal.calories;
      }
    }

    return dailyCalories.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  int _getDaysInPeriod() {
    switch (_selectedPeriod) {
      case '7 days':
        return 7;
      case '30 days':
        return 30;
      case '90 days':
        return 90;
      default:
        return 7;
    }
  }
}
