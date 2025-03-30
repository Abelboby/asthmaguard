import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign In was canceled by user');
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUserInFirestore(
          userCredential.user!.uid,
          userCredential.user!.email ?? '',
          userCredential.user!.displayName ?? 'User',
          userCredential.user!.photoURL,
        );
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user in Firestore
      await _createUserInFirestore(result.user!.uid, email, name);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Create user in Firestore
  Future<void> _createUserInFirestore(
      String uid, String email, String name) async {
    try {
      final userModel = UserModel(
        id: uid,
        email: email,
        name: name,
        hasSmartMask: false,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Create or update user in Firestore after Google Sign-In
  Future<void> _createOrUpdateUserInFirestore(
      String uid, String email, String name, String? photoUrl) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      final userModel = UserModel(
        id: uid,
        email: email,
        name: name,
        hasSmartMask: false,
        profileImage: photoUrl,
      );

      if (userDoc.exists) {
        // Update existing user
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({
          'email': email,
          'name': name,
          'profileImage': photoUrl,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user
        await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
          ...userModel.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user model from Firestore
  Future<UserModel?> getUserModel() async {
    try {
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userModel.id)
          .update(userModel.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
