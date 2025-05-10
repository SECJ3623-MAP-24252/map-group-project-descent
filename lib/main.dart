import 'package:bitewise/pages/home.dart';
import 'package:bitewise/pages/login.dart';
import 'package:bitewise/pages/register.dart';
import 'package:bitewise/pages/forget.dart';
import 'package:bitewise/pages/profile.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forget': (context) => const ForgetPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}