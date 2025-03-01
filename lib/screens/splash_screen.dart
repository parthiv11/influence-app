import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    print('DEBUG: SplashScreen - initState called');

    // Animation to scale the logo
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    print('DEBUG: SplashScreen - animation started');

    // Check auth state after delay
    Timer(Duration(seconds: 3), () async {
      print('DEBUG: SplashScreen - checking auth state');
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(
          'DEBUG: SplashScreen - user is logged in, ensuring profile exists',
        );

        // Ensure user profile exists before navigating
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.ensureUserProfileExists();

        print('DEBUG: SplashScreen - navigating to ProfileScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      } else {
        print(
          'DEBUG: SplashScreen - user is not logged in, navigating to LoginScreen',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: SplashScreen - build method called');
    return Scaffold(
      // Gradient background splash screen
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Icon(Icons.star, size: 120, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
