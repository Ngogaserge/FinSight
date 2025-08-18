import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth change user stream
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Validate password
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-email':
          throw 'The email address is invalid.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        default:
          throw 'An error occurred during sign in.';
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      throw 'An unexpected error occurred.';
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      if (!_isValidPassword(password)) {
        throw 'Password must be at least 6 characters long.';
      }

      if (name.trim().isEmpty) {
        throw 'Name cannot be empty.';
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await result.user?.updateDisplayName(name);

      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          throw 'The password provided is too weak.';
        case 'email-already-in-use':
          throw 'An account already exists for this email.';
        case 'invalid-email':
          throw 'The email address is invalid.';
        default:
          throw 'An error occurred during registration.';
      }
    } catch (e) {
      debugPrint('Error registering: $e');
      throw 'An unexpected error occurred.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Firebase Auth Error during sign out: ${e.code} - ${e.message}');
      throw 'Failed to sign out. Please try again.';
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw 'An unexpected error occurred during sign out.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'invalid-email':
          throw 'The email address is invalid.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        default:
          throw 'An error occurred while sending the reset email.';
      }
    } catch (e) {
      debugPrint('Error resetting password: $e');
      throw 'An unexpected error occurred.';
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign in was cancelled.';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'An account already exists with the same email address but different sign-in credentials.';
        case 'invalid-credential':
          throw 'The credential is invalid or has expired.';
        case 'operation-not-allowed':
          throw 'Google sign in is not enabled.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-verification-code':
          throw 'The verification code is invalid.';
        case 'invalid-verification-id':
          throw 'The verification ID is invalid.';
        default:
          throw 'An error occurred during Google sign in.';
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      throw 'An unexpected error occurred during Google sign in.';
    }
  }
}
