import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of auth state changes
  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Check if user profile exists and create one if it doesn't
  Future<UserModel?> ensureUserProfileExists() async {
    print('DEBUG: Ensuring user profile exists');
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      print('DEBUG: No user is logged in');
      return null;
    }

    try {
      // Check if user profile exists
      final docSnapshot =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!docSnapshot.exists) {
        print('DEBUG: User profile does not exist, creating one');
        await _firestoreService.createUserProfile(firebaseUser);
        print('DEBUG: User profile created successfully');
      } else {
        print('DEBUG: User profile already exists');
      }

      // Return the user profile
      return await _firestoreService.getUserProfile(firebaseUser.uid);
    } catch (e) {
      print('ERROR: Failed to ensure user profile exists: $e');
      return null;
    }
  }

  // Phone authentication with callbacks
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onVerificationFailed,
    required Function(auth.PhoneAuthCredential credential)
    onVerificationComplete,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: Duration(seconds: 60),
      verificationCompleted: (auth.PhoneAuthCredential credential) async {
        // Automatically sign in the user on Android devices.
        await _auth.signInWithCredential(credential);
        onVerificationComplete(credential);
      },
      verificationFailed: (auth.FirebaseAuthException e) {
        onVerificationFailed(e.message ?? "Verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Legacy phone authentication method - kept for backward compatibility
  Future<void> legacyVerifyPhoneNumber(
    BuildContext context,
    String phoneNumber,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: Duration(seconds: 60),
      verificationCompleted: (auth.PhoneAuthCredential credential) async {
        // Automatically sign in the user on Android devices.
        await _auth.signInWithCredential(credential);
        Navigator.pushNamed(context, '/profile');
      },
      verificationFailed: (auth.FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Verification failed")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        _showOtpDialog(context, verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Show OTP dialog for legacy method
  void _showOtpDialog(BuildContext context, String verificationId) {
    TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Enter OTP"),
            content: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "OTP"),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  auth.PhoneAuthCredential credential = auth
                      .PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: otpController.text.trim(),
                  );
                  try {
                    await _auth.signInWithCredential(credential);
                    Navigator.pop(context); // Dismiss dialog
                    Navigator.pushNamed(context, '/profile');
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Invalid OTP")));
                  }
                },
                child: Text("Verify"),
              ),
            ],
          ),
    );
  }

  // Legacy methods for email/password authentication
  Future<void> signInWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    }
  }

  Future<void> createUserWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Account created successfully")));
      Navigator.pushNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString()}")),
      );
    }
  }

  // Verify with code
  Future<UserModel?> verifyWithCode(
    String verificationId,
    String smsCode,
  ) async {
    try {
      auth.PhoneAuthCredential credential = auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      auth.UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Check if user profile exists, if not create one
        final docSnapshot =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!docSnapshot.exists) {
          await _firestoreService.createUserProfile(firebaseUser);
        }

        return await _firestoreService.getUserProfile(firebaseUser.uid);
      }
      return null;
    } catch (e) {
      print('Verification error: $e');
      throw e;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      auth.User? firebaseUser = result.user;

      if (firebaseUser != null) {
        return await _firestoreService.getUserProfile(firebaseUser.uid);
      }
      return null;
    } catch (e) {
      print('Email sign in error: $e');
      throw e;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      auth.User? firebaseUser = result.user;

      if (firebaseUser != null) {
        await _firestoreService.createUserProfile(firebaseUser);
        return await _firestoreService.getUserProfile(firebaseUser.uid);
      }
      return null;
    } catch (e) {
      print('Email registration error: $e');
      throw e;
    }
  }

  // Sign out method that handles all auth providers
  Future<void> signOut() async {
    print('DEBUG: Starting sign out process in AuthService');
    try {
      // Sign out from Google
      try {
        await _googleSignIn.signOut();
        print('DEBUG: Google sign out successful');
      } catch (e) {
        print('ERROR: Google sign out failed: $e');
      }

      // Sign out from Facebook
      try {
        await FacebookAuth.instance.logOut();
        print('DEBUG: Facebook sign out successful');
      } catch (e) {
        print('ERROR: Facebook sign out failed: $e');
      }

      // Sign out from Firebase
      await _auth.signOut();
      print('DEBUG: Firebase sign out successful');
    } catch (e) {
      print('ERROR: Sign out failed: $e');
      throw e;
    }
  }

  // Email/Password Authentication

  // Send password reset email
  Future<void> sendPasswordResetEmail(
    BuildContext context,
    String email,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = "Failed to send reset email";

      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

  // New methods for social sign-ins

  // Google Sign In
  Future<auth.UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final auth.OAuthCredential credential = auth
          .GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      auth.UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Store user data in Firestore
      await _storeUserDataFromSocial(userCredential, 'google', {
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
      });

      // Navigate to profile screen
      Navigator.pushNamed(context, '/profile');

      return userCredential;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
      return null;
    }
  }

  // Facebook Sign In
  Future<auth.UserCredential?> signInWithFacebook(BuildContext context) async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed');
      }

      // Get user data from Facebook
      final userData = await FacebookAuth.instance.getUserData();

      // Create a credential from the access token
      final auth.OAuthCredential credential = auth
          .FacebookAuthProvider.credential(result.accessToken!.token);

      // Sign in with the credential
      auth.UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Store user data in Firestore
      await _storeUserDataFromSocial(userCredential, 'facebook', {
        'email': userData['email'],
        'displayName': userData['name'],
        'photoUrl': userData['picture']['data']['url'],
      });

      // Navigate to profile screen
      Navigator.pushNamed(context, '/profile');

      return userCredential;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Facebook sign-in failed: $e")));
      return null;
    }
  }

  // Helper method to store user data
  Future<void> _storeUserDataFromSocial(
    auth.UserCredential credential,
    String provider,
    Map<String, dynamic> socialData,
  ) async {
    if (credential.user != null) {
      final auth.User user = credential.user!;

      // Check if user document already exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user document with flexible schema
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': socialData['displayName'] ?? user.displayName ?? '',
          'email': socialData['email'] ?? user.email ?? '',
          'profilePic': socialData['photoUrl'] ?? user.photoURL ?? '',
          'bio': '',
          'website': '',
          'userType': 'influencer',
          'socialAccounts': {provider: socialData},
          'metrics': {
            'totalFollowers': 0,
            'engagementRate': 0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing user document, only modifying the social accounts field
        await _firestore.collection('users').doc(user.uid).update({
          'socialAccounts.$provider': socialData,
          'lastSignIn': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Method to fetch social metrics
  Future<Map<String, dynamic>> fetchSocialMetrics(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['metrics'] ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching social metrics: $e');
      return {};
    }
  }

  // Method to update user profile with flexible fields
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}
