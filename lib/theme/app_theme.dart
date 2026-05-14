import 'package:flutter/material.dart';

// ZKred official brand colors (from Brand Guidelines 2025)
class ZKColors {
  // Primary palette
  static const electric = Color(0xFF114EF6);   // ZKred Electric — main CTA blue
  static const base = Color(0xFF0D39B3);        // ZKred Base — mid blue
  static const shield = Color(0xFF09287E);      // ZKred Shield — deep navy
  static const trust = Color(0xFF061B54);       // ZKred Trust — darkest navy

  // Aliases for semantic use
  static const primary = electric;
  static const primaryDark = base;
  static const background = trust;             // Dark navy background
  static const surface = Color(0xFF0C2266);    // Slightly lighter surface
  static const card = Color(0xFF0F2B7A);       // Card background
  static const cardBorder = Color(0xFF1A3A99);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF); // 70% white
  static const textMuted = Color(0x66FFFFFF);     // 40% white
  static const textOnLight = Color(0xFF061B54);   // Trust color for text on white

  // Aliases kept for screen compatibility
  static const text = textPrimary;
  static const border = cardBorder;

  static const error = Color(0xFFFF4D4F);
  static const success = Color(0xFF52C41A);
  static const warning = Color(0xFFFAAD14);

  // Gradient: dark navy → deep blue
  static const gradientStart = trust;
  static const gradientMid = shield;
  static const gradientEnd = base;
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Almarai',
        colorScheme: const ColorScheme.dark(
          primary: ZKColors.electric,
          secondary: ZKColors.base,
          surface: ZKColors.surface,
          error: ZKColors.error,
          onPrimary: Colors.white,
          onSurface: ZKColors.textPrimary,
        ),
        scaffoldBackgroundColor: ZKColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ZKColors.textPrimary,
          titleTextStyle: TextStyle(
            color: ZKColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontFamily: 'Almarai',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ZKColors.electric,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Almarai'),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ZKColors.electric,
            side: const BorderSide(color: ZKColors.electric, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Almarai'),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ZKColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ZKColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ZKColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ZKColors.electric, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle:
              const TextStyle(color: ZKColors.textMuted, fontSize: 16),
          labelStyle:
              const TextStyle(color: ZKColors.textSecondary),
        ),
        cardTheme: CardThemeData(
          color: ZKColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ZKColors.cardBorder),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ZKColors.shield,
          selectedItemColor: ZKColors.electric,
          unselectedItemColor: ZKColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: ZKColors.cardBorder,
          thickness: 1,
          space: 1,
        ),
      );
}

/// Full-screen gradient background matching ZKred navy brand.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ZKColors.trust,
            ZKColors.shield,
            ZKColors.base,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Smaller card-style container with ZKred electric glow border.
class ZKCard extends StatelessWidget {
  const ZKCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glowBorder = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool glowBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ZKColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glowBorder ? ZKColors.electric : ZKColors.cardBorder,
          width: glowBorder ? 1.5 : 1,
        ),
        boxShadow: glowBorder
            ? [
                BoxShadow(
                  color: const Color.fromRGBO(17, 78, 246, 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
