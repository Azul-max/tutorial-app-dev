// lib/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color.fromARGB(255, 195, 74, 74);
  static const Color accentRed = Color.fromARGB(255, 230, 200, 200);
  static const Color lightBackground = Color.fromARGB(255, 241, 227, 227);
  static const Color cardBackground = Colors.white; // Or any other color for cards
  static Color inputFillColor = Colors.grey[100]!;
  static const Color greyText = Colors.black54;
  static const Color greyHint = Colors.grey;
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    // Primary color for your app's main branding and interactive elements
    primaryColor: AppColors.primaryRed,
    // Accent color, can be used for secondary actions or highlights
    hintColor: AppColors.accentRed, // Often used for hints or secondary highlights

    // Define default background colors for Scaffold and Canvas
    scaffoldBackgroundColor: AppColors.lightBackground,
    canvasColor: AppColors.lightBackground, // Used by Drawer, BottomSheet etc.

    // Color scheme for various UI elements (buttons, selections, etc.)
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: MaterialColor(AppColors.primaryRed.value, const {
        50: Color.fromRGBO(195, 74, 74, .1),
        100: Color.fromRGBO(195, 74, 74, .2),
        200: Color.fromRGBO(195, 74, 74, .3),
        300: Color.fromRGBO(195, 74, 74, .4),
        400: Color.fromRGBO(195, 74, 74, .5),
        500: Color.fromRGBO(195, 74, 74, .6),
        600: Color.fromRGBO(195, 74, 74, .7),
        700: Color.fromRGBO(195, 74, 74, .8),
        800: Color.fromRGBO(195, 74, 74, .9),
        900: Color.fromRGBO(195, 74, 74, 1),
      }),
    ).copyWith(
      secondary: AppColors.accentRed,
      primary: AppColors.primaryRed,
      background: AppColors.lightBackground,
      surface: AppColors.cardBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),

    // AppBar Theme: consistent look for all AppBars
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardBackground, // White app bar background
      foregroundColor: Colors.black, // Dark text/icon color on app bar
      elevation: 0, // Flat design, no shadow
      centerTitle: true, // Center app bar titles by default
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Card Theme: consistent look for all Card widgets
    cardTheme: CardThemeData(
      elevation: 2, // Subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      color: AppColors.cardBackground, // White background for cards
    ),

    // Input Decoration Theme: consistent look for all TextFormFields
    inputDecorationTheme: InputDecorationTheme(
      filled: true, // Input fields will have a background fill
      fillColor: AppColors.inputFillColor, // Light grey fill color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for input fields
        borderSide: BorderSide.none, // No visible border line
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Padding inside input field
      labelStyle: const TextStyle(color: AppColors.greyText), // Label text color
      hintStyle: const TextStyle(color: AppColors.greyHint), // Hint text color
      prefixIconColor: AppColors.greyHint, // Color for prefix icons
      suffixIconColor: AppColors.greyHint, // Color for suffix icons
    ),

    // ElevatedButton Theme: consistent look for all ElevatedButtons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed, // Red background for main buttons
        foregroundColor: Colors.white, // White text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(vertical: 16), // Vertical padding
        elevation: 5, // Subtle shadow for depth
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Consistent text style
      ),
    ),

    // TextButton Theme: consistent look for all TextButtons (like "Sign Up", "Forgot Password")
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryRed, // Red color for text links
        textStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold text
      ),
    ),

    // Checkbox Theme: consistent look for Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryRed; // Red when checked
        }
        return Colors.grey; // Grey when unchecked
      }),
      checkColor: WidgetStateProperty.all(Colors.white), // White checkmark
    ),

    // Define a TextTheme for consistent typography across the app
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.w300, color: Colors.black87),
      displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.w300, color: Colors.black87),
      displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.w400, color: Colors.black87),
      headlineMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w400, color: Colors.black87),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black87),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87), // AppBar titles, section headers
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87), // General body text
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black87), // Smaller body text, list item subtitles
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 148, 145, 145)), // For button text (overridden by ElevatedButtonTheme)
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black54), // Hint text, small details
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black54), // Very small text
    ),
  );
}