import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/ai_food_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/models/meal_model.dart';
import 'base_viewmodel.dart';

class ScannerViewModel extends BaseViewModel {
  final AIFoodRepository _aiFoodRepository;
  final MealRepository _mealRepository;
  final ImagePicker _imagePicker = ImagePicker();
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String _scanningStatus = '';
  Map<String, dynamic>? _scanResults;
  bool _isFlashOn = false;

  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  String get scanningStatus => _scanningStatus;
  Map<String, dynamic>? get scanResults => _scanResults;
  bool get isFlashOn => _isFlashOn;

  ScannerViewModel(this._aiFoodRepository, this._mealRepository);

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        _isCameraInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      setError('Camera initialization failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> captureAndAnalyze() async {
    if (!_isCameraInitialized || isBusy) return null;

    setState(ViewState.busy);
    _updateScanningStatus('Capturing image...');

    try {
      final XFile image = await _cameraController!.takePicture();
      final result = await _analyzeFood(File(image.path));
      return {
        'imageFile': File(image.path),
        'nutritionData': result,
      };
    } catch (e) {
      setError('Failed to capture image: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> pickFromGallery() async {
    if (isBusy) return null;

    setState(ViewState.busy);
    _updateScanningStatus('Loading image...');

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final result = await _analyzeFood(File(image.path));
        return {
          'imageFile': File(image.path),
          'nutritionData': result,
        };
      } else {
        setState(ViewState.idle);
        _updateScanningStatus('');
        return null;
      }
    } catch (e) {
      setError('Failed to pick image: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>> _analyzeFood(File imageFile) async {
    try {
      _updateScanningStatus('Analyzing with AI...');
      
      final results = await _aiFoodRepository.analyzeFoodImage(imageFile);
      
      _scanResults = results;
      setState(ViewState.idle);
      _updateScanningStatus('');
      return results;
    } catch (e) {
      setError('Failed to analyze food: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> saveMealFromScan({
    required String userId,
    required Map<String, dynamic> nutritionData,
    required String mealType,
    required File imageFile,
  }) async {
    try {
      setState(ViewState.busy);
      
      final nutrition = nutritionData['nutrition'] ?? {};
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      // Convert ingredients from scan results to IngredientModel list
      List<IngredientModel>? ingredientsList;
      if (nutritionData['ingredients'] != null) {
        final ingredientsData = nutritionData['ingredients'] as List;
        ingredientsList = ingredientsData.map((ing) {
          return IngredientModel(
            name: ing['name'] ?? 'Unknown',
            weight: ing['weight'] ?? '0g',
            calories: (ing['calories'] ?? 0).toInt(),
            protein: ing['protein']?.toDouble(),
            carbs: ing['carbs']?.toDouble(),
            fat: ing['fat']?.toDouble(),
          );
        }).toList();
        
        print('Converted ${ingredientsList.length} ingredients for storage');
      }
      
      final meal = MealModel(
        id: '',
        userId: userId,
        name: nutritionData['food_name'] ?? 'Unknown Food',
        description: nutritionData['description'],
        calories: (nutrition['calories'] ?? 0).toDouble(),
        protein: (nutrition['protein'] ?? 0).toDouble(),
        carbs: (nutrition['carbs'] ?? 0).toDouble(),
        fat: (nutrition['fat'] ?? 0).toDouble(),
        timestamp: DateTime.now(),
        mealType: mealType,
        imageUrl: base64Image,
        ingredients: ingredientsList,
        scanSource: 'ai_scan',
      );

      await _mealRepository.createMeal(meal);
      print('Meal saved successfully with ${ingredientsList?.length ?? 0} ingredients');
      setState(ViewState.idle);
    } catch (e) {
      setError('Failed to save meal: ${e.toString()}');
    }
  }

  Future<void> toggleFlash() async {
    if (_cameraController != null && _isCameraInitialized) {
      try {
        final FlashMode newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(newFlashMode);
        _isFlashOn = !_isFlashOn;
        notifyListeners();
      } catch (e) {
        // Flash toggle failed, ignore silently
      }
    }
  }

  void _updateScanningStatus(String status) {
    _scanningStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
