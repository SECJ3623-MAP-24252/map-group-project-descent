import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'home_page_landscape.dart';
import 'package:get_it/get_it.dart';
import 'package:bitewise/data/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _currentUserId; // To track if userId has changed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authViewModel = context.watch<AuthViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    final newUserId = authViewModel.currentUser?.uid;
    print(
      'HomePage: didChangeDependencies - newUserId: $newUserId, currentUserId: $_currentUserId',
    );

    if (newUserId != null && newUserId != _currentUserId) {
      print('HomePage: User ID changed, loading meals for: $newUserId');
      _currentUserId = newUserId;
      homeViewModel.loadTodaysMeals(_currentUserId!);
    } else if (newUserId == null && _currentUserId != null) {
      // User logged out, clear meals
      print('HomePage: User logged out, clearing meals');
      _currentUserId = null;
      homeViewModel.clearMeals();
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Already on home - reset selection
        setState(() {
          _selectedIndex = 0;
        });
        break;
      case 1:
        Navigator.pushNamed(context, '/nutrition').then((_) {
          // Reset to home when returning and refresh meals
          setState(() {
            _selectedIndex = 0;
          });
          final authViewModel = context.read<AuthViewModel>();
          final homeViewModel = context.read<HomeViewModel>();
          final userId = authViewModel.currentUser?.uid;
          if (userId != null) {
            homeViewModel.refreshTodaysMeals(userId);
          }
        });
        break;
      case 2:
        _showAddFoodOptions();
        break;
      case 3:
        Navigator.pushNamed(context, '/profile').then((_) async {
          // Reset to home when returning and refresh both meals and user data
          setState(() {
            _selectedIndex = 0;
          });
          final authViewModel = context.read<AuthViewModel>();
          final homeViewModel = context.read<HomeViewModel>();
          final userId = authViewModel.currentUser?.uid;
          if (userId != null) {
            homeViewModel.refreshTodaysMeals(userId);
          }
          // Refresh user data to update profile picture
          await authViewModel.refreshUserData();
        });
        break;
      case 4:
        Navigator.pushNamed(context, '/analytics').then((_) async {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }
  }

  void _showAddFoodOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
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
                      color: const Color(0xFFD6F36B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFFFF7A4D),
                    ),
                  ),
                  title: const Text('Scan Food'),
                  subtitle: const Text('Use camera to identify food'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/scanner').then((_) {
                      // Refresh meals when returning from scanner
                      final authViewModel = context.read<AuthViewModel>();
                      final homeViewModel = context.read<HomeViewModel>();
                      final userId = authViewModel.currentUser?.uid;
                      if (userId != null) {
                        homeViewModel.refreshTodaysMeals(userId);
                      }
                    });
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F36B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFFFF7A4D)),
                  ),
                  title: const Text('Add Manually'),
                  subtitle: const Text('Enter food details manually'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/add-food').then((_) {
                      // Refresh meals when returning from add food
                      final authViewModel = context.read<AuthViewModel>();
                      final homeViewModel = context.read<HomeViewModel>();
                      final userId = authViewModel.currentUser?.uid;
                      if (userId != null) {
                        homeViewModel.refreshTodaysMeals(userId);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileImage(String? photoURL) {
    if (photoURL != null && photoURL.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    } else if (photoURL != null && photoURL.startsWith('http')) {
      // Network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          photoURL,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, color: Colors.black, size: 24);
          },
        ),
      );
    }

    // Default icon
    return const Icon(Icons.person, color: Colors.black, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, HomeViewModel>(
      builder: (context, authViewModel, homeViewModel, child) {
        final currentUser = authViewModel.currentUser;
        final todaysMeals = homeViewModel.todaysMeals;
        final totalCalories = homeViewModel.totalCalories;

        print(
          'HomePage: Building with ${todaysMeals.length} meals, ${totalCalories} calories',
        );

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
            child: Column(
              children: [
                // Top bar with avatar, welcome, and icons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap:
                            () => Navigator.pushNamed(context, '/profile').then(
                              (_) async {
                                // Refresh user data when returning from profile
                                final authViewModel =
                                    context.read<AuthViewModel>();
                                await authViewModel.refreshUserData();
                              },
                            ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFD6F36B),
                          child: _buildProfileImage(currentUser?.photoURL),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Welcome and name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome,',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              getDisplayName(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Debug button to manually refresh
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black54),
                        onPressed: () {
                          final userId = authViewModel.currentUser?.uid;
                          if (userId != null) {
                            print('HomePage: Manual refresh triggered');
                            homeViewModel.refreshTodaysMeals(userId);
                          }
                        },
                      ),
                      // Notification and settings icons
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications coming soon!'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.black54),
                        onPressed:
                            () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ],
                  ),
                ),
                // Title and calories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track your diet\njourney',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Today's Calories Consumed: $totalCalories",
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      // Debug info
                      Text(
                        "Debug: ${todaysMeals.length} meals found",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Calories progress card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Container(
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                              strokeWidth: 6,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNutrientInfo(
                              'Protein',
                              '${homeViewModel.proteinGrams.round()}g',
                              Colors.blue,
                            ),
                            _buildNutrientInfo(
                              'Carbs',
                              '${homeViewModel.carbsGrams.round()}g',
                              Colors.orange,
                            ),
                            _buildNutrientInfo(
                              'Fat',
                              '${homeViewModel.fatGrams.round()}g',
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Days row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        homeViewModel.getWeekDays().asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final day = entry.value;
                          final isSelected =
                              homeViewModel.selectedDate.day ==
                              day['fullDate'].day;
                          return GestureDetector(
                            onTap: () {
                              final userId = authViewModel.currentUser?.uid;
                              if (userId != null) {
                                homeViewModel.selectDate(
                                  day['fullDate'],
                                  userId,
                                );
                              }
                            },
                            child: _DayItem(
                              day: day['day'],
                              date: day['date'],
                              selected: isSelected,
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Meals list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Meals",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${todaysMeals.length} meals',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (homeViewModel.isBusy)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (todaysMeals.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No meals recorded for today.\nTap "Add Meal" to get started!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ...todaysMeals
                            .map(
                              (meal) => _MealCard(
                                title: meal.name,
                                items: [meal.description ?? 'No description'],
                                calories: meal.calories.toInt(),
                                time: DateFormat(
                                  'h:mm a',
                                ).format(meal.timestamp.toLocal()),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/edit-food',
                                    arguments: meal,
                                  ).then((_) {
                                    // Refresh meals when returning from edit
                                    final userId =
                                        authViewModel.currentUser?.uid;
                                    if (userId != null) {
                                      homeViewModel.refreshTodaysMeals(userId);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      _AddMealCard(
                        title: 'Add Meal',
                        subtitle: 'Log your next meal',
                        icon: Icons.add,
                        onTap: _showAddFoodOptions,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onBottomNavTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFFFF7A4D),
              unselectedItemColor: const Color(0xFFB0B0B0),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant),
                  label: 'Nutrition',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        setState(() {
          _selectedIndex = 0;
        });
        break;
      case 1:
        Navigator.pushNamed(context, '/nutrition').then((_) {
          setState(() {
            _selectedIndex = 0;
          });
          final authViewModel = context.read<AuthViewModel>();
          final homeViewModel = context.read<HomeViewModel>();
          final userId = authViewModel.currentUser?.uid ?? 'default_user';
          homeViewModel.refreshTodaysMeals(userId);
        });
        break;
      case 2:
        _showAddFoodOptions();
        break;
      case 3:
        Navigator.pushNamed(context, '/profile').then((_) async {
          setState(() {
            _selectedIndex = 0;
          });
          final authViewModel = context.read<AuthViewModel>();
          final homeViewModel = context.read<HomeViewModel>();
          final userId = authViewModel.currentUser?.uid ?? 'default_user';
          homeViewModel.refreshTodaysMeals(userId);
          await authViewModel.refreshUserData();
        });
        break;
      case 4:
        Navigator.pushNamed(context, '/nutrition-graph');
        break;
    }
  }

  void _showAddFoodOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
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
                      color: const Color(0xFFD6F36B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFFFF7A4D),
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
                      color: const Color(0xFFD6F36B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFFFF7A4D)),
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

  Widget _buildProfileImage(String? photoURL) {
    if (photoURL != null && photoURL.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    } else if (photoURL != null && photoURL.startsWith('http')) {
      // Network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          photoURL,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, color: Colors.black, size: 24);
          },
        ),
      );
    }
    // Default icon
    return const Icon(Icons.person, color: Colors.black, size: 24);
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
}

class _DayItem extends StatelessWidget {
  final String day;
  final String date;
  final bool selected;

  const _DayItem({
    required this.day,
    required this.date,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD6F36B) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.black : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final int calories;
  final String time;
  final VoidCallback onTap;

  const _MealCard({
    required this.title,
    required this.items,
    required this.calories,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $item',
                        style: const TextStyle(color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$calories calories',
                    style: const TextStyle(
                      color: Color(0xFFFF7A4D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black54,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMealCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AddMealCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFD6F36B),
            child: Icon(icon, color: Colors.black),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.add_circle, color: Color(0xFFD6F36B)),
        ),
      ),
    );
  }
}
