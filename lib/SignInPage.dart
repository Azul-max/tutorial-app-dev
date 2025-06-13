import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      // Use a Stack to layer the background gradient and the content
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8), // Start with primary color
                  Theme.of(context).hintColor.withOpacity(0.9),    // End with accent color
                ],
              ),
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
                    // App Logo (Enhanced Prominence)
                    // Added more vertical padding around the logo
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Image.asset(
                        'assets/logo.png', // Ensure this path is correct in pubspec.yaml
                        height: 150, // Increased height for more prominence
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.fitness_center, size: 120, color: Colors.white); // Larger fallback
                        },
                      ),
                    ),
                    const SizedBox(height: 16), // Adjusted spacing

                    // Welcome Text
                    Text(
                      'Welcome to Calorie Tracker!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // White text for contrast
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in or Sign up to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70), // Lighter white
                    ),
                    const SizedBox(height: 32),

                    // Username Input Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: const Icon(Icons.person_outline), // Icon color from theme
                        // Inherit other styles from InputDecorationTheme
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9), // Slightly transparent white fill
                        border: Theme.of(context).inputDecorationTheme.border,
                        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                        contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle?.copyWith(color: Colors.black87), // Label color
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Hint color
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
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ), // Icon color from theme
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        // Inherit other styles from InputDecorationTheme
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9), // Slightly transparent white fill
                        border: Theme.of(context).inputDecorationTheme.border,
                        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                        contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
                        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle?.copyWith(color: Colors.black87),
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
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
                            title: Text('Remember Me', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)), // White text
                            value: _rememberMe,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _rememberMe = newValue!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: Colors.white, // White checkbox fill
                            checkColor: Theme.of(context).primaryColor, // Green checkmark
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Forgot Password functionality coming soon!')),
                            );
                          },
                          // TextButton style is now inherited from Theme.of(context).textButtonTheme
                          child: const Text(
                            'Forgot Password?',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign In Button
                    ElevatedButton(
                      style: Theme.of(context).elevatedButtonTheme.style, // Inherit button style from theme
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, // White spinner
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({}),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70), // Lighter white
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
