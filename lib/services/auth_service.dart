import 'package:bikex/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email, password, and name
  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Send email verification
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }
      // Store user details in Firestore
      if (result.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .set({
          'name': name,
          'email': email,
          'address': [],
          'phoneNumber': '',
        });
      }
      return result.user;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  // Fetch RestaurantUser from Firestore
  Future<RestaurantUser?> getRestaurantUser() async {
    User? fbUser = getCurrentUser();
    if (fbUser == null) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .get();
      
      if (!userDoc.exists) return null;

      return RestaurantUser(
        id: fbUser.uid,
        name: userDoc.get('name') ?? fbUser.displayName ?? 'User',
        email: fbUser.email ?? '',
        address: List<String>.from(userDoc.get('address') ?? []),
        phoneNumber: userDoc.get('phoneNumber') ?? '',
      );
    } catch (e) {
      print('Error fetching RestaurantUser: $e');
      return null;
    }
  }
}