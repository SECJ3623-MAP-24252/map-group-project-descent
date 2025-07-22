import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// This class is a service for interacting with Firebase.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// The [FirebaseAuth] instance.
  FirebaseAuth get auth => FirebaseAuth.instance;
  /// The [FirebaseFirestore] instance.
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  /// The [FirebaseStorage] instance.
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Initializes Firebase.
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  /// Uploads an image to Firebase Storage.
  ///
  /// The [path] is the path to the image file.
  /// The [fileName] is the name of the file to be created in Firebase Storage.
  ///
  /// Returns the download URL of the uploaded image.
  Future<String> uploadImage(String path, String fileName) async {
    try {
      final ref = storage.ref().child('images/$fileName');
      final uploadTask = await ref.putFile(File(path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }
}