import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/main_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// Add a global variable for debug messages
bool _firebaseInitialized = false;

// Add a simple test function for Firebase connection
Future<void> testFirebaseConnection() async {
  try {
    print('DEBUG: Testing Firebase connection...');
    await FirebaseFirestore.instance
        .collection('_test_connection')
        .doc('test')
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Test connection successful',
        });
    print('DEBUG: Firebase connection successful!');
  } catch (e) {
    print('ERROR: Firebase connection failed: $e');
  }
}

Future<void> main() async {
  print('DEBUG: App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('DEBUG: Flutter binding initialized');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Initialize Facebook SDK first
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "YOUR_FACEBOOK_APP_ID", // Replace with your actual Facebook App ID
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
    print('DEBUG: Facebook SDK initialized');

    // Then initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
    print('DEBUG: Firebase initialized successfully');

    // Test the Firebase connection
    await testFirebaseConnection();
  } catch (e) {
    print('DEBUG: Error during initialization: $e');
  }

  runApp(const MyApp());
  print('DEBUG: MyApp started');
}

// Test function for Firestore
Future<void> testFirestoreConnection() async {
  if (!_firebaseInitialized) {
    print('ERROR: Cannot test Firestore - Firebase not initialized');
    return;
  }

  try {
    print('DEBUG: Testing Firestore connection...');
    final testDoc =
        await FirebaseFirestore.instance
            .collection('_test_connection')
            .doc('test')
            .get();

    print('DEBUG: Firestore connection successful!');

    // Optional - create a test document
    try {
      await FirebaseFirestore.instance
          .collection('_test_connection')
          .doc('test')
          .set({
            'timestamp': FieldValue.serverTimestamp(),
            'message': 'Connection test successful',
          });
      print('DEBUG: Test document created successfully');
    } catch (e) {
      print('DEBUG: Could not create test document: $e');
    }
  } catch (e) {
    print('ERROR: Firestore connection failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building MyApp widget');
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Influence App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF9146FF), // Twitch purple
          scaffoldBackgroundColor: const Color(
            0xFF0E0E10,
          ), // Twitch dark background
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFF18181B), // Twitch dark gray
            foregroundColor: Colors.white,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          cardTheme: CardTheme(
            elevation: 4,
            color: const Color(0xFF18181B), // Twitch dark gray
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            displayMedium: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
            bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white70),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9146FF), // Twitch purple
            secondary: Color(0xFFE91916), // Twitch red
            tertiary: Color(0xFF1F69FF), // Twitch blue
            surface: Color(0xFF18181B),
            background: Color(0xFF18181B), // Updated to match surface color
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white, // Added to match onSurface
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9146FF), // Twitch purple
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: Color(0xFF9146FF), // Twitch purple
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF9146FF), // Twitch purple
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF9146FF), // Twitch purple
                width: 2,
              ),
            ),
            fillColor: const Color(
              0xFF26262C,
            ), // Slightly lighter than background
            filled: true,
            labelStyle: const TextStyle(color: Colors.grey),
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/main': (context) => const MainScreen(),
          '/home': (context) => const HomeScreen(),
          '/discover': (context) => const DiscoverScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/chat': (context) => const ChatScreen(),
        },
      ),
    );
  }
}
