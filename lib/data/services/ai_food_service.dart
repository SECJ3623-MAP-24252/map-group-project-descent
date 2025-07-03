import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'local_food_database.dart';

class AIFoodService {
  /// Main method to analyze food image using Gemini + CalorieNinjas
  static Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      // Step 1: Use Gemini to analyze the image and extract ingredients
      final ingredientsString = await _analyzeImageWithGemini(imageFile);

      if (ingredientsString != null && ingredientsString.isNotEmpty) {
        print('Successfully extracted ingredients: $ingredientsString');

        // Step 2: Use CalorieNinjas to get nutrition data for the ingredients
        final nutritionData = await _getNutritionFromCalorieNinjas(
          ingredientsString,
        );

        if (nutritionData != null) {
          return nutritionData;
        }
      } else {
        print('Failed to extract ingredients from image');
      }

      // If AI services fail, return a default response
      return _getDefaultResponse();
    } catch (e) {
      print('Error in analyzeFoodImage: $e');
      return _getDefaultResponse();
    }
  }

  /// Analyze food image using Gemini 1.5 Flash API
  static Future<String?> _analyzeImageWithGemini(File imageFile) async {
    try {
      final apiKey = APIConfig.getApiKey('gemini');
      if (apiKey == null || apiKey.isEmpty) {
        print('Gemini API key not configured');
        return null;
      }

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Updated Gemini API endpoint for 1.5 Flash model
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final prompt =
          '''Analyze the provided image for individual food items. If a composite dish (e.g., cheeseburger, pizza slice) is identified, break it down into its distinct, base ingredients. For each identified food item or base ingredient, estimate its weight in grams (g). Convert any liquid volume measurements (e.g., ml, tablespoons), piece measurements, or unspecified units to grams. Provide its specific name. List all identified items and their estimated weights in a single, comma-separated string, formatted as 'WEIGHTg INGREDIENT_NAME', with no additional text, descriptions, or calorie counts. Do not include any ambiguous or vague terms.

Example Input:
(Image of a hamburger: bun, patty, cheese, lettuce, tomato, ketchup, mayonnaise)

Expected API Output Format:
70g Bun, 90g Beef Patty, 18g Processed Cheese, 8g Iceberg Lettuce, 20g Tomato, 15g Ketchup, 5g Mayonnaise''';

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.1,
          "topK": 32,
          "topP": 1,
          "maxOutputTokens": 4096,
        },
      };

      print('Sending request to Gemini API...');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Gemini response status: ${response.statusCode}');
      print('Gemini response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data is Map<String, dynamic> &&
            data['candidates'] != null &&
            data['candidates'] is List &&
            data['candidates'].isNotEmpty) {
          final candidates = data['candidates'] as List;
          final firstCandidate = candidates[0];

          if (firstCandidate is Map<String, dynamic> &&
              firstCandidate['content'] != null &&
              firstCandidate['content'] is Map<String, dynamic>) {
            final content = firstCandidate['content'] as Map<String, dynamic>;

            if (content['parts'] != null &&
                content['parts'] is List &&
                content['parts'].isNotEmpty) {
              final parts = content['parts'] as List;
              final firstPart = parts[0];

              if (firstPart is Map<String, dynamic> &&
                  firstPart['text'] != null) {
                final ingredientsText = firstPart['text'].toString().trim();
                print('Gemini extracted ingredients: $ingredientsText');
                return ingredientsText;
              }
            }
          }
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in _analyzeImageWithGemini: $e');
    }
    return null;
  }

  /// Get nutrition data from CalorieNinjas API
  static Future<Map<String, dynamic>?> _getNutritionFromCalorieNinjas(
    String ingredientsString,
  ) async {
    try {
      final apiKey = APIConfig.getApiKey('calorieninjas');
      if (apiKey == null || apiKey.isEmpty) {
        print('CalorieNinjas API key not configured');
        return _tryLocalDatabase(ingredientsString);
      }

      final uri = Uri.parse('https://api.calorieninjas.com/v1/nutrition');

      print('Sending request to CalorieNinjas API with query: $ingredientsString');
      final response = await http.get(
        uri.replace(queryParameters: {'query': ingredientsString}),
        headers: {'X-Api-Key': apiKey},
      );

      print('CalorieNinjas response status: ${response.statusCode}');
      print('CalorieNinjas response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('CalorieNinjas full response received with ${data['items']?.length ?? 0} items');

        if (data != null &&
            data is Map<String, dynamic> &&
            data['items'] != null &&
            data['items'] is List) {
          final items = data['items'] as List;

          if (items.isNotEmpty) {
            return _processCalorieNinjasResponse(items, ingredientsString);
          } else {
            print('CalorieNinjas returned empty items list');
          }
        }
      } else {
        print('CalorieNinjas API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in _getNutritionFromCalorieNinjas: $e');
    }

    // Try local database as fallback
    return _tryLocalDatabase(ingredientsString);
  }

  /// Process CalorieNinjas API response and combine nutrition data
  static Map<String, dynamic> _processCalorieNinjasResponse(
    List items,
    String originalQuery,
  ) {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;
    double totalSodium = 0.0;
    double totalWeight = 0.0;

    List<Map<String, dynamic>> ingredients = [];
    String mainFoodName = 'Mixed Food Items';

    print('Processing ${items.length} items from CalorieNinjas response');

    // Extract main food name from the first item or original query
    if (items.isNotEmpty) {
      final firstItem = items[0];
      if (firstItem is Map<String, dynamic> && firstItem['name'] != null) {
        mainFoodName = _cleanFoodName(firstItem['name'].toString());

        // If multiple items, make it more descriptive
        if (items.length > 1) {
          mainFoodName =
              '$mainFoodName and ${items.length - 1} other ingredient${items.length > 2 ? 's' : ''}';
        }
      }
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is Map<String, dynamic>) {
        // Extract core nutrition data
        final calories = _parseDouble(item['calories']);
        final protein = _parseDouble(item['protein_g']);
        final carbs = _parseDouble(item['carbohydrates_total_g']);
        final fat = _parseDouble(item['fat_total_g']);
        final fiber = _parseDouble(item['fiber_g']);
        final sugar = _parseDouble(item['sugar_g']);
        final sodium = _parseDouble(item['sodium_mg']) / 1000; // Convert mg to g
        final weight = _parseDouble(item['serving_size_g']);
        final name = _cleanFoodName(item['name']?.toString() ?? 'Unknown');

        // Add to totals
        totalCalories += calories;
        totalProtein += protein;
        totalCarbs += carbs;
        totalFat += fat;
        totalFiber += fiber;
        totalSugar += sugar;
        totalSodium += sodium;
        totalWeight += weight;

        // Create clean ingredient entry
        ingredients.add({
          'name': name,
          'weight': '${weight.round()}g',
          'calories': calories.round(),
          'protein': double.parse(protein.toStringAsFixed(1)),
          'carbs': double.parse(carbs.toStringAsFixed(1)),
          'fat': double.parse(fat.toStringAsFixed(1)),
          'serving_size_g': weight.round(),
        });

        print('Processed ingredient ${i + 1}: $name - ${calories.round()} cal, ${weight.round()}g');
      }
    }

    final result = {
      'food_name': mainFoodName,
      'confidence': 0.85, // High confidence since we have detailed breakdown
      'source': 'gemini_calorieninjas',
      'nutrition': {
        'calories': totalCalories.round(),
        'protein': double.parse(totalProtein.toStringAsFixed(1)),
        'carbs': double.parse(totalCarbs.toStringAsFixed(1)),
        'fat': double.parse(totalFat.toStringAsFixed(1)),
        'fiber': double.parse(totalFiber.toStringAsFixed(1)),
        'sugar': double.parse(totalSugar.toStringAsFixed(1)),
        'sodium': double.parse(totalSodium.toStringAsFixed(2)),
      },
      'ingredients': ingredients,
      'serving_size': '${totalWeight.round()}g',
      'detailed_breakdown': items, // Keep full response for debugging
      'original_query': originalQuery,
    };

    print('Final nutrition summary: ${totalCalories.round()} cal, ${totalProtein.toStringAsFixed(1)}g protein, ${totalCarbs.toStringAsFixed(1)}g carbs, ${totalFat.toStringAsFixed(1)}g fat');
    print('Total ingredients processed: ${ingredients.length}');

    return result;
  }

  /// Try to get nutrition from local database as fallback
  static Map<String, dynamic>? _tryLocalDatabase(String ingredientsString) {
    try {
      print('Trying local database with: $ingredientsString');
      // Extract the first ingredient from the string for local lookup
      final firstIngredient = ingredientsString.split(',').first.trim();
      final ingredientName =
          firstIngredient.replaceAll(RegExp(r'\d+g\s*'), '').trim();

      final localData = LocalFoodDatabase.searchFood(ingredientName);
      if (localData != null) {
        return {
          'food_name': _cleanFoodName(ingredientName),
          'confidence': 0.6,
          'source': 'local_database',
          'nutrition': {
            'calories': localData['calories'],
            'protein': localData['protein'],
            'carbs': localData['carbs'],
            'fat': localData['fat'],
            'fiber': localData['fiber'] ?? 0.0,
            'sugar': localData['sugar'] ?? 0.0,
            'sodium': 0.0,
          },
          'ingredients': [
            {
              'name': ingredientName,
              'weight': '100g',
              'calories': localData['calories'],
              'protein': localData['protein'],
              'carbs': localData['carbs'],
              'fat': localData['fat'],
              'serving_size_g': 100,
            },
          ],
          'serving_size': localData['serving_size'] ?? '100g',
        };
      } else {
        print('No match found in local database for: $ingredientName');
      }
    } catch (e) {
      print('Error in _tryLocalDatabase: $e');
    }
    return null;
  }

  /// Safely parse a value to double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Clean and standardize food names
  static String _cleanFoodName(String rawName) {
    if (rawName.isEmpty) return 'Unknown Food';

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

  /// Default nutrition values when all services fail
  static Map<String, dynamic> _getDefaultNutrition() {
    return {
      'calories': 150,
      'protein': 5.0,
      'carbs': 20.0,
      'fat': 8.0,
      'fiber': 3.0,
      'sugar': 5.0,
      'sodium': 0.2,
    };
  }

  /// Default response when all AI services fail
  static Map<String, dynamic> _getDefaultResponse() {
    return {
      'food_name': 'Unknown Food Item',
      'confidence': 0.5,
      'source': 'default',
      'nutrition': _getDefaultNutrition(),
      'ingredients': [
        {
          'name': 'Unknown',
          'weight': '100g',
          'calories': 150,
          'protein': 5.0,
          'carbs': 20.0,
          'fat': 8.0,
          'serving_size_g': 100,
        },
      ],
      'serving_size': '100g',
      'description': 'Could not identify food item. Please edit manually.',
    };
  }
}
