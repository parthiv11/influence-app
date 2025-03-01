import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../lib/firebase_options.dart';

// This script seeds the Firebase Firestore database with initial data.
// Run this script with: flutter run scripts/firebase_seed.dart

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Sample user data
  await seedUsers(firestore);

  // Sample chat data
  await seedChats(firestore);

  // Sample campaigns
  await seedCampaigns(firestore);

  print('Firebase database seeded successfully!');
}

Future<void> seedUsers(FirebaseFirestore firestore) async {
  // Sample influencer profiles
  await firestore.collection('users').doc('sample_influencer_1').set({
    'uid': 'sample_influencer_1',
    'name': 'Gaming Pro',
    'email': 'gamer@example.com',
    'bio': 'Professional gamer and content creator',
    'userType': 'influencer',
    'profilePic':
        'https://ui-avatars.com/api/?name=Gaming+Pro&background=9146FF&color=fff',
    'website': 'https://gaming.example.com',
    'createdAt': FieldValue.serverTimestamp(),
    'metrics': {
      'totalFollowers': 125000,
      'engagementRate': 8.5,
      'lastUpdated': DateTime.now().toIso8601String(),
    },
    'socialAccounts': {'twitch': true, 'youtube': true, 'instagram': true},
  });

  await firestore.collection('users').doc('sample_influencer_2').set({
    'uid': 'sample_influencer_2',
    'name': 'Beauty Guru',
    'email': 'beauty@example.com',
    'bio': 'Beauty and lifestyle content creator',
    'userType': 'influencer',
    'profilePic':
        'https://ui-avatars.com/api/?name=Beauty+Guru&background=E91916&color=fff',
    'website': 'https://beauty.example.com',
    'createdAt': FieldValue.serverTimestamp(),
    'metrics': {
      'totalFollowers': 87500,
      'engagementRate': 5.2,
      'lastUpdated': DateTime.now().toIso8601String(),
    },
    'socialAccounts': {'instagram': true, 'youtube': true, 'tiktok': true},
  });

  // Sample brand profiles
  await firestore.collection('users').doc('sample_brand_1').set({
    'uid': 'sample_brand_1',
    'name': 'TechGadgets',
    'email': 'contact@techgadgets.example.com',
    'bio': 'Innovative tech gadgets for modern life',
    'userType': 'brand',
    'profilePic':
        'https://ui-avatars.com/api/?name=Tech+Gadgets&background=1F69FF&color=fff',
    'website': 'https://techgadgets.example.com',
    'createdAt': FieldValue.serverTimestamp(),
    'industry': 'Technology',
    'companySince': '2015',
  });

  await firestore.collection('users').doc('sample_brand_2').set({
    'uid': 'sample_brand_2',
    'name': 'FitLife Supplements',
    'email': 'contact@fitlife.example.com',
    'bio': 'Premium fitness supplements and nutrition',
    'userType': 'brand',
    'profilePic':
        'https://ui-avatars.com/api/?name=Fit+Life&background=00C853&color=fff',
    'website': 'https://fitlife.example.com',
    'createdAt': FieldValue.serverTimestamp(),
    'industry': 'Fitness & Nutrition',
    'companySince': '2018',
  });
}

Future<void> seedChats(FirebaseFirestore firestore) async {
  // Create a general chat
  await firestore.collection('chats').doc('general').set({
    'name': 'General Chat',
    'description': 'Chat room for all users',
    'createdAt': FieldValue.serverTimestamp(),
    'type': 'public',
  });

  // Add some sample messages
  await firestore
      .collection('chats')
      .doc('general')
      .collection('messages')
      .add({
        'senderId': 'sample_influencer_1',
        'message':
            'Hello everyone! I\'m looking for tech brands to collaborate with.',
        'timestamp': FieldValue.serverTimestamp(),
      });

  await firestore.collection('chats').doc('general').collection('messages').add({
    'senderId': 'sample_brand_1',
    'message':
        'Hi there! We\'re looking for gaming influencers for our new product launch.',
    'timestamp': FieldValue.serverTimestamp(),
  });

  // Create a direct chat between a brand and influencer
  final directChatId = 'direct_brand1_influencer1';
  await firestore.collection('chats').doc(directChatId).set({
    'participants': ['sample_brand_1', 'sample_influencer_1'],
    'createdAt': FieldValue.serverTimestamp(),
    'type': 'direct',
    'lastMessage': 'Let\'s discuss the collaboration details',
    'lastMessageTime': FieldValue.serverTimestamp(),
  });

  await firestore.collection('chats').doc(directChatId).collection('messages').add({
    'senderId': 'sample_brand_1',
    'message':
        'Hi! We love your content and would like to discuss a potential partnership.',
    'timestamp': FieldValue.serverTimestamp(),
  });

  await firestore.collection('chats').doc(directChatId).collection('messages').add({
    'senderId': 'sample_influencer_1',
    'message':
        'Thanks for reaching out! I\'d be interested in learning more about your products.',
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Future<void> seedCampaigns(FirebaseFirestore firestore) async {
  // Create sample campaigns
  await firestore.collection('campaigns').doc('campaign_1').set({
    'title': 'Gaming Peripherals Launch',
    'brandId': 'sample_brand_1',
    'description':
        'Seeking gaming influencers to promote our new line of gaming peripherals',
    'requirements': ['Min 50K followers', 'Gaming niche', 'Content in English'],
    'budget': 'USD 500-1000 per post',
    'status': 'active',
    'createdAt': FieldValue.serverTimestamp(),
    'deadline': DateTime.now().add(Duration(days: 30)).toIso8601String(),
    'applicants': [],
  });

  await firestore.collection('campaigns').doc('campaign_2').set({
    'title': 'Fitness Challenge Sponsorship',
    'brandId': 'sample_brand_2',
    'description':
        'Looking for fitness influencers to participate in a 30-day challenge',
    'requirements': [
      'Min 25K followers',
      'Fitness/Health niche',
      'Experience with fitness challenges',
    ],
    'budget': 'USD 800-1500 per campaign',
    'status': 'active',
    'createdAt': FieldValue.serverTimestamp(),
    'deadline': DateTime.now().add(Duration(days: 45)).toIso8601String(),
    'applicants': ['sample_influencer_2'],
  });
}
