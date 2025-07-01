import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/food_viewmodel.dart';
import 'views/home.dart';
import 'views/login.dart';
import 'views/register.dart';
import 'views/forget.dart';
import 'views/profile.dart';
import 'views/food_scanner.dart';
import 'views/daily_nutrition.dart';
import 'views/edit_food.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FoodViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BiteWise',
        theme: ThemeData(
          fontFamily: 'Poppins',
          primarySwatch: Colors.green,
          primaryColor: const Color(AppConstants.primaryColor),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(AppConstants.backgroundColor),
            foregroundColor: Color(AppConstants.textColor),
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forget': (context) => const ForgetPage(),
          '/profile': (context) => const ProfilePage(),
          '/scanner': (context) => const FoodScannerPage(),
          '/nutrition': (context) => const DailyNutritionPage(),
          '/add-food': (context) => const AddFoodPage(),
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
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authViewModel.isAuthenticated) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
