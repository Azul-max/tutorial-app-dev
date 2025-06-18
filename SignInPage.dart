import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'MainMenuPage.dart';
import 'SignUpPage.dart';
import 'MyGoalsPage.dart'; // <--- ADD THIS LINE: Import the MyGoalsPage

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
      final prefs = await SharedPreferences.getInstance(); // Get SharedPreferences instance here

      if (users.containsKey(normalizedUsername) && users[normalizedUsername]?['password'] == password) {
        final String? userEmail = users[normalizedUsername]?['email'];
        final String originalCaseUsername = users[normalizedUsername]?['username'] ?? inputUsername; // Get original case username

        // Save 'remember me' preference
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('last_remembered_username', normalizedUsername);
        } else {
          await prefs.remove('last_remembered_username');
        }

        // Store current logged-in user session data
        await prefs.setString('loggedInUser', jsonEncode({
          'username': originalCaseUsername,
          'email': userEmail,
        }));

        // --- NEW LOGIC: Check for existing goals ---
        final bool goalsSet = prefs.getString('userGoals') != null; // Check if userGoals data exists

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, $originalCaseUsername!')),
          );

          if (goalsSet) {
            // Goals are already set, navigate to MainMenuPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainMenuPage(username: originalCaseUsername, email: userEmail ?? ''),
              ),
            );
          } else {
            // Goals are NOT set, navigate to MyGoalsPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyGoalsPage(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password. Please sign up if you do not have an account.')),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We'll use a specific red color that matches the logo
    const Color logoRed = Color(0xFFC82333); // A deep red from the logo
    const Color buttonRed = Color(0xFF9E1D2A); // A slightly darker red for buttons

    return Scaffold(
      backgroundColor: logoRed, // Set the background to the logo's red
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Image.asset(
                    'assets/logo.png', // Your logo image path
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.fitness_center, size: 120, color: Colors.white);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Welcome Text
                Text(
                  'Welcome to Nutrio!', // Changed from Calorie Tracker as per logo
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or Sign up to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // Username Input Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey), // Icon visible on white fill
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9), // White background for text field
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none, // No border for cleaner look
                    ),
                    labelStyle: const TextStyle(color: Colors.grey), // Label text color
                    hintStyle: const TextStyle(color: Colors.grey), // Hint text color
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
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey), // Icon visible on white fill
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey, // Icon visible on white fill
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 255, 254, 254).withOpacity(0.9), // Grey background for text field
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: const TextStyle(color: Colors.grey), // Label text color
                    hintStyle: const TextStyle(color: Colors.grey), // Hint text color
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
                        title: Text(
                          'Remember Me',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        value: _rememberMe,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _rememberMe = newValue!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.white, // White checkbox when active
                        checkColor: logoRed, // Red checkmark on white
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
                        style: TextStyle(color: Colors.white), // White text for forgotten password link
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonRed, // Darker red for button background
                    foregroundColor: Colors.white, // White text on button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
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
                      : const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
                        style: TextStyle(color: Colors.white), // White text for Sign Up link
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