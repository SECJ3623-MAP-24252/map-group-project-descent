import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserRepository {
  final FirebaseService _firebaseService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserRepository(this._firebaseService);

  // Authentication methods
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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // User data methods
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

  Future<void> createUserDocument(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(
    String uid, {
    String? displayName,
    String? photoURL,
    File? imageFile,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;

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

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to update last login: $e');
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
