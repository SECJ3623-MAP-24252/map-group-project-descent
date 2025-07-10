import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/nutrition_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class NutritionGraphPage extends StatefulWidget {
  const NutritionGraphPage({Key? key}) : super(key: key);

  @override
  State<NutritionGraphPage> createState() => _NutritionGraphPageState();
}

class _NutritionGraphPageState extends State<NutritionGraphPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = context.read<AuthViewModel>();
      final nutritionViewModel = context.read<NutritionViewModel>();
      final userId = authViewModel.currentUser?.uid ?? 'default_user';
      await nutritionViewModel.fetchWeeklyCalories(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nutritionViewModel = context.watch<NutritionViewModel>();
    final weekDays = nutritionViewModel.weekDays;
    final caloriesPerDay = nutritionViewModel.weeklyCalories;
    final isLoading = nutritionViewModel.isWeeklyCaloriesLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Nutrition Graph'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SizedBox(
                    height: 220,
                    width: 340,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (caloriesPerDay.isNotEmpty ? (caloriesPerDay.reduce((a, b) => a > b ? a : b) + 100).toDouble() : 1000),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${caloriesPerDay[group.x]} cal',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final dayIndex = value.toInt();
                                if (dayIndex < 0 || dayIndex >= weekDays.length) return const SizedBox.shrink();
                                return Text(
                                  ['S', 'M', 'T', 'W', 'T', 'F', 'S'][dayIndex],
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (i < caloriesPerDay.length ? caloriesPerDay[i].toDouble() : 0),
                              color: Colors.green,
                              width: 10,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
} 