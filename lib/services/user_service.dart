import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'users';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user document reference
  DocumentReference get _userDoc =>
      _firestore.collection(_collection).doc(currentUser?.uid);

  // Create or update user data
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _userDoc.set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData() async {
    try {
      final doc = await _userDoc.get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _userDoc.update({'preferences': preferences});
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      updates['lastLoginAt'] = FieldValue.serverTimestamp();

      await _userDoc.update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      await _userDoc.delete();
      await currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete user account: $e');
    }
  }

  // Stream user data changes
  Stream<UserModel?> streamUserData() {
    return _userDoc.snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }
}
