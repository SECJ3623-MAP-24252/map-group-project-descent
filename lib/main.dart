import 'package:bitewise/pages/home.dart';
import 'package:bitewise/pages/login.dart';
import 'package:bitewise/pages/register.dart';
import 'package:bitewise/pages/forget.dart';
import 'package:bitewise/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

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
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: initialRoute,
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
