import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CraftConnectApp());
}

class CraftConnectApp extends StatelessWidget {
  const CraftConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CraftConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4E71),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}