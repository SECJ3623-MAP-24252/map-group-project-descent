import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/dependency_injection.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/scanner_viewmodel.dart';
import 'presentation/viewmodels/nutrition_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'app/routes.dart';
import 'presentation/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupDependencyInjection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<HomeViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<ScannerViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<NutritionViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<ProfileViewModel>()),
      ],
      child: MaterialApp(
        title: 'Nutrition Tracker',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
