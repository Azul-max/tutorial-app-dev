import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for local storage
import 'dart:convert'; // Import for JSON encoding/decoding

import 'MainMenuPage.dart'; // Import your MainMenuPage
import 'SignUpPage.dart'; // Import the new SignUpPage

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State for password visibility
  bool _isPasswordVisible = false;
  // State for loading indicator
  bool _isLoading = false;
  // State for "Remember Me" functionality
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference(); // Load "Remember Me" state and potentially pre-fill username
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Loads the "Remember Me" preference and last username.
  Future<void> _loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        final String? lastUsername = prefs.getString('last_remembered_username');
        if (lastUsername != null) {
          _usernameController.text = lastUsername;
        }
      }
    });
  }

  /// Loads all registered users from SharedPreferences.
  /// Returns a map where key is username and value is a map containing 'password' and 'email'.
  Future<Map<String, Map<String, String>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('registered_users');
    if (usersJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((key, value) => MapEntry(key, Map<String, String>.from(value)));
    }
    return {};
  }

  /// Handles the sign-in logic.
  /// Checks credentials against locally stored registered users.
  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      // Normalize username for consistent comparison with signup
      final String inputUsername = _usernameController.text.trim(); // Keep original for display
      final String normalizedUsername = inputUsername.toLowerCase(); // Use normalized for lookup
      final String password = _passwordController.text;

      final users = await _loadUsers();

      if (users.containsKey(normalizedUsername) && users[normalizedUsername]?['password'] == password) {
        // Authentication successful
        final String? userEmail = users[normalizedUsername]?['email']; // Get email from stored data

        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          await prefs.setString('last_remembered_username', normalizedUsername); // Save normalized username
        } else {
          // If "Remember Me" is unchecked, clear any previously remembered info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', false);
          await prefs.remove('last_remembered_username');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back, $inputUsername!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Pass both original username and retrieved email
            builder: (context) => MainMenuPage(username: inputUsername, email: userEmail ?? ''),
          ),
        );
      } else {
        // Authentication failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password. Please sign up if you do not have an account.')),
        );
      }

      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.fitness_center, size: 100, color: Colors.grey);
                  },
                ),
                const SizedBox(height: 32),

                const Text(
                  'Welcome to Calorie Tracker!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in or Sign up to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    // Apply theme styles
                    border: Theme.of(context).inputDecorationTheme.border,
                    filled: Theme.of(context).inputDecorationTheme.filled,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    // Apply theme styles
                    border: Theme.of(context).inputDecorationTheme.border,
                    filled: Theme.of(context).inputDecorationTheme.filled,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Remember Me', style: TextStyle(color: Colors.black87)),
                        value: _rememberMe,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _rememberMe = newValue!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).primaryColor, // Apply theme primary color
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forgot Password functionality coming soon!')),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF8BC34A), // Still hardcoded for now, but theme will apply
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ?? const Color(0xFF8BC34A),
                    foregroundColor: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white,
                    shape: Theme.of(context).elevatedButtonTheme.style?.shape?.resolve({}) ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: Theme.of(context).elevatedButtonTheme.style?.padding?.resolve({}) ?? const EdgeInsets.symmetric(vertical: 16),
                    elevation: Theme.of(context).elevatedButtonTheme.style?.elevation?.resolve({}) ?? 5,
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({}),
                        ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        // Styles will be applied from Theme.of(context).textButtonTheme.style
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
