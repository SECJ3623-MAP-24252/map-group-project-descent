import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'local_food_database.dart';

class AIFoodService {
  /// Main method to analyze food image using AI services
  static Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Try Spoonacular first for both recognition and nutrition
      try {
        if (APIConfig.hasApiKey('spoonacular')) {
          final spoonacularResult = await _analyzeFoodWithSpoonacular(
            imageFile,
          );
          if (spoonacularResult != null) {
            return spoonacularResult;
          }
        }
      } catch (e) {
        print('Spoonacular analysis failed: $e');
      }

      // Try Clarifai for food recognition
      try {
        if (APIConfig.hasApiKey('clarifai')) {
          final clarifaiResult = await _analyzeFoodWithClarifai(base64Image);
          if (clarifaiResult != null) {
            // Get nutrition data from Spoonacular using the food name
            final nutritionData = await _getNutritionFromSpoonacular(
              clarifaiResult['food_name'],
            );
            return _combineResults(clarifaiResult, nutritionData);
          }
        }
      } catch (e) {
        print('Clarifai analysis failed: $e');
      }

      // If all AI services fail, return a default response
      return _getDefaultResponse();
    } catch (e) {
      throw Exception('Failed to analyze food image: $e');
    }
  }

  /// Analyze food using Spoonacular's image recognition API
  static Future<Map<String, dynamic>?> _analyzeFoodWithSpoonacular(
    File imageFile,
  ) async {
    final apiKey = APIConfig.getApiKey('spoonacular');
    if (apiKey == null) return null;

    final uri = Uri.parse('https://api.spoonacular.com/food/images/analyze');

    // Create multipart request
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['x-api-key'] = apiKey
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);

      if (data['category'] != null && data['nutrition'] != null) {
        // Extract the most relevant food name
        String foodName = data['category']['name'];

        // If there are annotations, use the most confident one
        if (data['annotations'] != null && data['annotations'].isNotEmpty) {
          final annotations = data['annotations'] as List;
          if (annotations.isNotEmpty) {
            foodName = annotations.first['annotation'];
          }
        }

        // Extract nutrition data
        final nutrition = data['nutrition'];
        final calories =
            nutrition['calories'] != null
                ? nutrition['calories']['value'] ?? 0.0
                : 0.0;

        // Extract nutrients
        final nutrients = nutrition['nutrients'] as List;
        double protein = 0.0, carbs = 0.0, fat = 0.0, fiber = 0.0, sugar = 0.0;

        for (final nutrient in nutrients) {
          final name = nutrient['name'].toString().toLowerCase();
          final value = nutrient['amount'] ?? 0.0;

          if (name.contains('protein'))
            protein = value;
          else if (name.contains('carbohydrates'))
            carbs = value;
          else if (name.contains('fat'))
            fat = value;
          else if (name.contains('fiber'))
            fiber = value;
          else if (name.contains('sugar'))
            sugar = value;
        }

        return {
          'food_name': _cleanFoodName(foodName),
          'confidence': 0.85, // Spoonacular doesn't provide confidence scores
          'source': 'spoonacular',
          'nutrition': {
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'fiber': fiber,
            'sugar': sugar,
          },
          'serving_size': '100g',
          'ingredients': [foodName],
        };
      }
    }
    return null;
  }

  /// Analyze food using Clarifai Food Model
  static Future<Map<String, dynamic>?> _analyzeFoodWithClarifai(
    String base64Image,
  ) async {
    final apiKey = APIConfig.getApiKey('clarifai');
    if (apiKey == null) return null;

    const String url =
        'https://api.clarifai.com/v2/models/food-item-recognition/outputs';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Key $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': [
          {
            'data': {
              'image': {'base64': base64Image},
            },
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final concepts = data['outputs'][0]['data']['concepts'] as List;

      if (concepts.isNotEmpty) {
        final topConcept = concepts.first;
        return {
          'food_name': _cleanFoodName(topConcept['name']),
          'confidence': topConcept['value'],
          'source': 'clarifai',
          'raw_concepts':
              concepts
                  .take(5)
                  .map((c) => {'name': c['name'], 'confidence': c['value']})
                  .toList(),
        };
      }
    }
    return null;
  }

  /// Get nutrition information from Spoonacular using food name
  static Future<Map<String, dynamic>?> _getNutritionFromSpoonacular(
    String foodName,
  ) async {
    final apiKey = APIConfig.getApiKey('spoonacular');
    if (apiKey == null) {
      // Try local database if API key is not available
      return LocalFoodDatabase.searchFood(foodName);
    }

    final encodedQuery = Uri.encodeComponent(foodName);
    final uri = Uri.parse(
      'https://api.spoonacular.com/recipes/guessNutrition?title=$encodedQuery&apiKey=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if we got valid nutrition data
      if (data['calories'] != null && data['calories']['value'] != null) {
        return {
          'calories': data['calories']['value']?.toDouble() ?? 0.0,
          'protein': data['protein']['value']?.toDouble() ?? 0.0,
          'carbs': data['carbs']['value']?.toDouble() ?? 0.0,
          'fat': data['fat']['value']?.toDouble() ?? 0.0,
          'serving_weight': 100.0,
          'serving_description': '100g',
        };
      }

      // If guessNutrition fails, try searching for the food
      return await _searchFoodNutrition(foodName);
    }

    // Try local database as fallback
    return LocalFoodDatabase.searchFood(foodName);
  }

  /// Search for food nutrition using Spoonacular search API
  static Future<Map<String, dynamic>?> _searchFoodNutrition(
    String foodName,
  ) async {
    final apiKey = APIConfig.getApiKey('spoonacular');
    if (apiKey == null) return null;

    final encodedQuery = Uri.encodeComponent(foodName);
    final uri = Uri.parse(
      'https://api.spoonacular.com/food/ingredients/search?query=$encodedQuery&number=1&apiKey=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;

      if (results.isNotEmpty) {
        final ingredientId = results.first['id'];

        // Get nutrition data for this ingredient
        final nutritionUri = Uri.parse(
          'https://api.spoonacular.com/food/ingredients/$ingredientId/information?amount=100&unit=grams&apiKey=$apiKey',
        );

        final nutritionResponse = await http.get(nutritionUri);

        if (nutritionResponse.statusCode == 200) {
          final nutritionData = jsonDecode(nutritionResponse.body);
          final nutrients = nutritionData['nutrition']['nutrients'] as List;

          double calories = 0.0,
              protein = 0.0,
              carbs = 0.0,
              fat = 0.0,
              fiber = 0.0,
              sugar = 0.0;

          for (final nutrient in nutrients) {
            final name = nutrient['name'].toString().toLowerCase();
            final value = nutrient['amount'] ?? 0.0;

            if (name.contains('calories'))
              calories = value;
            else if (name.contains('protein'))
              protein = value;
            else if (name.contains('carbohydrates'))
              carbs = value;
            else if (name.contains('fat'))
              fat = value;
            else if (name.contains('fiber'))
              fiber = value;
            else if (name.contains('sugar'))
              sugar = value;
          }

          return {
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'fiber': fiber,
            'sugar': sugar,
            'serving_weight': 100.0,
            'serving_description': '100g',
          };
        }
      }
    }

    // Try local database as fallback
    return LocalFoodDatabase.searchFood(foodName);
  }

  /// Combine AI recognition results with nutrition data
  static Map<String, dynamic> _combineResults(
    Map<String, dynamic> aiResult,
    Map<String, dynamic>? nutritionData,
  ) {
    // Default to 100g if no weight is provided
    final estimatedWeight = 100.0;
    final servingWeight = nutritionData?['serving_weight'] ?? 100.0;
    final weightRatio = estimatedWeight / servingWeight;

    return {
      'food_name': aiResult['food_name'],
      'confidence': aiResult['confidence'],
      'source': aiResult['source'],
      'nutrition':
          nutritionData != null
              ? {
                'calories': (nutritionData['calories'] * weightRatio).round(),
                'protein': double.parse(
                  (nutritionData['protein'] * weightRatio).toStringAsFixed(1),
                ),
                'carbs': double.parse(
                  (nutritionData['carbs'] * weightRatio).toStringAsFixed(1),
                ),
                'fat': double.parse(
                  (nutritionData['fat'] * weightRatio).toStringAsFixed(1),
                ),
                'fiber':
                    nutritionData['fiber'] != null
                        ? double.parse(
                          (nutritionData['fiber'] * weightRatio)
                              .toStringAsFixed(1),
                        )
                        : 0.0,
                'sugar':
                    nutritionData['sugar'] != null
                        ? double.parse(
                          (nutritionData['sugar'] * weightRatio)
                              .toStringAsFixed(1),
                        )
                        : 0.0,
              }
              : _getDefaultNutrition(),
      'ingredients': [aiResult['food_name']],
      'serving_size': '${estimatedWeight.round()}g',
      'raw_data': aiResult,
    };
  }

  /// Clean and standardize food names
  static String _cleanFoodName(String rawName) {
    return rawName
        .toLowerCase()
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ')
        .replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Default nutrition values when API fails
  static Map<String, dynamic> _getDefaultNutrition() {
    return {
      'calories': 150,
      'protein': 5.0,
      'carbs': 20.0,
      'fat': 8.0,
      'fiber': 3.0,
      'sugar': 5.0,
    };
  }

  /// Default response when all AI services fail
  static Map<String, dynamic> _getDefaultResponse() {
    return {
      'food_name': 'Unknown Food Item',
      'confidence': 0.5,
      'source': 'default',
      'nutrition': _getDefaultNutrition(),
      'ingredients': ['Unknown'],
      'serving_size': '100g',
      'description': 'Could not identify food item. Please edit manually.',
    };
  }
}
