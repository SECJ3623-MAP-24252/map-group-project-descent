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
  String? _currentUserId; // To track if userId has changed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authViewModel = context.watch<AuthViewModel>();
    final homeViewModel = context.read<HomeViewModel>();

    final newUserId = authViewModel.currentUser?.uid;
    if (newUserId != null && newUserId != _currentUserId) {
      _currentUserId = newUserId;
      homeViewModel.loadInitialData(_currentUserId!);
    } else if (newUserId == null && _currentUserId != null) {
      _currentUserId = null;
      homeViewModel.clearMeals();
    }
  }

  void _refreshData() {
    final authViewModel = context.read<AuthViewModel>();
    final homeViewModel = context.read<HomeViewModel>();
    final userId = authViewModel.currentUser?.uid;
    if (userId != null) {
      Future.wait([
        homeViewModel.loadUserData(userId),
        homeViewModel.refreshTodaysMeals(userId),
        authViewModel.refreshUserData(),
      ]);
    }
  }

  Widget _buildProfileImage(String? photoURL) {
    ImageProvider? imageProvider;
    if (photoURL != null && photoURL.startsWith('data:image')) {
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        imageProvider = MemoryImage(bytes);
      } catch (e) {
        // Ignore errors, which will result in the default icon being used.
      }
    } else if (photoURL != null && photoURL.startsWith('http')) {
      imageProvider = NetworkImage(photoURL);
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFD6F36B).withAlpha(128),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person_outline, color: Colors.black, size: 28)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer2<AuthViewModel, HomeViewModel>(
        builder: (context, authViewModel, homeViewModel, child) {
          final currentUser = authViewModel.currentUser;
          final todaysMeals = homeViewModel.todaysMeals;
          final totalCalories = homeViewModel.totalCalories;
          final calorieGoal = homeViewModel.user?.calorieGoal ?? 2000;

          String getDisplayName() {
            if (currentUser?.displayName != null &&
                currentUser!.displayName!.isNotEmpty) {
              return currentUser.displayName!.split(' ').first;
            }
            return "User";
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome,',
                        style: TextStyle(fontSize: 16, color: Colors.black54)),
                    Text(getDisplayName(),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/profile').then((_) {
                      _refreshData();
                    }),
                    child: _buildProfileImage(currentUser?.photoURL),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.black54),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Notifications coming soon!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.black54),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/profile').then((_) {
                      _refreshData();
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text('Track your diet\njourney',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2)),
                      const SizedBox(height: 20),
                      _buildCaloriesCard(
                          homeViewModel, totalCalories, calorieGoal),
                      const SizedBox(height: 20),
                      _buildDaysRow(homeViewModel, authViewModel),
                      const SizedBox(height: 20),
                      _buildMealsHeader(todaysMeals.length),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

              ),
              _buildMealsList(homeViewModel, todaysMeals, authViewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCaloriesCard(
      HomeViewModel homeViewModel, int totalCalories, int calorieGoal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD6F36B).withAlpha(178),
            const Color(0xFFD6F36B).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calories Consumed',
                      style: TextStyle(fontSize: 14, color: Colors.black87)),
                  Text('$totalCalories / $calorieGoal cal',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ],
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: homeViewModel.getCalorieProgress(),
                  backgroundColor: Colors.white.withAlpha(102),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.black),
                  strokeWidth: 8,


                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutrientInfo('Protein',
                  '${homeViewModel.proteinGrams.round()}g', Colors.blue),
              _buildNutrientInfo('Carbs',
                  '${homeViewModel.carbsGrams.round()}g', Colors.orange),
              _buildNutrientInfo(
                  'Fat', '${homeViewModel.fatGrams.round()}g', Colors.red),
            ],
          ),
        ],
      ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildDaysRow(
      HomeViewModel homeViewModel, AuthViewModel authViewModel) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: homeViewModel.getWeekDays().length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = homeViewModel.getWeekDays()[index];
          final isSelected =
              homeViewModel.selectedDate.day == day['fullDate'].day;
          return GestureDetector(
            onTap: () {
              final userId = authViewModel.currentUser?.uid;
              if (userId != null) {
                homeViewModel.selectDate(day['fullDate'], userId);
              }
            },
            child: _DayItem(
              day: day['day'],
              date: day['date'],
              selected: isSelected,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealsHeader(int mealCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Today's Meals",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$mealCount meals',
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMealsList(HomeViewModel homeViewModel, List<dynamic> todaysMeals,
      AuthViewModel authViewModel) {
    if (homeViewModel.isBusy) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (todaysMeals.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fastfood_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 20),
                Text('No meals logged yet',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Tap the "+" button to add your first meal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final meal = todaysMeals[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _MealCard(
              title: meal.name,
              items: [meal.description ?? 'No description'],
              calories: meal.calories.toInt(),
              time: DateFormat('h:mm a').format(meal.timestamp.toLocal()),
              onTap: () {
                Navigator.pushNamed(context, '/edit-food', arguments: meal)
                    .then((_) => _refreshData());
              },
            ),
          );
        },
        childCount: todaysMeals.length,
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final String day;
  final String date;
  final bool selected;


  const _DayItem(
      {required this.day, required this.date, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFD6F36B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: selected
            ? Border.all(color: Colors.black.withAlpha(25), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.black : Colors.black54)),
          const SizedBox(height: 4),
          Text(date,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.black : Colors.black54)),
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(items.join(', '),
                      style: const TextStyle(color: Colors.black54),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$calories cal',
                    style: const TextStyle(
                        color: Color(0xFFFF7A4D),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(time,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
