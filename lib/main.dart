/// This is the main entry point of the application.
/// It initializes Firebase, sets up dependency injection, and runs the app.
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

/// This function handles background messages from Firebase Cloud Messaging.
/// It is a top-level function to ensure it can be accessed by the Firebase plugin.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if it hasn't been already.
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  // You can perform heavy data processing here if needed.
}

/// The main function of the application.
void main() async {
  // Ensure that the Flutter binding is initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase.
  tz.initializeTimeZones();
  await Firebase.initializeApp();

  // Set up the background message handler for Firebase Messaging.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission for notifications on iOS and web.
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

  // Get the FCM token and print it to the console.
  // This token can be used to send push notifications to this specific device.
  FirebaseMessaging.instance.getToken().then((token) {
    if (token != null) {
      print('FCM Token: $token');
      // You might want to save this token to your database for the current user.
      // This will be handled by the AuthViewModel/UserRepository after login/registration.
    }
  });

  // Listen for incoming messages when the app is in the foreground.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // You can show a local notification here using flutter_local_notifications.
    }
  });

  // Handle messages when the app is opened from a terminated state.
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print(
        'App opened from terminated state with message: ${message.messageId}',
      );
      // Handle navigation or specific actions based on the notification.
    }
  });

  // Handle messages when the app is in the background and opened from a notification.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from background with message: ${message.messageId}');
    // Handle navigation or specific actions based on the notification.
  });

  // Set up the dependency injection container.
  setupDependencyInjection();
  // Run the app.
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates a new instance of the MyApp widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide the view models to the widget tree.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<HomeViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<ScannerViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<NutritionViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<ProfileViewModel>()),
      ],
      // The MaterialApp widget is the root of the app's UI.
      child: MaterialApp(
        title: 'Bitewise',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // The splash screen is the first screen that is shown to the user.
        home: const SplashScreen(),
        // The onGenerateRoute callback is used to handle named routes.
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
