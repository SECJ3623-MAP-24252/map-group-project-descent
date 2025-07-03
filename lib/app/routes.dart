import 'package:flutter/material.dart';
import '../presentation/views/auth/login_page.dart';
import '../presentation/views/auth/register_page.dart';
import '../presentation/views/auth/forgot_password_page.dart';
import '../presentation/views/home/home_page.dart';
import '../presentation/views/profile/profile_page.dart';
import '../presentation/views/profile/edit_profile_page.dart';
import '../presentation/views/nutrition/daily_nutrition_page.dart';
import '../presentation/views/nutrition/add_food_page.dart';
import '../presentation/views/nutrition/edit_food_page.dart';
import '../presentation/views/scanner/food_scanner_page.dart';
import '../presentation/views/scanner/food_scan_results_page.dart';
import '../data/models/meal_model.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      case '/nutrition':
        return MaterialPageRoute(builder: (_) => const DailyNutritionPage());
      case '/add-food':
        return MaterialPageRoute(builder: (_) => const AddFoodPage());
      case '/edit-food':
        final args = settings.arguments;
        if (args is MealModel) {
          return MaterialPageRoute(builder: (_) => EditFoodPage(meal: args));
        }
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('Invalid arguments for ${settings.name}'),
                ),
              ),
        );
      case '/scanner':
        return MaterialPageRoute(builder: (_) => const FoodScannerPage());
      case '/scan-results':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (_) => FoodScanResultsPage(
                  imageFile: args['imageFile'],
                  nutritionData: args['nutritionData'],
                ),
          );
        }
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('Invalid arguments for ${settings.name}'),
                ),
              ),
        );
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
