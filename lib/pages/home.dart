// Updated home.dart with scan functionality
import 'package:flutter/material.dart';
import 'edit_food.dart';
import 'daily_nutrition.dart';
import 'food_scanner.dart'; // Add this import

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 600 ? 32.0 : 20.0;

    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text("Welcome to BiteWise!", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: Text("Go to Profile"),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: padding),
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/icons/logo.png'), // Placeholder
                  ),
                  const SizedBox(width: 12),
                  // Welcome and name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome,',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        Text(
                          'Abdulrahman',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Notification and settings icons
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: Colors.black54),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.black54),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Title and calories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Track your diet\njourney',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Today's Calories Consumed: 1783",
                    style: TextStyle(
                      color: Color(0xFFE57373),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Graph placeholder
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('Graph Placeholder'),
                ),
              ),
            ),
            // Days row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DayItem(day: 'Mon', date: '12', selected: false),
                  _DayItem(day: 'Tue', date: '13', selected: false),
                  _DayItem(day: 'Wed', date: '14', selected: false),
                  _DayItem(day: 'Thu', date: '15', selected: true),
                  _DayItem(day: 'Fri', date: '16', selected: false),
                  _DayItem(day: 'Sat', date: '17', selected: false),
                  _DayItem(day: 'Sun', date: '18', selected: false),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Meals list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _MealCard(
                    title: 'Add Breakfast',
                    subtitle: 'Recommended 450-650 cal',
                    icon: Icons.free_breakfast,
                  ),
                  _MealCard(
                    title: 'Add Lunch',
                    subtitle: 'Recommended 450-650 cal',
                    icon: Icons.lunch_dining,
                  ),
                  _MealCard(
                    title: 'Add Dinner',
                    subtitle: 'Recommended 450-650 cal',
                    icon: Icons.dinner_dining,
                  ),
                ],
              ),
            ),
            // Bottom bar and add button
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(Icons.home, color: Color(0xFFB0B0B0)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DailyNutritionPage()),
                          );
                        },
                        child: Icon(Icons.calendar_today, color: Color(0xFFB0B0B0)),
                      ),
                      SizedBox(width: 48), // Space for FAB
                      // Add scan button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FoodScannerPage()),
                          );
                        },
                        child: Icon(Icons.camera_alt, color: Color(0xFFB0B0B0)),
                      ),
                      Icon(Icons.person, color: Color(0xFFB0B0B0)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: FloatingActionButton(
                    backgroundColor: Color(0xFFD6F36B),
                    onPressed: () {
                      // Show options: Manual Add or Scan
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.camera_alt, color: Color(0xFFFF7A4D)),
                                title: Text('Scan Food'),
                                subtitle: Text('Use camera to identify food'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FoodScannerPage()),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.edit, color: Color(0xFFFF7A4D)),
                                title: Text('Add Manually'),
                                subtitle: Text('Enter food details manually'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddFoodPage()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the existing _DayItem and _MealCard classes unchanged
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
  final String subtitle;
  final IconData icon;
  const _MealCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD6F36B),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.check_circle, color: Color(0xFFD6F36B)),
        onTap: () {},
      ),
    );
  }
}

