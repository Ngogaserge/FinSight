import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create a reference to the location where the image will be stored
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: ${e.code} - ${e.message}');
      throw 'Failed to upload image: ${e.message}';
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw 'An unexpected error occurred while uploading image';
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');
      await storageRef.delete();
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: ${e.code} - ${e.message}');
      throw 'Failed to delete image: ${e.message}';
    } catch (e) {
      debugPrint('Error deleting image: $e');
      throw 'An unexpected error occurred while deleting image';
    }
  }
}
