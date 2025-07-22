import 'package:flutter/foundation.dart';

/// An enumeration of the possible states of a view.
enum ViewState { idle, busy, error }

/// A base class for all view models.
class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  /// The current state of the view.
  ViewState get state => _state;
  /// The error message, if any.
  String get errorMessage => _errorMessage;

  /// Whether the view is currently busy.
  bool get isBusy => _state == ViewState.busy;
  /// Whether the view has an error.
  bool get hasError => _state == ViewState.error;

  /// Sets the state of the view.
  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Sets the error message for the view.
  void setError(String message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }

  /// Clears the error message for the view.
  void clearError() {
    _errorMessage = '';
    if (_state == ViewState.error) {
      _state = ViewState.idle;
      notifyListeners();
    }
  }
}