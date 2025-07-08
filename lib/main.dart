import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'core/services/dependency_injection.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/scanner_viewmodel.dart';
import 'presentation/viewmodels/nutrition_viewmodel.dart';
import 'presentation/viewmodels/profile_viewmodel.dart';
import 'app/routes.dart';
import 'presentation/views/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  // You can perform heavy data processing here if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission for notifications
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

  print('User granted permission: ${settings.authorizationStatus}');

  // Get FCM token and update it in the user's profile
  FirebaseMessaging.instance.getToken().then((token) {
    if (token != null) {
      print('FCM Token: $token');
      // You might want to save this token to your database for the current user
      // This will be handled by the AuthViewModel/UserRepository after login/registration
    }
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // You can show a local notification here using flutter_local_notifications
    }
  });

  // Handle background messages (when app is in background but not terminated)
  // Handle messages when the app is opened from a terminated state
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print(
        'App opened from terminated state with message: ${message.messageId}',
      );
      // Handle navigation or specific actions based on the notification
    }
  });

  // Handle messages when the app is terminated and opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from background with message: ${message.messageId}');
    // Handle navigation or specific actions based on the notification
  });

  setupDependencyInjection();
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
        title: 'Bitewise',
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
