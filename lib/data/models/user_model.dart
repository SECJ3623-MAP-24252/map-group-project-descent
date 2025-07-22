import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user of the application.
class UserModel {
  /// The unique identifier of the user.
  final String uid;
  /// The email address of the user.
  final String email;
  /// The display name of the user.
  final String? displayName;
  /// The URL of the user's profile photo.
  final String? photoURL;
  /// The date and time the user was created.
  final DateTime createdAt;
  /// The date and time the user last logged in.
  final DateTime lastLoginAt;
  /// A map of the user's preferences.
  final Map<String, dynamic>? preferences;
  /// The FCM token of the user's device.
  final String? fcmToken; // Added for FCM
  /// The user's daily calorie goal.
  final int? calorieGoal;

  /// Creates a new instance of the [UserModel] class.
  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
    this.fcmToken, // Added for FCM
    this.calorieGoal,
  });

  /// Converts this [UserModel] to a [Map] for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'preferences': preferences,
      'fcmToken': fcmToken, // Added for FCM
      'calorieGoal': calorieGoal,
    };
  }

  /// Creates a new instance of the [UserModel] class from a Firestore document.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      preferences: data['preferences'],
      fcmToken: data['fcmToken'], // Added for FCM
      calorieGoal: data['calorieGoal'],
    );
  }

  /// Creates a copy of this [UserModel] with the given fields updated.
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    String? fcmToken, // Added for FCM
    int? calorieGoal,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      fcmToken: fcmToken ?? this.fcmToken, // Added for FCM
      calorieGoal: calorieGoal ?? this.calorieGoal,
    );
  }
}