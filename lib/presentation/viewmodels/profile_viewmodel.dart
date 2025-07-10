import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/analytics_repository.dart';
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
        notifyListeners();
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

        final userDoc =
            await firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final creationTimestamp =
              userDoc.data()?['createdAt'] as Timestamp?;

          if (creationTimestamp != null) {
            final creationDate = creationTimestamp.toDate();
            final now = DateTime.now();
            final difference = now.difference(creationDate);
            final daysActive = difference.inDays;

            int foodsScanned = 0;

            final mealsQuery = await firestore
                .collection('meals')
                .where('userId', isEqualTo: currentUser.uid)
                .get();

            for (final doc in mealsQuery.docs) {
              final data = doc.data();
              if (data['imageUrl'] != null ||
                  (data['description'] != null &&
                      data['description']
                          .toString()
                          .contains('Scanned'))) {
                foodsScanned++;
              }
            }

            _userStats = {
              'daysActive': daysActive,
              'foodsScanned': foodsScanned,
            };

            notifyListeners();
          } else {
            _userStats = {'daysActive': 0, 'foodsScanned': 0};
          }
        } else {
          _userStats = {'daysActive': 0, 'foodsScanned': 0};
        }
      }
    } catch (e) {
      print('Error loading user stats: $e');
      _userStats = {'daysActive': 0, 'foodsScanned': 0};
    }
  }

  Future<void> updateProfile(
      {String? displayName,
      File? imageFile,
      int? calorieGoal}) async {
    setState(ViewState.busy);

    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        await _userRepository.updateUserProfile(
          currentUser.uid,
          displayName: displayName,
          imageFile: imageFile,
          calorieGoal: calorieGoal,
        );

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

  Future<void> recalculateAnalytics() async {
    setState(ViewState.busy);
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        final analyticsRepository = AnalyticsRepository();
        await analyticsRepository.recalculateAnalytics(currentUser.uid);
      }
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }
}
