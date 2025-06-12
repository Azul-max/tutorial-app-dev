import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _caloriesBurnedController = TextEditingController();

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> meals = prefs.getStringList('meals') ?? [];

    final newEntry = {
      'name': _exerciseController.text,
      'type': 'Exercise',
      'cal': int.tryParse(_caloriesBurnedController.text) ?? 0,
      'dateTime': DateTime.now().toIso8601String(),
    };

    meals.add(jsonEncode(newEntry));
    await prefs.setStringList('meals', meals);

    _exerciseController.clear();
    _caloriesBurnedController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exercise saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _exerciseController,
                decoration: InputDecoration(labelText: 'Exercise Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter exercise name' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _caloriesBurnedController,
                decoration: InputDecoration(labelText: 'Calories Burned'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter calories burned' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExercise,
                child: Text('Save Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
