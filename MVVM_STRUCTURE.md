# MVVM Architecture Structure

This Flutter project has been restructured to follow the MVVM (Model-View-ViewModel) architecture pattern for better separation of concerns, testability, and maintainability.

## 📁 Project Structure

```
lib/
├── models/           # Data models
│   ├── user_model.dart
│   ├── food_model.dart
│   └── meal_model.dart
├── views/            # UI components (pages)
│   ├── home.dart
│   ├── login.dart
│   ├── register.dart
│   ├── profile.dart
│   ├── food_scanner.dart
│   ├── food_scan_results.dart
│   ├── daily_nutrition.dart
│   ├── edit_food.dart
│   ├── food_entry_detail.dart
│   └── forget.dart
├── viewmodels/       # Business logic and state management
│   ├── base_viewmodel.dart
│   ├── auth_viewmodel.dart
│   └── food_viewmodel.dart
├── services/         # Data services and API calls
│   ├── api_config.dart
│   ├── ai_food_service.dart
│   └── local_food_database.dart
├── utils/            # Utilities and helpers
│   └── constants.dart
└── main.dart
```

## 🏗️ Architecture Components

### **Models** (`lib/models/`)
- **UserModel**: Represents user data structure
- **FoodModel**: Represents food item data structure
- **MealModel**: Represents meal data structure

### **Views** (`lib/views/`)
- UI components that display data and handle user interactions
- Should be as simple as possible, containing only UI logic
- Use `Consumer<ViewModel>` to listen to ViewModel changes

### **ViewModels** (`lib/viewmodels/`)
- **BaseViewModel**: Abstract base class with common functionality
- **AuthViewModel**: Handles authentication logic and user state
- **FoodViewModel**: Handles food-related business logic and state

### **Services** (`lib/services/`)
- **APIConfig**: Manages API keys and configuration
- **AIFoodService**: Handles AI food recognition API calls
- **LocalFoodDatabase**: Manages local food database operations

### **Utils** (`lib/utils/`)
- **Constants**: App-wide constants and configuration

## 🔄 Data Flow

1. **View** → **ViewModel**: User interactions trigger ViewModel methods
2. **ViewModel** → **Service**: ViewModel calls services for data operations
3. **Service** → **Model**: Services return data as Model objects
4. **ViewModel** → **View**: ViewModel notifies View of state changes via `notifyListeners()`

## 📦 Dependencies

The project uses **Provider** for state management:
```yaml
provider: ^6.1.1
```

## 🚀 Usage Examples

### Using a ViewModel in a View:
```dart
class MyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: viewModel.items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(viewModel.items[index].name),
              onTap: () => viewModel.selectItem(index),
            );
          },
        );
      },
    );
  }
}
```

### Creating a new ViewModel:
```dart
class MyViewModel extends BaseViewModel {
  List<MyModel> _items = [];
  
  List<MyModel> get items => _items;
  
  Future<void> loadItems() async {
    setLoading(true);
    try {
      // Load data from service
      _items = await myService.getItems();
      notifyListeners();
    } catch (e) {
      setError('Failed to load items');
    } finally {
      setLoading(false);
    }
  }
}
```

## 🔧 Benefits of MVVM

1. **Separation of Concerns**: UI logic is separated from business logic
2. **Testability**: ViewModels can be easily unit tested
3. **Maintainability**: Clear structure makes code easier to maintain
4. **Reusability**: ViewModels can be reused across different Views
5. **State Management**: Centralized state management with Provider

## 📝 Next Steps

1. **Update existing Views**: Refactor existing pages to use ViewModels
2. **Add more ViewModels**: Create ViewModels for other features
3. **Implement Repository Pattern**: Add repository layer for data access
4. **Add Unit Tests**: Write tests for ViewModels and Services
5. **Add Error Handling**: Implement comprehensive error handling

## 🔗 Related Files

- `pubspec.yaml`: Dependencies configuration
- `lib/main.dart`: App initialization with Provider setup
- `lib/utils/constants.dart`: App constants and configuration 