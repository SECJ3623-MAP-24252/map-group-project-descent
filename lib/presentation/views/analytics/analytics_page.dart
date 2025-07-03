import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../../core/services/dependency_injection.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, double> _macroBreakdown = {};
  double _avgDailyCalories = 0;
  int _totalMeals = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final authViewModel = context.read<AuthViewModel>();
    final userId = authViewModel.currentUser?.uid;

    if (userId == null) return;

    try {
      final mealRepository = getIt<MealRepository>();
      final now = DateTime.now();

      // Load last 7 days of data
      _weeklyData = [];
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      int totalMealsCount = 0;

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final meals = await mealRepository.getMealsForDate(userId, date);

        double dayCalories = 0;
        double dayProtein = 0;
        double dayCarbs = 0;
        double dayFat = 0;

        for (final meal in meals) {
          dayCalories += meal.calories;
          dayProtein += meal.protein;
          dayCarbs += meal.carbs;
          dayFat += meal.fat;
          totalMealsCount++;
        }

        _weeklyData.add({
          'date': date,
          'calories': dayCalories,
          'protein': dayProtein,
          'carbs': dayCarbs,
          'fat': dayFat,
          'meals': meals.length,
        });

        totalCalories += dayCalories;
        totalProtein += dayProtein;
        totalCarbs += dayCarbs;
        totalFat += dayFat;
      }

      _avgDailyCalories = totalCalories / 7;
      _totalMeals = totalMealsCount;

      // Calculate macro breakdown
      final totalMacros = totalProtein + totalCarbs + totalFat;
      if (totalMacros > 0) {
        _macroBreakdown = {
          'Protein': (totalProtein / totalMacros) * 100,
          'Carbs': (totalCarbs / totalMacros) * 100,
          'Fat': (totalFat / totalMacros) * 100,
        };
      }

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
          onPressed:
              () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              ),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadAnalyticsData();
            },
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
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Avg Daily Calories',
                            value: _avgDailyCalories.round().toString(),
                            subtitle: 'Last 7 days',
                            color: Colors.orange,
                            icon: Icons.local_fire_department,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Meals',
                            value: _totalMeals.toString(),
                            subtitle: 'This week',
                            color: Colors.green,
                            icon: Icons.restaurant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Weekly Calories Chart
                    const Text(
                      'Weekly Calories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < _weeklyData.length) {
                                    final date =
                                        _weeklyData[value.toInt()]['date']
                                            as DateTime;
                                    return Text(
                                      '${date.day}/${date.month}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots:
                                  _weeklyData.asMap().entries.map((entry) {
                                    return FlSpot(
                                      entry.key.toDouble(),
                                      entry.value['calories'].toDouble(),
                                    );
                                  }).toList(),
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

                    const SizedBox(height: 24),

                    // Macro Breakdown
                    const Text(
                      'Macro Breakdown (Last 7 Days)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          _macroBreakdown.isEmpty
                              ? const Center(child: Text('No data available'))
                              : Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: PieChart(
                                      PieChartData(
                                        sections: [
                                          PieChartSectionData(
                                            value:
                                                _macroBreakdown['Protein'] ?? 0,
                                            title:
                                                '${(_macroBreakdown['Protein'] ?? 0).round()}%',
                                            color: Colors.blue,
                                            radius: 60,
                                          ),
                                          PieChartSectionData(
                                            value:
                                                _macroBreakdown['Carbs'] ?? 0,
                                            title:
                                                '${(_macroBreakdown['Carbs'] ?? 0).round()}%',
                                            color: Colors.orange,
                                            radius: 60,
                                          ),
                                          PieChartSectionData(
                                            value: _macroBreakdown['Fat'] ?? 0,
                                            title:
                                                '${(_macroBreakdown['Fat'] ?? 0).round()}%',
                                            color: Colors.red,
                                            radius: 60,
                                          ),
                                        ],
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _MacroLegendItem(
                                          color: Colors.blue,
                                          label: 'Protein',
                                          percentage:
                                              _macroBreakdown['Protein'] ?? 0,
                                        ),
                                        const SizedBox(height: 8),
                                        _MacroLegendItem(
                                          color: Colors.orange,
                                          label: 'Carbs',
                                          percentage:
                                              _macroBreakdown['Carbs'] ?? 0,
                                        ),
                                        const SizedBox(height: 8),
                                        _MacroLegendItem(
                                          color: Colors.red,
                                          label: 'Fat',
                                          percentage:
                                              _macroBreakdown['Fat'] ?? 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                    ),

                    const SizedBox(height: 24),

                    // Daily Meals Chart
                    const Text(
                      'Daily Meals Count',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < _weeklyData.length) {
                                    final date =
                                        _weeklyData[value.toInt()]['date']
                                            as DateTime;
                                    const days = [
                                      'Sun',
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                    ];
                                    return Text(
                                      days[date.weekday % 7],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              _weeklyData.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value['meals'].toDouble(),
                                      color: const Color(0xFFD6F36B),
                                      width: 20,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;

  const _MacroLegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label\n${percentage.round()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
