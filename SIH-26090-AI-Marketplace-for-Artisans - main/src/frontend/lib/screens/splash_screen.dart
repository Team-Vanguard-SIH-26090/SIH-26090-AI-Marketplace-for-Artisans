import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../auth.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Auth.load();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final next = Auth.artisanId == null ? const OnboardingScreen() : const DashboardScreen();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB), // Warm Sand
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF9E4733), // Terracotta
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'CraftConnect',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C221E), // Espresso Brown
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Empowering craft. Connecting markets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8C7A70), // Earthy Grey
              ),
            ),

            const SizedBox(height: 40),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF9E4733), // Terracotta
              ),
            ),
          ],
        ),
      ),
    );
  }
}