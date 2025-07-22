import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// This class is a repository for the user feature.
class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new instance of the [UserRepository] class.
  UserRepository();

  // Authentication methods
  /// Signs in a user with the given email and password.
  ///
  /// The [email] is the user's email address.
  /// The [password] is the user's password.
  ///
  /// Returns a [UserModel] object if the sign-in is successful, otherwise returns null.
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
        return await getUserData(credential.user!.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Registers a new user with the given email, password, and display name.
  ///
  /// The [email] is the user's email address.
  /// The [password] is the user's password.
  /// The [displayName] is the user's display name.
  ///
  /// Returns a [UserModel] object if the registration is successful, otherwise returns null.
  Future<UserModel?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update the user's display name
        await credential.user!.updateDisplayName(displayName);

        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await createUserDocument(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email to the given email address.
  ///
  /// The [email] is the user's email address.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User data methods
  /// Gets the user data for the given unique identifier.
  ///
  /// The [uid] is the unique identifier of the user.
  ///
  /// Returns a [UserModel] object if the user is found, otherwise returns null.
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Creates a new user document in Firestore.
  ///
  /// The [user] is the user to be created.
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  /// Updates the user's profile.
  ///
  /// The [uid] is the unique identifier of the user.
  /// The [displayName] is the user's new display name.
  /// The [photoURL] is the URL of the user's new profile photo.
  /// The [imageFile] is the new profile photo.
  /// The [calorieGoal] is the user's new daily calorie goal.
  Future<void> updateUserProfile(
    String uid, {
    String? displayName,
    String? photoURL,
    File? imageFile,
    int? calorieGoal,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (calorieGoal != null) updates['calorieGoal'] = calorieGoal;

      // Convert image to base64 if provided
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        updates['photoURL'] = 'data:image/jpeg;base64,$base64Image';
      } else if (photoURL != null) {
        updates['photoURL'] = photoURL;
      }

      updates['lastLoginAt'] = Timestamp.now();

      await _firestore.collection('users').doc(uid).update(updates);

      // Also update Firebase Auth profile
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (updates['photoURL'] != null) {
          await user.updatePhotoURL(updates['photoURL']);
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Updates the last login time of the user.
  ///
  /// The [uid] is the unique identifier of the user.
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to update last login: $e');
    }
  }

  /// Gets the current user.
  User? get currentUser => _auth.currentUser;

  /// A stream of the user's authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}