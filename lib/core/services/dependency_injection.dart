import 'package:get_it/get_it.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/ai_food_repository.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/ai_food_service.dart';
import '../../data/services/local_food_database.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../presentation/viewmodels/scanner_viewmodel.dart';
import '../../presentation/viewmodels/nutrition_viewmodel.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';
import '../../presentation/viewmodels/notification_viewmodel.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Services
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());
  getIt.registerLazySingleton<AIFoodService>(() => AIFoodService());
  getIt.registerLazySingleton<LocalFoodDatabase>(() => LocalFoodDatabase());

  // Repositories
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
  getIt.registerLazySingleton<MealRepository>(() => MealRepository());
  getIt.registerLazySingleton<AIFoodRepository>(() => AIFoodRepository());
  getIt.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepository());

  // ViewModels
  getIt.registerFactory<AuthViewModel>(
    () => AuthViewModel(getIt<UserRepository>()),
  );
  getIt.registerFactory<HomeViewModel>(
    () => HomeViewModel(getIt<MealRepository>(), getIt<UserRepository>()),
  );
  getIt.registerFactory<ScannerViewModel>(
    () => ScannerViewModel(getIt<AIFoodRepository>(), getIt<MealRepository>()),
  );
  getIt.registerFactory<NutritionViewModel>(
    () => NutritionViewModel(getIt<MealRepository>()),
  );
  getIt.registerFactory<ProfileViewModel>(
    () => ProfileViewModel(getIt<UserRepository>()),
  );
}
