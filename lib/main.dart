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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const HomePage(),
      // login: const LoginPage(),
      // register: const RegisterPage(),
      // forget: const ForgetPage(),
      // dashboard: const DashboardPage(),
      // profile: const ProfilePage(),
    );
  }
}