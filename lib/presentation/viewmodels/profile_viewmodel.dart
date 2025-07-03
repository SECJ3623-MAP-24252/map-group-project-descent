import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import 'base_viewmodel.dart';

class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  UserModel? _userData;
  UserModel? get userData => _userData;

  ProfileViewModel(this._userRepository);

  Future<void> loadUserData() async {
    setState(ViewState.busy);

    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        // In a real app, you'd fetch from Firestore
        _userData = UserModel(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName,
          photoURL: currentUser.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    File? imageFile,
  }) async {
    setState(ViewState.busy);

    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        String? finalPhotoURL = photoURL;

        // If an image file is provided, you would upload it to Firebase Storage here
        // For now, we'll just use the existing photoURL
        if (imageFile != null) {
          // TODO: Upload image to Firebase Storage and get URL
          // finalPhotoURL = await uploadImageToStorage(imageFile);
        }

        await _userRepository.updateUserProfile(
          currentUser.uid,
          displayName: displayName,
          photoURL: finalPhotoURL,
        );
        await loadUserData(); // Refresh user data
      }
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> signOut() async {
    setState(ViewState.busy);

    try {
      await _userRepository.signOut();
      _userData = null;
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  String getDisplayName() {
    if (_userData?.displayName != null && _userData!.displayName!.isNotEmpty) {
      return _userData!.displayName!;
    }
    return "User";
  }

  String getEmail() {
    return _userData?.email ?? "No email";
  }
}
