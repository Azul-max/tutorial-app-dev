import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import 'SignInPage.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _targetCaloriesController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;

  String? _gender;
  String? _activityLevel;
  String? _goalType;

  File? _imageFile;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _targetCaloriesController = TextEditingController();
    _currentWeightController = TextEditingController();
    _targetWeightController = TextEditingController();
    _heightController = TextEditingController();
    _ageController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _targetCaloriesController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load user account details
    final String? storedUsersJson = prefs.getString('registered_users');
    if (storedUsersJson != null) {
      final Map<String, dynamic> decodedUsers = jsonDecode(storedUsersJson);
      final String normalizedUsername = widget.name.toLowerCase();
      if (decodedUsers.containsKey(normalizedUsername)) {
        final user = decodedUsers[normalizedUsername];
        setState(() {
          _nameController.text = user['username'] ?? widget.name;
          _emailController.text = user['email'] ?? widget.email;
          _targetCaloriesController.text = user['targetCalories']?.toString() ?? '2000';
          _imagePath = user['profileImagePath'];
          if (_imagePath != null && _imagePath!.isNotEmpty) {
            _imageFile = File(_imagePath!);
          }
        });
      }
    }

    // Load user goals data
    final String? userGoalsJson = prefs.getString('userGoals');
    if (userGoalsJson != null) {
      try {
        final Map<String, dynamic> goals = jsonDecode(userGoalsJson);
        setState(() {
          _currentWeightController.text = (goals['currentWeight'] ?? '').toString();
          _targetWeightController.text = (goals['targetWeight'] ?? '').toString();
          _gender = goals['gender'];
          _heightController.text = (goals['height'] ?? '').toString();
          _ageController.text = (goals['age'] ?? '').toString();
          _activityLevel = goals['activityLevel'];
          _goalType = goals['goalType'];
          // Also load targetCalories if present in goals
          if (goals['targetCalories'] != null) {
            _targetCaloriesController.text = goals['targetCalories'].toString();
          }
        });
      } catch (e) {
        setState(() {
          _currentWeightController.clear();
          _targetWeightController.clear();
          _gender = null;
          _heightController.clear();
          _ageController.clear();
          _activityLevel = null;
          _goalType = null;
        });
      }
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please correct the errors in the form.')),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String storedUsersJson = prefs.getString('registered_users') ?? '{}';
    Map<String, dynamic> users = jsonDecode(storedUsersJson);

    final String currentNormalizedUsername = widget.name.toLowerCase();
    final String newUsername = _nameController.text.trim();
    final String newNormalizedUsername = newUsername.toLowerCase();

    if (newUsername.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username cannot be empty.')),
        );
      }
      return;
    }

    if (currentNormalizedUsername != newNormalizedUsername) {
      if (users.containsKey(newNormalizedUsername)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already taken. Please choose another.')),
          );
        }
        return;
      }
      users.remove(currentNormalizedUsername);
    }

    Map<String, dynamic> currentUserData = users[currentNormalizedUsername] ?? {};

    // Save targetCalories as int if possible
    int? targetCaloriesInt = int.tryParse(_targetCaloriesController.text.trim());

    currentUserData.addAll({
      'username': newUsername,
      'email': _emailController.text.trim(),
      'password': currentUserData['password'] ?? '',
      'targetCalories': targetCaloriesInt ?? 2000,
      'profileImagePath': _imagePath,
    });

    users[newNormalizedUsername] = currentUserData;
    await prefs.setString('registered_users', jsonEncode(users));

    // Save Goal Data (including targetCalories)
    final Map<String, dynamic> userGoals = {
      'currentWeight': double.tryParse(_currentWeightController.text),
      'targetWeight': double.tryParse(_targetWeightController.text),
      'gender': _gender,
      'height': double.tryParse(_heightController.text),
      'age': int.tryParse(_ageController.text),
      'activityLevel': _activityLevel,
      'goalType': _goalType,
      'targetCalories': targetCaloriesInt ?? 2000,
    };
    await prefs.setString('userGoals', jsonEncode(userGoals));

    // Update loggedInUser if needed
    final String? loggedInUserJson = prefs.getString('loggedInUser');
    if (loggedInUserJson != null) {
      Map<String, dynamic> loggedInUser = jsonDecode(loggedInUserJson);
      if (loggedInUser['username']?.toLowerCase() == currentNormalizedUsername) {
        loggedInUser['username'] = newUsername;
        loggedInUser['email'] = _emailController.text.trim();
        await prefs.setString('loggedInUser', jsonEncode(loggedInUser));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile and Goals updated successfully!')),
      );
      Navigator.pop(context, true); // Return true to trigger refresh in MainMenuPage
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
    await prefs.remove('remember_me');
    await prefs.remove('last_remembered_username');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildProfileCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Theme.of(context).hintColor,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : null,
                      child: _imageFile == null
                          ? Icon(
                              Icons.person,
                              size: 70,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Information (Editable)
              _buildProfileCard(
                title: 'Account Information',
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetCaloriesController,
                    decoration: InputDecoration(
                      labelText: 'Daily Target Calories (kcal)',
                      prefixIcon: Icon(Icons.local_fire_department, color: Theme.of(context).primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a target calorie value';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Please enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Editable User Goals
              _buildProfileCard(
                title: 'My Goals & Health Data',
                children: [
                  TextFormField(
                    controller: _currentWeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Weight (kg)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 70.5',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your current weight';
                      if (double.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetWeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Weight (kg)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 65.0',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your target weight';
                      if (double.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Gender',
                    ),
                    hint: const Text('Select Gender'),
                    items: ['Male', 'Female'].map((String gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _gender = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 175',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your height';
                      if (double.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 30',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your age';
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Activity Level',
                    ),
                    hint: const Text('Select Activity Level'),
                    items: [
                      'Sedentary (little to no exercise)',
                      'Lightly active (light exercise/sports 1-3 days/week)',
                      'Moderately active (moderate exercise/sports 3-5 days/week)',
                      'Very active (hard exercise/sports 6-7 days/week)',
                      'Extremely active (very hard exercise/physical job)'
                    ].map((String level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _activityLevel = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your activity level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _goalType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Your Primary Goal',
                    ),
                    hint: const Text('Select Your Primary Goal'),
                    items: [
                      'Weight Loss',
                      'Weight Gain',
                      'Weight Maintenance',
                      'Muscle Gain'
                    ].map((String goal) {
                      return DropdownMenuItem(
                        value: goal,
                        child: Text(goal),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _goalType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your primary goal';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveProfileData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Save Profile'),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Logout'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}