import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/analytics_repository.dart';
import 'base_viewmodel.dart';

/// This class is a view model for the profile screen.
class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  UserModel? _userData;
  Map<String, int> _userStats = {};

  /// The user data.
  UserModel? get userData => _userData;
  /// The user stats.
  Map<String, int> get userStats => _userStats;

  /// Creates a new instance of the [ProfileViewModel] class.
  ProfileViewModel(this._userRepository);

  /// Loads the user data.
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

  /// Loads the user stats.
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

  /// Updates the user's profile.
  ///
  /// The [displayName] is the user's new display name.
  /// The [imageFile] is the user's new profile image.
  /// The [calorieGoal] is the user's new daily calorie goal.
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

  /// Signs out the current user.
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

  /// Gets the user's display name.
  String getDisplayName() {
    if (_userData?.displayName != null && _userData!.displayName!.isNotEmpty) {
      return _userData!.displayName!;
    }
    return "User";
  }

  /// Gets the user's email address.
  String getEmail() {
    return _userData?.email ?? "No email";
  }

  /// Recalculates the user's analytics.
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