import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/food_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';
import 'food_scanner.dart';
import 'profile.dart';
import 'daily_nutrition.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'BiteWise',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(AppConstants.primaryColor),
                  child: authViewModel.currentUser?.photoURL != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            authViewModel.currentUser!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 16,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 16,
                        ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<FoodViewModel>(
        builder: (context, foodViewModel, child) {
          if (foodViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: 24),
                _buildCalorieSummary(foodViewModel),
                const SizedBox(height: 24),
                _buildTodaysMeals(foodViewModel),
                const SizedBox(height: 24),
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final displayName = authViewModel.currentUser?.displayName?.split(' ').first ?? 'User';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: const Color(AppConstants.textLightColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalorieSummary(FoodViewModel foodViewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Calories',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(AppConstants.textLightColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${foodViewModel.totalCalories.round()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.textColor),
                  ),
                ),
                const Text(
                  'calories',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(AppConstants.textLightColor),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.black,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMeals(FoodViewModel foodViewModel) {
    if (foodViewModel.todaysMeals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: const Color(AppConstants.textLightColor).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged today',
              style: TextStyle(
                fontSize: 18,
                color: const Color(AppConstants.textLightColor).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first meal',
              style: TextStyle(
                fontSize: 14,
                color: const Color(AppConstants.textLightColor).withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Meals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: 16),
        ...foodViewModel.todaysMeals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getMealIcon(meal.name),
              color: const Color(AppConstants.secondaryColor),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppConstants.textColor),
                  ),
                ),
                Text(
                  '${meal.totalCalories.round()} calories',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppConstants.textLightColor),
                  ),
                ),
              ],
            ),
          ),
          Text(
            meal.time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(AppConstants.textLightColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Scan Food',
                Icons.camera_alt,
                const Color(AppConstants.secondaryColor),
                () => Navigator.pushNamed(context, '/scanner'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Add Manually',
                Icons.edit,
                const Color(AppConstants.primaryColor),
                () => Navigator.pushNamed(context, '/add-food'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(AppConstants.secondaryColor),
      unselectedItemColor: const Color(AppConstants.textLightColor),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Nutrition',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            Navigator.pushNamed(context, '/nutrition');
            break;
          case 2:
            _showAddFoodOptions(context);
            break;
          case 3:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
    );
  }

  void _showAddFoodOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Food',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(AppConstants.secondaryColor),
                ),
              ),
              title: const Text('Scan Food'),
              subtitle: const Text('Use camera to identify food'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/scanner');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(AppConstants.secondaryColor),
                ),
              ),
              title: const Text('Add Manually'),
              subtitle: const Text('Enter food details manually'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-food');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealName) {
    switch (mealName.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.restaurant;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.coffee;
      default:
        return Icons.fastfood;
    }
  }
} 