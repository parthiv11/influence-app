import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Get current user ID
  String? get currentUserId => auth.FirebaseAuth.instance.currentUser?.uid;

  // Create a new user profile
  Future<void> createUserProfile(auth.User user) async {
    try {
      // Check if user already exists
      final docSnapshot = await _usersCollection.doc(user.uid).get();

      if (!docSnapshot.exists) {
        // Create new user document
        await _usersCollection.doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'profilePic': user.photoURL ?? '',
          'bio': '',
          'website': '',
          'userType': 'influencer',
          'createdAt': FieldValue.serverTimestamp(),
          'metrics': {
            'totalFollowers': 0,
            'engagementRate': 0.0,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        });
      }
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (docSnapshot.exists) {
        return UserModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Update a specific field in user profile
  Future<void> updateUserField(
    String userId,
    String field,
    dynamic value,
  ) async {
    try {
      await _usersCollection.doc(userId).update({field: value});
    } catch (e) {
      print('Error updating user field: $e');
      throw e;
    }
  }

  // Upload profile image and return the URL
  Future<String> uploadProfileImage(XFile image) async {
    try {
      final String userId = auth.FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final File file = File(image.path);
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users/$userId/$fileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Update user profile with new image URL
      await _usersCollection.doc(userId).update({'profilePic': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw e;
    }
  }

  // Remove a social account
  Future<void> removeSocialAccount(String userId, String provider) async {
    try {
      await _usersCollection.doc(userId).update({
        'socialAccounts.$provider': FieldValue.delete(),
      });
    } catch (e) {
      print('Error removing social account: $e');
      throw e;
    }
  }

  // Get user metrics
  Future<Map<String, dynamic>> getUserMetrics(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        return userData['metrics'] as Map<String, dynamic>? ?? {};
      }
      return {};
    } catch (e) {
      print('Error getting user metrics: $e');
      return {};
    }
  }

  // Stream user profile for real-time updates
  Stream<UserModel?> streamUserProfile(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists
                  ? UserModel.fromMap(
                    snapshot.data() as Map<String, dynamic>,
                    snapshot.id,
                  )
                  : null,
        );
  }

  // Get all users for discovery
  Future<List<Map<String, dynamic>>> getInfluencers(int limit) async {
    List<Map<String, dynamic>> influencers = [];

    try {
      QuerySnapshot querySnapshot =
          await _db
              .collection("users")
              .orderBy("metrics.totalFollowers", descending: true)
              .limit(limit)
              .get();

      for (var doc in querySnapshot.docs) {
        influencers.add(doc.data() as Map<String, dynamic>);
      }

      return influencers;
    } catch (e) {
      print('Error getting influencers: $e');
      return [];
    }
  }

  // Chat functions: using a 'chats' collection with a document 'general'
  // and a subcollection 'messages'
  Stream<QuerySnapshot> getChatMessages() {
    return _db
        .collection("chats")
        .doc("general")
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Future<void> sendMessage(String message) async {
    auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection("chats").doc("general").collection("messages").add({
        "senderId": user.uid,
        "message": message,
        "timestamp": FieldValue.serverTimestamp(),
      });
    }
  }
}
