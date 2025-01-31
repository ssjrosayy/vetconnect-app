import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up a new user and save additional details in Firestore
  Future<String> signUpUser({
    required String name,
    required String email,
    required String password,
    required String role, // 'PET' or 'VET'
  }) async {
    try {
      // Create the user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role, // 'PET' or 'VET'
      });

      return "User created successfully.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // Method to log in with email and password
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } catch (e) {
      throw Exception('Failed to log in: $e');
    }
  }

  // Fetch userType from Firestore
  Future<String> getUserType(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      // Return userType if available
      return userDoc.data()?['role'] ?? '';
    } else {
      throw Exception('User document does not exist.');
    }
  }
}
