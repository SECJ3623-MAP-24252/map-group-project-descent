import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/forget.dart';
import 'pages/profile.dart';
import 'pages/food_scanner.dart';
import 'pages/daily_nutrition.dart';
import 'pages/edit_food.dart';
import 'pages/edit_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if user is already logged in
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;

  runApp(MyApp(initialRoute: user != null ? '/' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forget': (context) => const ForgetPage(),
        '/profile': (context) => const ProfilePage(),
        '/scanner': (context) => const FoodScannerPage(),
        '/nutrition': (context) => const DailyNutritionPage(),
        '/add-food': (context) => const EditFoodPage(),
        '/edit-profile': (context) => const EditProfilePage(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes if needed
        switch (settings.name) {
          case '/edit-food':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => EditFoodPage(foodData: args?['foodData']),
            );
          default:
            return null;
        }
      },
    );
  }
}
