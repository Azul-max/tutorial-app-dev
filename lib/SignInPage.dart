import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// Removed: import 'package:flutter_svg/flutter_svg.dart'; // No longer needed for Icon

import 'MainMenuPage.dart';
import 'SignUpPage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<Map<String, Map<String, String>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('registered_users');
    if (usersJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((key, value) => MapEntry(key, Map<String, String>.from(value)));
    }
    return {};
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String inputUsername = _usernameController.text.trim();
      final String normalizedUsername = inputUsername.toLowerCase();
      final String password = _passwordController.text;

      final users = await _loadUsers();

      if (users.containsKey(normalizedUsername) && users[normalizedUsername]?['password'] == password) {
        final String? userEmail = users[normalizedUsername]?['email'];

        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          await prefs.setString('last_remembered_username', normalizedUsername);
        } else {
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
            builder: (context) => MainMenuPage(username: inputUsername, email: userEmail ?? ''),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password. Please sign up if you do not have an account.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Updated for Earthy & Muted palette)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 167, 240, 104), // Muted Primary Green (darker for top left)
                  Color(0xFFDCEDC8), // Light Muted Secondary Green (lighter for bottom right)
                ],
              ),
            ),
          ),
          // Optional: Add an overlay for better text readability
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), // Lighter overlay for contrast
            ),
          ),
          // Content Scrollable View
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo (Now using a Flutter Icon)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Icon( // Changed from SvgPicture.asset to Icon
                        Icons.restaurant_menu, // A suitable food-related icon
                        size: 150, // Maintain a large size
                        color: const Color(0xFF689F38), // Muted Primary Green for logo
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Welcome Text
                    Text(
                      'Welcome to Calorie Tracker!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFFEEEEEE)), // Light Neutral for text
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in or Sign up to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFFBDBDBD)), // Hint/Subtle Text color
                    ),
                    const SizedBox(height: 32),

                    // Username Input Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF424242)), // Dark Neutral for icons
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE).withOpacity(0.9), // Light Neutral for fill
                        border: Theme.of(context).inputDecorationTheme.border,
                        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                        contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle?.copyWith(color: const Color(0xFF424242)), // Dark Neutral for label
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle?.copyWith(color: const Color(0xFFBDBDBD)), // Hint/Subtle Text color
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

                    // Password Input Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF424242)), // Dark Neutral for icons
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF424242), // Dark Neutral for visibility icon
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE).withOpacity(0.9), // Light Neutral for fill
                        border: Theme.of(context).inputDecorationTheme.border,
                        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                        contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle?.copyWith(color: const Color(0xFF424242)), // Dark Neutral for label
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle?.copyWith(color: const Color(0xFFBDBDBD)), // Hint/Subtle Text color
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
                            title: Text('Remember Me', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFEEEEEE))), // Light Neutral for text
                            value: _rememberMe,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _rememberMe = newValue!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF689F38), // Muted Primary Green for active state
                            checkColor: const Color(0xFFEEEEEE), // Light Neutral for checkmark
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
                            style: TextStyle(color: Color(0xFF689F38)), // Muted Primary Green for link
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF689F38), // Muted Primary Green
                        foregroundColor: Colors.white, // White text on button
                        shape: Theme.of(context).elevatedButtonTheme.style?.shape?.resolve({}),
                        padding: Theme.of(context).elevatedButtonTheme.style?.padding?.resolve({}),
                        elevation: Theme.of(context).elevatedButtonTheme.style?.elevation?.resolve({}),
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
                        Text(
                          "Don't have an account?",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFBDBDBD)), // Hint/Subtle Text color
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
                            style: TextStyle(color: Color(0xFF689F38)), // Muted Primary Green for link
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
