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

/// A service locator for the application.
final GetIt getIt = GetIt.instance;

/// Sets up the dependency injection for the application.
Future<void> setupDependencyInjection() async {
  // Services
  // Registers the [FirebaseService] as a lazy singleton.
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());
  // Registers the [AIFoodService] as a lazy singleton.
  getIt.registerLazySingleton<AIFoodService>(() => AIFoodService());
  // Registers the [LocalFoodDatabase] as a lazy singleton.
  getIt.registerLazySingleton<LocalFoodDatabase>(() => LocalFoodDatabase());

  // Repositories
  // Registers the [UserRepository] as a lazy singleton.
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
  // Registers the [MealRepository] as a lazy singleton.
  getIt.registerLazySingleton<MealRepository>(() => MealRepository());
  // Registers the [AIFoodRepository] as a lazy singleton.
  getIt.registerLazySingleton<AIFoodRepository>(() => AIFoodRepository());
  // Registers the [AnalyticsRepository] as a lazy singleton.
  getIt.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepository());

  // ViewModels
  // Registers the [AuthViewModel] as a factory.
  getIt.registerFactory<AuthViewModel>(
    () => AuthViewModel(getIt<UserRepository>()),
  );
  // Registers the [HomeViewModel] as a factory.
  getIt.registerFactory<HomeViewModel>(
    () => HomeViewModel(getIt<MealRepository>(), getIt<UserRepository>()),
  );
  // Registers the [ScannerViewModel] as a factory.
  getIt.registerFactory<ScannerViewModel>(
    () => ScannerViewModel(getIt<AIFoodRepository>(), getIt<MealRepository>()),
  );
  // Registers the [NutritionViewModel] as a factory.
  getIt.registerFactory<NutritionViewModel>(
    () => NutritionViewModel(getIt<MealRepository>()),
  );
  // Registers the [ProfileViewModel] as a factory.
  getIt.registerFactory<ProfileViewModel>(
    () => ProfileViewModel(getIt<UserRepository>()),
  );
}