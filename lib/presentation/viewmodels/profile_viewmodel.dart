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

        // Calculate days active (days with at least one meal)
        final mealsQuery =
            await firestore
                .collection('meals')
                .where('userId', isEqualTo: currentUser.uid)
                .get();

        final uniqueDays = <String>{};
        int foodsScanned = 0;

        for (final doc in mealsQuery.docs) {
          final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
          final dayKey =
              '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          uniqueDays.add(dayKey);

          // Count foods that were scanned (have imageUrl or source indicates scanning)
          final data = doc.data();
          if (data['imageUrl'] != null ||
              (data['description'] != null &&
                  data['description'].toString().contains('Scanned'))) {
            foodsScanned++;
          }
        }

        _userStats = {
          'daysActive': uniqueDays.length,
          'foodsScanned': foodsScanned,
        };

        notifyListeners();
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
