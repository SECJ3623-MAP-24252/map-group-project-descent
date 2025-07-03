import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firebase_service.dart';
import 'base_viewmodel.dart';

class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  UserModel? _userData;
  Map<String, int> _userStats = {};

  UserModel? get userData => _userData;
  Map<String, int> get userStats => _userStats;

  ProfileViewModel(this._userRepository);

  Future<void> loadUserData() async {
    setState(ViewState.busy);

    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        _userData = await _userRepository.getUserData(currentUser.uid);
        notifyListeners(); // Ensure UI updates
      }
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> loadUserStats() async {
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        final firestore = FirebaseFirestore.instance;

        // Get user document to access creation timestamp
        final userDoc =
            await firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final creationTimestamp = userDoc.data()?['createdAt'] as Timestamp?;

          if (creationTimestamp != null) {
            // Calculate days active from account creation
            int daysActive = 0;
            if (_userData?.createdAt != null) {
              final now = DateTime.now();
              final createdAt = _userData!.createdAt;
              daysActive = now.difference(createdAt).inDays;
            }

            int foodsScanned = 0;

            final mealsQuery =
                await firestore
                    .collection('meals')
                    .where('userId', isEqualTo: currentUser.uid)
                    .get();

            for (final doc in mealsQuery.docs) {
              final data = doc.data();
              if (data['imageUrl'] != null ||
                  (data['description'] != null &&
                      data['description'].toString().contains('Scanned'))) {
                foodsScanned++;
              }
            }

            _userStats = {
              'daysActive': daysActive,
              'foodsScanned': foodsScanned,
            };

            notifyListeners();
          } else {
            print('User creation timestamp not found.');
            _userStats = {'daysActive': 0, 'foodsScanned': 0};
          }
        } else {
          print('User document not found.');
          _userStats = {'daysActive': 0, 'foodsScanned': 0};
        }
      }
    } catch (e) {
      print('Error loading user stats: $e');
      _userStats = {'daysActive': 0, 'foodsScanned': 0};
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
        await _userRepository.updateUserProfile(
          currentUser.uid,
          displayName: displayName,
          imageFile: imageFile,
        );

        // Reload user data to get the updated profile
        await loadUserData();
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
      _userStats = {};
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
