// main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for jsonDecode

// Import all your application pages
import 'SignInPage.dart';
import 'MainMenuPage.dart';
import 'ProfilePage.dart';
import 'HistoryPage.dart';
import 'CaloriesCalculatorPage.dart';
import 'CreateFoodPage.dart';
import 'ExercisePage.dart'; // Ensure this page exists or remove its route
import 'RecipeSuggestionPage.dart'; // Ensure this page exists or remove its route
import 'SignUpPage.dart';

// Shared history list (can be used for other pages if needed)
List<Map<String, dynamic>> globalMealHistory = [];

void main() {
  // It's good practice to ensure Flutter binding is initialized before running the app,
  // especially if you perform async operations like SharedPreferences in main.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // _initialPage will hold the widget that should be displayed first (SignInPage or MainMenuPage)
  Widget _initialPage = const SizedBox.shrink(); // A tiny, invisible placeholder while loading

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Perform login check when the app starts
  }

  /// Checks the login status from SharedPreferences to determine the initial route.
  /// If "Remember Me" was selected and a valid username is remembered, auto-logs in.
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? false;
    final String? lastUsername = prefs.getString('last_remembered_username');

    if (rememberMe && lastUsername != null && lastUsername.isNotEmpty) {
      // Optional: Re-verify if the remembered user still exists in registered users
      final usersJson = prefs.getString('registered_users');
      if (usersJson != null) {
        final Map<String, dynamic> decodedUsers = jsonDecode(usersJson);
        // Check if the normalized username (as stored) is in our registered users
        if (decodedUsers.containsKey(lastUsername)) {
          // Retrieve the email associated with the lastUsername
          final String? userEmail = decodedUsers[lastUsername]?['email'];
          setState(() {
            // If auto-login is successful, set MainMenuPage as the initial page
            // Note: We pass the username stored, assuming it was normalized upon saving.
            _initialPage = MainMenuPage(username: lastUsername, email: userEmail ?? '');
          });
          return; // Exit as we've determined the initial page
        }
      }
    }
    // If no auto-login, or if remembered user not found, default to SignInPage
    setState(() {
      _initialPage = const SignInPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      // The 'home' property is used to display the initial widget dynamically.
      // It will show a blank screen (_initialPage) until _checkLoginStatus completes.
      home: _initialPage,
      
      // Define a consistent theme for the entire application
      theme: ThemeData(
        // Primary color for your app's main branding and interactive elements
        primaryColor: const Color(0xFF8BC34A), // A vibrant green
        // Accent color, can be used for secondary actions or highlights
        hintColor: const Color(0xFFC8E6C9), // A lighter, softer green
        
        // Define default background colors for Scaffold and Canvas
        scaffoldBackgroundColor: const Color(0xFFE3F1EC), // Light background for most pages
        canvasColor: const Color(0xFFE3F1EC), // Used by Drawer, BottomSheet etc.
        
        // AppBar Theme: consistent look for all AppBars
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // White app bar background
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
        cardTheme: CardThemeData( // Changed CardTheme to CardThemeData
          elevation: 2, // Subtle shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          // Removed 'margin' as it's better handled by parent widgets like ListView.builder
          // margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Default margin for cards
        ),

        // Input Decoration Theme: consistent look for all TextFormFields
        inputDecorationTheme: InputDecorationTheme(
          filled: true, // Input fields will have a background fill
          fillColor: Colors.grey[100], // Light grey fill color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners for input fields
            borderSide: BorderSide.none, // No visible border line
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Padding inside input field
          labelStyle: const TextStyle(color: Colors.black54), // Label text color
          hintStyle: const TextStyle(color: Colors.grey), // Hint text color
          prefixIconColor: Colors.grey, // Color for prefix icons
          suffixIconColor: Colors.grey, // Color for suffix icons
        ),

        // ElevatedButton Theme: consistent look for all ElevatedButtons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8BC34A), // Green background for main buttons
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
            foregroundColor: const Color(0xFF8BC34A), // Green color for text links
            textStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold text
          ),
        ),
        
        // Checkbox Theme: consistent look for Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF8BC34A); // Green when checked
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
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white), // For button text (overridden by ElevatedButtonTheme)
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black54), // Hint text, small details
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black54), // Very small text
        ),

        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
            .copyWith(secondary: const Color(0xFFC8E6C9)), // Define secondary color
      ),

      // Define your application routes (for navigation between pages)
      routes: {
        // Note: The '/' route is handled by 'home: _initialPage' above.
        // These routes are used when you use Navigator.pushNamed().
        '/mainMenu': (context) => MainMenuPage(username: 'user'), // Placeholder username, ideally passed from SignIn/SignUp
        '/profile': (context) => ProfilePage(name: 'User', email: 'user@example.com'), // REMOVED targetCalories
        '/history': (context) => const HistoryPage(),
        '/calculator': (context) => const CaloriesCalculatorPage(),
        '/createFood': (context) => const CreateFoodPage(),
        '/exercise': (context) => const ExercisePage(),
        '/recipes': (context) => const RecipeSuggestionPage(),
        '/signUp': (context) => const SignUpPage(),
      },
    );
  }
}
