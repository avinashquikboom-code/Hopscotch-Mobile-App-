import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Sending OTP to phone: $phoneNumber');
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign in on Android
          if (kDebugMode) {
            debugPrint('Auto-verification completed');
          }
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            debugPrint('OTP verification failed: ${e.code} - ${e.message}');
          }
          onError('${e.code}: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            debugPrint('OTP code sent, verificationId: $verificationId');
          }
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            debugPrint('OTP auto-retrieval timeout');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OTP send error: $e');
      }
      onError(e.toString());
    }
  }

  // Verify OTP and sign in
  Future<User?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Save user data to Firestore
  Future<void> saveUserData({
    required String userId,
    required String phoneNumber,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'phoneNumber': phoneNumber,
        'name': name ?? '',
        'email': email ?? '',
        'avatarUrl': avatarUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign up with email and password
  Future<User?> signup({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      
      if (user != null) {
        // Save user data to Firestore
        await saveUserData(
          userId: user.uid,
          phoneNumber: mobile,
          name: name,
          email: email,
        );
      }
      
      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
