import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'MainMenuPage.dart'; // Adjust path if needed

class MyGoalsPage extends StatefulWidget {
  const MyGoalsPage({super.key});

  @override
  State<MyGoalsPage> createState() => _MyGoalsPageState();
}

class _MyGoalsPageState extends State<MyGoalsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for text input fields
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _targetCaloriesController = TextEditingController();

  // Variables for dropdown selections
  String? _gender;
  String? _activityLevel;
  String? _goalType;

  @override
  void dispose() {
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _targetCaloriesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userGoalsJson = prefs.getString('userGoals');
    if (userGoalsJson != null) {
      final Map<String, dynamic> goals = jsonDecode(userGoalsJson);
      setState(() {
        _currentWeightController.text = (goals['currentWeight'] ?? '').toString();
        _targetWeightController.text = (goals['targetWeight'] ?? '').toString();
        _heightController.text = (goals['height'] ?? '').toString();
        _ageController.text = (goals['age'] ?? '').toString();
        _targetCaloriesController.text = (goals['targetCalories'] ?? '').toString();
        _gender = goals['gender'];
        _activityLevel = goals['activityLevel'];
        _goalType = goals['goalType'];
      });
    }
  }

  Future<void> _saveGoals() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      final double? currentWeight = double.tryParse(_currentWeightController.text);
      final double? targetWeight = double.tryParse(_targetWeightController.text);
      final double? height = double.tryParse(_heightController.text);
      final int? age = int.tryParse(_ageController.text);
      final int? targetCalories = int.tryParse(_targetCaloriesController.text);

      final Map<String, dynamic> userGoals = {
        'currentWeight': currentWeight ?? 0,
        'targetWeight': targetWeight ?? 0,
        'gender': _gender,
        'height': height ?? 0,
        'age': age ?? 0,
        'activityLevel': _activityLevel,
        'goalType': _goalType,
        'targetCalories': targetCalories ?? 0,
      };

      await prefs.setString('userGoals', jsonEncode(userGoals));
      print('Goals saved: ${jsonEncode(userGoals)}');

      final String? loggedInUserJson = prefs.getString('loggedInUser');
      if (loggedInUserJson != null) {
        final Map<String, dynamic> loggedInUser = jsonDecode(loggedInUserJson);
        final String username = loggedInUser['username'] ?? 'User';
        final String email = loggedInUser['email'] ?? 'No Email';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goals saved successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainMenuPage(
                username: username,
                email: email,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User session data not found. Please re-login.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields correctly.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Weight field (added)
              TextFormField(
                controller: _currentWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 70.0',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your target weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _targetCaloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily Target Calories (kcal)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your target calories';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
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
              const SizedBox(height: 32),

              Center(
                child: ElevatedButton(
                  onPressed: _saveGoals,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Save Goals & Continue'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}