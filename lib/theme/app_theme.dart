import 'package:flutter/material.dart';

class AppTheme {
  // Main colors
  static const Color primaryColor = Color(0xFF2F80ED); // Blue
  static const Color secondaryColor = Color(0xFF27AE60); // Green
  static const Color accentColor = Color(0xFFFFA000); // Orange

  // Role colors
  static const Color adminColor = Color(0xFF9B51E0); // Purple
  static const Color doctorColor = Color(0xFF2F80ED); // Blue
  static const Color patientColor = Color(0xFF27AE60); // Green

  // Neutral colors
  static Color lightBackgroundColor = Colors.grey[100]!;
  static final Color cardColor = Colors.white;
  static final Color dividerColor = Colors.grey.shade300;

  // Text colors
  static final Color primaryTextColor = Colors.grey.shade900;
  static final Color secondaryTextColor = Colors.grey.shade700;
  static Color subtleTextColor = Colors.grey[600]!;

  // Status colors
  static const Color successColor = Color(0xFF66BB6A); // Green
  static const Color warningColor = Color(0xFFFFB74D); // Orange
  static const Color errorColor = Color(0xFFEB5757); // Red

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    minimumSize: const Size(double.infinity, 50),
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    minimumSize: const Size(double.infinity, 50),
  );

  // Card styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha((0.05 * 255).toInt()),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: primaryTextColor,
  );

  static TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: subtleTextColor,
  );

  // Main app theme
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          // formerly headline5
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          // formerly headline6
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          // formerly bodyText1
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          // formerly bodyText2
          fontSize: 14,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
