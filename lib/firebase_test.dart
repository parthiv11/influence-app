import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Try to access Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      final testDoc = await firestore
          .collection('test')
          .doc('connectivity')
          .set({
            'timestamp': FieldValue.serverTimestamp(),
            'message': 'Firebase connection test',
          });
      print('Firestore write successful');

      // Read back the document
      final docSnapshot =
          await firestore.collection('test').doc('connectivity').get();
      if (docSnapshot.exists) {
        print('Firestore read successful: ${docSnapshot.data()}');
      } else {
        print('Document exists but no data');
      }
    } catch (e) {
      print('Firestore error: $e');
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Firebase Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Check the console output for Firebase connectivity results',
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final firestore = FirebaseFirestore.instance;
                    await firestore.collection('test').doc('button-press').set({
                      'timestamp': FieldValue.serverTimestamp(),
                      'message': 'Button pressed',
                    });
                    print('Button press recorded in Firestore');
                  } catch (e) {
                    print('Error on button press: $e');
                  }
                },
                child: Text('Test Firestore Write'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
