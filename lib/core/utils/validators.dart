/// This class contains validator methods for text fields.
class Validators {
  /// Validates an email address.
  ///
  /// Returns an error message if the email is invalid, otherwise returns null.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email';
    }
    // This regex checks for a valid email format.
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates a password.
  ///
  /// Returns an error message if the password is invalid, otherwise returns null.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter your password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates a display name.
  ///
  /// Returns an error message if the display name is invalid, otherwise returns null.
  static String? validateDisplayName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  /// Validates that a value is not empty.
  ///
  /// Returns an error message if the value is empty, otherwise returns null.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }
}