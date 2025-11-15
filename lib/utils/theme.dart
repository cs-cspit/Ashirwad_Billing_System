import 'package:flutter/material.dart';

class AppTheme {
  // Professional color scheme for Ashirwad Industries
  static const Color primaryColor = Color(0xFF1565C0); // Deep blue
  static const Color secondaryColor = Color(0xFF0277BD); // Lighter blue
  static const Color accentColor = Color(0xFF4CAF50); // Green for success
  static const Color successColor = Color(0xFF4CAF50); // Green for success
  static const Color warningColor = Color(0xFFFF9800); // Orange for warnings
  static const Color errorColor = Color(0xFFD32F2F); // Red for errors
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light gray
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color onSurface = Color(0xFF212121); // Dark text on surface

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: onPrimary,
        onSurface: onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }
}

class AppConstants {
  static const String appName = 'Ashirwad Billing';
  static const String companyName = 'Ashirwad Industries';
  static const String companyDescription = 'Plastic Granules Manufacturing';
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  
  // Text sizes
  static const double textSizeSmall = 12.0;
  static const double textSizeMedium = 14.0;
  static const double textSizeLarge = 16.0;
  static const double textSizeXLarge = 18.0;
  static const double textSizeTitle = 20.0;
  static const double textSizeHeading = 24.0;
  
  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
}
