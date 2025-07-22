/// This class is used to configure the API keys for the various services used in the application.
class APIConfig {
  // In production, these should come from environment variables or Firebase Remote Config
  static const Map<String, String> _apiKeys = {
    // Gemini API Key (Free tier: 60 requests per minute)
    'gemini': 'AIzaSyChHdtVxWif6fi5w3v_2iAj-AKVFuXJmhM',

    // CalorieNinjas API Key (Free tier: 100,000 requests/month)
    'calorieninjas': 'nP9c+cyCj0xibU1VbFktEA==uE2FWPbXEArOYZG1',
  };

  /// Gets the API key for the specified service.
  ///
  /// The [service] is the name of the service for which to get the API key.
  ///
  /// Returns the API key for the specified service, or null if the service is not found.
  static String? getApiKey(String service) {
    try {
      return _apiKeys[service];
    } catch (e) {
      print('Error getting API key for $service: $e');
      return null;
    }
  }

  /// Checks if an API key is available for the specified service.
  ///
  /// The [service] is the name of the service for which to check for an API key.
  ///
  /// Returns true if an API key is available for the specified service, otherwise returns false.
  static bool hasApiKey(String service) {
    try {
      final key = _apiKeys[service];
      return key != null &&
          key.isNotEmpty &&
          !key.startsWith('YOUR_') &&
          key.length > 10; // Basic validation
    } catch (e) {
      print('Error checking API key for $service: $e');
      return false;
    }
  }

  /// Check which AI services are available
  ///
  /// Returns a list of the available AI services.
  static List<String> getAvailableServices() {
    final available = <String>[];

    try {
      if (hasApiKey('gemini')) available.add('gemini');
      if (hasApiKey('calorieninjas')) available.add('calorieninjas');
    } catch (e) {
      print('Error getting available services: $e');
    }

    return available;
  }
}