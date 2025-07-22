import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';

class HomePageLandscape extends StatelessWidget {
  const HomePageLandscape({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, HomeViewModel>(
      builder: (context, authViewModel, homeViewModel, child) {
        final currentUser = authViewModel.currentUser;
        final todaysMeals = homeViewModel.todaysMeals;
        final totalCalories = homeViewModel.totalCalories;

        String getDisplayName() {
          if (currentUser?.displayName != null &&
              currentUser!.displayName!.isNotEmpty) {
            return currentUser!.displayName!.split(' ').first;
          }
          return "User";
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Left Panel - User Info & Quick Actions
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildUserHeader(currentUser, getDisplayName()),
                        const SizedBox(height: 20),
                        _buildQuickStats(totalCalories, homeViewModel),
                        const SizedBox(height: 20),
                        _buildQuickActions(context),
                        const Spacer(),
                        _buildNavigationMenu(context),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Center Panel - Daily Overview & Meals
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailyOverviewHeader(),
                        const SizedBox(height: 16),
                        _buildNutritionProgress(totalCalories, homeViewModel),
                        const SizedBox(height: 20),
                        _buildRecentMeals(todaysMeals, authViewModel, homeViewModel),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Right Panel - Days & Goals
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildWeekDays(homeViewModel, authViewModel),
                        const SizedBox(height: 20),
                        _buildGoalsCard(),
                        const SizedBox(height: 20),
                        _buildInsightsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(currentUser, String displayName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F36B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6F36B).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD6F36B),
            child: _buildProfileImage(currentUser?.photoURL),
          ),
          const SizedBox(height: 12),
          const Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? photoURL) {
    if (photoURL != null && photoURL.startsWith('data:image')) {
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.memory(bytes, width: 60, height: 60, fit: BoxFit.cover),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    } else if (photoURL != null && photoURL.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.network(
          photoURL,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, color: Colors.black, size: 30);
          },
        ),
      );
    }
    return const Icon(Icons.person, color: Colors.black, size: 30);
  }

  Widget _buildQuickStats(int totalCalories, homeViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Calories', '$totalCalories', '2000', const Color(0xFFFF7A4D)),
          const SizedBox(height: 8),
          _buildStatRow('Protein', '${homeViewModel.proteinGrams.round()}g', '150g', Colors.blue),
          const SizedBox(height: 8),
          _buildStatRow('Carbs', '${homeViewModel.carbsGrams.round()}g', '250g', Colors.orange),
          const SizedBox(height: 8),
          _buildStatRow('Fat', '${homeViewModel.fatGrams.round()}g', '65g', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String current, String target, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$current / $target',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Scan Food',
            color: const Color(0xFFFF7A4D),
            onTap: () => Navigator.pushNamed(context, '/scanner'),
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.add,
            label: 'Add Meal',
            color: const Color(0xFFD6F36B),
            onTap: () => Navigator.pushNamed(context, '/add-food'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNavItem(Icons.restaurant, 'Nutrition', () => Navigator.pushNamed(context, '/nutrition')),
          _buildNavItem(Icons.timeline, 'Progress', () {}),
          _buildNavItem(Icons.person, 'Profile', () => Navigator.pushNamed(context, '/profile')),
          _buildNavItem(Icons.settings, 'Settings', () => Navigator.pushNamed(context, '/profile')),
          _buildNavItem(Icons.bar_chart, 'Graph', () => Navigator.pushNamed(context, '/nutrition-graph')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyOverviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Track your diet journey',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6F36B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFF7A4D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionProgress(int totalCalories, homeViewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD6F36B).withOpacity(0.8),
            const Color(0xFFD6F36B).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Goal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '$totalCalories / 2000 cal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CircularProgressIndicator(
                value: totalCalories / 2000,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 6,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutrientInfo('Protein', '${homeViewModel.proteinGrams.round()}g', Colors.blue),
              _buildNutrientInfo('Carbs', '${homeViewModel.carbsGrams.round()}g', Colors.orange),
              _buildNutrientInfo('Fat', '${homeViewModel.fatGrams.round()}g', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildRecentMeals(todaysMeals, authViewModel, homeViewModel) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Meals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ...todaysMeals.map((meal) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F36B).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.restaurant, color: Color(0xFFFF7A4D), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                meal.description ?? 'No description',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${meal.calories.toInt()} cal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF7A4D),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDays(homeViewModel, authViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...homeViewModel.getWeekDays().map((day) {
            final isSelected = homeViewModel.selectedDate.day == day['fullDate'].day;
            return GestureDetector(
              onTap: () {
                final userId = authViewModel.currentUser?.uid ?? 'default_user';
                homeViewModel.selectDate(day['fullDate'], userId);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD6F36B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day['day'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    Text(
                      day['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildGoalItem('Weight Loss', '0.5 kg/week', Icons.trending_down, const Color(0xFFFF7A4D)),
          const SizedBox(height: 8),
          _buildGoalItem('Water Intake', '8 glasses', Icons.local_drink, Colors.blue),
          const SizedBox(height: 8),
          _buildGoalItem('Exercise', '30 min', Icons.fitness_center, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, String target, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                target,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD6F36B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: const Color(0xFFFF7A4D),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Tip of the Day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF7A4D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'You\'re doing great! Keep tracking your meals consistently.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

