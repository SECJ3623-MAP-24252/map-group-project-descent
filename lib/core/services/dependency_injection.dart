import 'package:get_it/get_it.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/ai_food_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../presentation/viewmodels/scanner_viewmodel.dart';
import '../../presentation/viewmodels/nutrition_viewmodel.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';
import '../../presentation/viewmodels/notification_viewmodel.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Services
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  getIt.registerSingleton<FirebaseService>(firebaseService);

  // Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Repositories
  getIt.registerLazySingleton<UserRepository>(() => UserRepository(getIt<FirebaseService>()));
  getIt.registerLazySingleton<MealRepository>(() => MealRepository(getIt<FirebaseService>()));
  getIt.registerLazySingleton<AIFoodRepository>(() => AIFoodRepository());
  getIt.registerLazySingleton<NotificationRepository>(() => NotificationRepository(getIt<FirebaseService>(), getIt<NotificationService>()));

  // ViewModels
  getIt.registerFactory<AuthViewModel>(() => AuthViewModel(getIt<UserRepository>()));
  getIt.registerFactory<HomeViewModel>(() => HomeViewModel(getIt<MealRepository>()));
  getIt.registerFactory<ScannerViewModel>(() => ScannerViewModel(getIt<AIFoodRepository>(), getIt<MealRepository>()));
  getIt.registerFactory<NutritionViewModel>(() => NutritionViewModel(getIt<MealRepository>(), getIt<NotificationViewModel>()));
  getIt.registerFactory<ProfileViewModel>(() => ProfileViewModel(getIt<UserRepository>()));
  getIt.registerFactory<NotificationViewModel>(() => NotificationViewModel(getIt<NotificationRepository>(), getIt<MealRepository>(), getIt<UserRepository>()));
}
