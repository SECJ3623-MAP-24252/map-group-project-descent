import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  AuthViewModel() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      _currentUser = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: user.metadata.creationTime,
      );
      _isAuthenticated = true;
      
      // Save user to Firebase Firestore
      await FirebaseService.saveUser(_currentUser!);
    } else {
      _currentUser = null;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      setLoading(true);
      setError(null);
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      setLoading(true);
      setError(null);
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        
        // Create user model and save to Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );
        
        await FirebaseService.saveUser(userModel);
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      setLoading(true);
      setError(null);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Create user model and save to Firestore
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName,
          photoURL: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
        );
        
        await FirebaseService.saveUser(userModel);
      }
      
      return true;
    } catch (e) {
      setError('Failed to sign in with Google');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      setLoading(true);
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      setError('Failed to sign out');
    } finally {
      setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      setLoading(true);
      setError(null);
      
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      setError(_getErrorMessage(e.code));
    } catch (e) {
      setError('An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      setLoading(true);
      setError(null);
      
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
      // Update Firestore user document
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      
      await FirebaseService.updateUser(user.uid, updateData);
      
      // Update local user model
      _currentUser = _currentUser?.copyWith(
        displayName: displayName ?? _currentUser?.displayName,
        photoURL: photoURL ?? _currentUser?.photoURL,
      );
      
      notifyListeners();
    } catch (e) {
      setError('Failed to update profile');
    } finally {
      setLoading(false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      default:
        return 'Authentication failed';
    }
  }
} 