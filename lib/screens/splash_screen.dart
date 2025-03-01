import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';

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

        print('DEBUG: SplashScreen - navigating to MainScreen');
        Navigator.pushReplacementNamed(context, '/main');
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
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.star,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // App name with fade-in animation
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'Influence',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tagline with fade-in animation
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'Connect with creators who match your brand',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
