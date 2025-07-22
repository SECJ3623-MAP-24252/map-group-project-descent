import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

/// This class is the splash screen of the application.
/// It is shown when the application is first launched.
class SplashScreen extends StatefulWidget {
  /// Creates a new instance of the [SplashScreen] class.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
    
    if (mounted) {
      final authViewModel = context.read<AuthViewModel>();
      final isLoggedIn = await authViewModel.checkAuthState();
      
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6F36B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 60,
                color: Color(0xFFFF7A4D),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Nutrition Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your healthy journey',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}