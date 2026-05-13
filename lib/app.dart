import 'package:flutter/material.dart';

import 'screens/credentials_screen.dart';
import 'screens/home_screen.dart';
import 'screens/identity_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/splash_screen.dart';

class ZKredApp extends StatelessWidget {
  const ZKredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZKred Wallet',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/identity': (_) => const IdentityScreen(),
        '/credentials': (_) => const CredentialsScreen(),
        '/scanner': (_) => const ScannerScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    const primaryPurple = Color(0xFF7C3AED);
    const bgDark = Color(0xFF0D0D1A);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.dark,
        surface: bgDark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF16162A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D2D4E)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16162A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D2D4E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D2D4E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple),
        ),
      ),
    );
  }
}
