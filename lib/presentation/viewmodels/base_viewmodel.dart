import 'package:flutter/foundation.dart';

enum ViewState { idle, busy, error }

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  bool get isBusy => _state == ViewState.busy;
  bool get hasError => _state == ViewState.error;

  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_state == ViewState.error) {
      _state = ViewState.idle;
      notifyListeners();
    }
  }
}
