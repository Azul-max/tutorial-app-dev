// main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: Import for SharedPreferences
import 'dart:convert'; // NEW: Import for jsonDecode

import 'SignInPage.dart';
import 'MainMenuPage.dart';
import 'ProfilePage.dart';
import 'HistoryPage.dart';
import 'CaloriesCalculatorPage.dart';
import 'CreateFoodPage.dart';
import 'ExercisePage.dart';
import 'RecipeSuggestionPage.dart';

import 'SignUpPage.dart';

// Shared history list (can be used for other pages if needed)
List<Map<String, dynamic>> globalMealHistory = [];

void main() {
  runApp(const MyApp()); // Made MyApp const
}

class MyApp extends StatefulWidget { // Changed to StatefulWidget for async initial route
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _initialPage = const SizedBox.shrink(); // Placeholder during loading

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status on app start
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? false;
    final String? lastUsername = prefs.getString('last_remembered_username');

    if (rememberMe && lastUsername != null && lastUsername.isNotEmpty) {
      // Simulate a quick check if this user still exists (optional, could be more robust)
      final usersJson = prefs.getString('registered_users');
      if (usersJson != null) {
        final Map<String, dynamic> decodedUsers = jsonDecode(usersJson);
        // Ensure the normalized username actually exists in registered users
        if (decodedUsers.containsKey(lastUsername)) {
          setState(() {
            // Navigate directly to MainMenuPage with the remembered username
            _initialPage = MainMenuPage(username: lastUsername);
          });
          return; // Exit if auto-login is successful
        }
      }
    }
    // If no auto-login, go to SignInPage
    setState(() {
      _initialPage = const SignInPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      // No initialRoute needed as we're managing it with _initialPage
      home: _initialPage, // Use the dynamically determined initial page
      routes: {
        // Define other named routes
        '/mainMenu': (context) => MainMenuPage(username: 'user'), // Placeholder username, ideally passed from SignIn/SignUp
        '/profile': (context) => ProfilePage(name: 'User', email: 'user@example.com', targetCalories: 2000), // Placeholder
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
