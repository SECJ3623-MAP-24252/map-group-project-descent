import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './home/home_page.dart';
import './nutrition/daily_nutrition_page.dart';
import './profile/profile_page.dart';
import './analytics/analytics_page.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    DailyNutritionPage(),
    ProfilePage(),
    AnalyticsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddFoodOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add Food',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Color(0xFFFF7A4D), size: 28),
              ),
              title: const Text('Scan Food', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Use camera to identify food', style: TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/scanner').then((_) {
                  final authViewModel = context.read<AuthViewModel>();
                  final homeViewModel = context.read<HomeViewModel>();
                  final userId = authViewModel.currentUser?.uid;
                  if (userId != null) {
                    homeViewModel.refreshTodaysMeals(userId);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFFFF7A4D), size: 28),
              ),
              title: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Enter food details manually', style: TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-food').then((_) {
                  final authViewModel = context.read<AuthViewModel>();
                  final homeViewModel = context.read<HomeViewModel>();
                  final userId = authViewModel.currentUser?.uid;
                  if (userId != null) {
                    homeViewModel.refreshTodaysMeals(userId);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodOptions,
        backgroundColor: const Color(0xFFFF7A4D),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4.0,
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
            _buildBottomNavItem(icon: Icons.calendar_today_outlined, label: 'Nutrition', index: 1),
            const SizedBox(width: 40), // The space for the FAB
            _buildBottomNavItem(icon: Icons.person_outline, label: 'Profile', index: 2),
            _buildBottomNavItem(icon: Icons.analytics_outlined, label: 'Analytics', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      {required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon,
          color: isSelected ? const Color(0xFFFF7A4D) : Colors.grey),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}
