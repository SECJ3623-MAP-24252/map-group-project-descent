import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/validators.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  
  bool get isLoggedIn => _currentUser != null;

  AuthViewModel(this._userRepository) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _userRepository.authStateChanges.listen((user) async {
      if (user != null) {
        // User is signed in, fetch user data
        try {
          _currentUser = await _userRepository.getUserData(user.uid);
          if (_currentUser == null) {
            // Create user document if it doesn't exist
            _currentUser = UserModel(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoURL: user.photoURL,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            );
            await _userRepository.createUserDocument(_currentUser!);
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool> checkAuthState() async {
    try {
      final user = _userRepository.currentUser;
      if (user != null) {
        // Always fetch fresh user data from Firestore
        _currentUser = await _userRepository.getUserData(user.uid);
        notifyListeners(); // Ensure UI updates with fresh data
        return _currentUser != null;
      }
      return false;
    } catch (e) {
      print('Error checking auth state: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    setState(ViewState.busy);
    
    try {
      final user = await _userRepository.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        setState(ViewState.idle);
        return true;
      } else {
        setError('Login failed');
        return false;
      }
    } catch (e) {
      setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    setState(ViewState.busy);
    
    try {
      final user = await _userRepository.registerWithEmail(email, password, displayName);
      if (user != null) {
        _currentUser = user;
        setState(ViewState.idle);
        return true;
      } else {
        setError('Registration failed');
        return false;
      }
    } catch (e) {
      setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    setState(ViewState.busy);
    
    try {
      await _userRepository.signOut();
      _currentUser = null;
      setState(ViewState.idle);
    } catch (e) {
      setError(_getErrorMessage(e));
    }
  }

  Future<bool> resetPassword(String email) async {
    setState(ViewState.busy);
    
    try {
      await _userRepository.resetPassword(email);
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setError(_getErrorMessage(e));
      return false;
    }
  }

  // Method to refresh user data manually
  Future<void> refreshUserData() async {
    try {
      final user = _userRepository.currentUser;
      if (user != null) {
        _currentUser = await _userRepository.getUserData(user.uid);
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return error.toString();
  }

  // Form validation
  String? validateEmail(String? email) => Validators.validateEmail(email);
  String? validatePassword(String? password) => Validators.validatePassword(password);
  String? validateDisplayName(String? name) => Validators.validateDisplayName(name);
}
