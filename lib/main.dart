// main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for jsonDecode

// Import your centralized theme file
import 'app_theme.dart'; // <--- NEW IMPORT: Import your centralized theme file

// Import all your application pages
import 'otherpage/SignInPage.dart';
import 'otherpage/MainMenuPage.dart';
import 'otherpage/ProfilePage.dart';
import 'Module/HistoryPage.dart';
import 'Module/Calories/CaloriesCalculatorPage.dart';
import 'Module/Calories/CreateFoodPage.dart';
import 'Module/Exercise/ExercisePage.dart';
import 'Module/RecipeSuggestionPage.dart';
import 'otherpage/SignUpPage.dart';
import 'otherpage/MyGoalsPage.dart';

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
  // _initialPage will hold the widget that should be displayed first (SignInPage, MyGoalsPage, or MainMenuPage)
  Widget _initialPage = const SizedBox.shrink(); // A tiny, invisible placeholder while loading

  @override
  void initState() {
    super.initState();
    _checkInitialNavigation(); // Renamed function for clarity
  }

  /// Checks login status and goal-setting status to determine the initial page.
  /// Flow: Is User Logged In? -> Are Goals Set? -> Appropriate Page.
  Future<void> _checkInitialNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? false;
    final String? lastUsernameNormalized = prefs.getString('last_remembered_username');
    final String? goalsJson = prefs.getString('userGoals'); // Check for goals data

    bool isLoggedIn = false;
    String? currentUsername;
    String? currentUserEmail;
    bool goalsSet = goalsJson != null; // True if 'userGoals' key exists

    if (rememberMe && lastUsernameNormalized != null && lastUsernameNormalized.isNotEmpty) {
      final usersJson = prefs.getString('registered_users');
      if (usersJson != null) {
        final Map<String, dynamic> decodedUsers = jsonDecode(usersJson);
        if (decodedUsers.containsKey(lastUsernameNormalized)) {
          final user = decodedUsers[lastUsernameNormalized];
          currentUsername = user['username']; // Get original case username
          currentUserEmail = user['email'];
          isLoggedIn = true; // User is effectively logged in via remember me
        }
      }
    }

    setState(() {
      if (isLoggedIn) {
        if (goalsSet) {
          // Logged in AND goals set -> Go to Main Menu
          _initialPage = MainMenuPage(username: currentUsername!, email: currentUserEmail!);
        } else {
          // Logged in BUT goals NOT set -> Go to My Goals Page
          _initialPage = const MyGoalsPage();
        }
      } else {
        // Not logged in -> Go to Sign In Page
        _initialPage = const SignInPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      // The 'home' property is used to display the initial widget dynamically.
      // It will show a blank screen (_initialPage) until _checkInitialNavigation completes.
      home: _initialPage,

      // Define a consistent theme for the entire application
      theme: AppTheme.darkTheme, // <--- USING THE CENTRALIZED THEME

      // Define your application routes (for navigation between pages)
      routes: {
        // SignInPage and MyGoalsPage are now the entry points after initial check
        '/signIn': (context) => const SignInPage(), // Explicitly define SignInPage route
        '/myGoals': (context) => const MyGoalsPage(), // MyGoalsPage route
        // This route is primarily for direct navigation via Navigator.pushNamed,
        // but the initial app entry is handled by _initialPage based on login status.
        // It's given placeholder data as the actual user data is handled by _initialPage.
        '/mainMenu': (context) => const MainMenuPage(username: 'user', email: 'user@example.com'),
        '/profile': (context) => const ProfilePage(name: 'User', email: 'user@example.com'),
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
