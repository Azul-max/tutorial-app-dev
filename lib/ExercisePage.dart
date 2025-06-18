// lib/Module/ExercisePage.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Still needed for init and direct calls
import 'dart:convert'; // Still needed for direct calls
// import 'package:intl/intl.dart'; // THIS LINE IS NOW REMOVED - it's used in _exercise_ui_widgets.dart

// Import the new data manager and UI widgets
import '_exercise_data_manager.dart';
import '_exercise_ui_widgets.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _caloriesBurnedController = TextEditingController();
  final _durationController = TextEditingController();
  final _searchController = TextEditingController();

  // Data & State variables
  Map<String, dynamic>? _userProfile; // For profile dialog
  List<Map<String, dynamic>> _recentExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  String? _selectedExercise;
  int? _calculatedDuration;
  double _weeklyProgress = 0.0;
  bool _showMotivation = false;
  String _motivationMessage = '';
  String _filterPeriod = 'All';
  String _sortBy = 'Newest';

  // Constants (moved from data manager for simplicity, can be moved further if needed)
  final List<String> _exerciseSuggestions = [
    'Running', 'Cycling', 'Swimming', 'Walking', 'Yoga',
    'Weight Training', 'HIIT', 'Pilates', 'Dancing', 'Jump Rope'
  ];
  final Map<String, double> _exerciseRates = {
    'Running': 10.0, 'Cycling': 7.0, 'Swimming': 8.0, 'Walking': 4.0,
    'Yoga': 3.0, 'Weight Training': 5.0, 'HIIT': 12.0, 'Pilates': 4.0,
    'Dancing': 6.0, 'Jump Rope': 11.0,
  };
  final List<String> _motivationalMessages = [
    "You're doing amazing! Keep pushing! 💪", "Every minute counts! You've got this! 🔥",
    "Your future self will thank you! 🌟", "Stronger than yesterday! Keep going! 🚀",
    "Pain is temporary, pride is forever! ✨", "Make sweat your best accessory today! 💦",
    "You're one step closer to your goals! 👟", "The only bad workout is the one you didn't do! 👍",
    "Your effort today is your result tomorrow! 🌈", "Beast mode activated! 🦁"
  ];


  // DataManager instance
  late ExerciseDataManager _dataManager;

  @override
  void initState() {
    super.initState();
    _dataManager = ExerciseDataManager(); // Initialize data manager
    _loadAllData();
    _caloriesBurnedController.addListener(_calculateDuration);
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _caloriesBurnedController.removeListener(_calculateDuration);
    _caloriesBurnedController.dispose();
    _durationController.dispose();
    _searchController.removeListener(_filterExercises);
    _searchController.dispose();
    super.dispose();
  }

  // Load all necessary data
  Future<void> _loadAllData() async {
    await _dataManager.loadUserProfile();
    await _dataManager.loadRecentExercises(); // Load all exercises first
    setState(() {
      _userProfile = _dataManager.userProfile;
      _recentExercises = _dataManager.recentExercises;
      _filterExercises(); // Apply initial filter (All)
      _calculateWeeklyProgress();
    });
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _dataManager.filterExercises(query, _filterPeriod, _sortBy);
    });
  }

  void _showMotivationalNotification() {
    final random = DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length;
    setState(() {
      _motivationMessage = _motivationalMessages[random];
      _showMotivation = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showMotivation = false;
        });
      }
    });
  }

  void _calculateDuration() {
    if (_selectedExercise != null && _caloriesBurnedController.text.isNotEmpty) {
      final calories = int.tryParse(_caloriesBurnedController.text) ?? 0;
      final rate = _exerciseRates[_selectedExercise] ?? 1.0;
      if (rate > 0) {
        setState(() {
          _calculatedDuration = (calories / rate).ceil();
          _durationController.text = _calculatedDuration?.toString() ?? '';
        });
      } else {
        setState(() {
          _calculatedDuration = null;
          _durationController.clear();
        });
      }
    } else {
      setState(() {
        _calculatedDuration = null;
        _durationController.clear();
      });
    }
  }

  void _calculateWeeklyProgress() {
    int weeklyCalorieTarget = _userProfile?['weeklyTarget'] ?? 5000;
    int totalCalories = _dataManager.getWeeklyCaloriesBurned();
    setState(() {
      _weeklyProgress = (totalCalories / weeklyCalorieTarget).clamp(0.0, 1.0);
    });
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    final newEntry = {
      'name': _exerciseController.text,
      'type': 'Exercise',
      'cal': int.tryParse(_caloriesBurnedController.text) ?? 0,
      'duration': int.tryParse(_durationController.text) ?? 0,
      'dateTime': DateTime.now().toIso8601String(),
    };

    await _dataManager.saveExercise(newEntry);

    _exerciseController.clear();
    _caloriesBurnedController.clear();
    _durationController.clear();
    setState(() {
      _selectedExercise = null;
      _calculatedDuration = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exercise saved!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(20),
          child: const Icon(Icons.check, color: Color.fromARGB(255, 175, 76, 76), size: 50),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Pop the dialog
      Navigator.pop(context, true); // Signal successful save to previous page
    });

    _loadAllData(); // Reload all data to update UI
    _showMotivationalNotification();
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_userProfile?['name'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Weight: ${_userProfile?['weight'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Height: ${_userProfile?['height'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Goal: ${_userProfile?['goal'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Weekly Target: ${_userProfile?['weeklyTarget'] ?? 'N/A'} cal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double value) {
    if (value < 0.25) return Colors.red;
    if (value < 0.5) return Colors.orange;
    if (value < 0.75) return Colors.lightGreen;
    return const Color.fromARGB(255, 230, 233, 230);
  }

  @override
  Widget build(BuildContext context) {
    int netCalories = (_userProfile?['targetCalories'] ?? 2000 - _dataManager.getTodayCaloriesBurned() + _dataManager.getTodayMinutesBurned()).round();
    int caloriesLeftDisplay = netCalories > 0 ? netCalories : 0; // Use dataManager for today's data

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 232, 232),
      appBar: AppBar(
        title: const Text('EXERCISE TRACKER', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color.fromARGB(255, 175, 76, 76),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: _showProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHOOSE YOUR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'EXERCISE TODAY',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              if (_showMotivation)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 230, 200, 200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _motivationMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick Add Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exerciseSuggestions.map((exercise) {
                  return FilterChip(
                    label: Text(exercise),
                    selected: _selectedExercise == exercise,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedExercise = exercise;
                          _exerciseController.text = exercise;
                        } else {
                          _selectedExercise = null;
                          _exerciseController.clear();
                        }
                      });
                      _calculateDuration();
                    },
                    selectedColor: const Color.fromARGB(255, 214, 165, 165),
                    checkmarkColor: const Color.fromARGB(255, 94, 27, 27),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Daily Summary
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("TODAY'S BURN"),
                          Text(
                            _dataManager.getTodayCaloriesBurned().toString(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text("calories"),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("ACTIVE TIME"),
                          Text(
                            "${_dataManager.getTodayMinutesBurned()} min",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text("minutes"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedExercise,
                      decoration: const InputDecoration(
                        labelText: 'Select Exercise',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      items: _exerciseSuggestions.map((exercise) {
                        return DropdownMenuItem<String>(
                          value: exercise,
                          child: Row(
                            children: [
                              Icon(ExerciseUIWidgets.getExerciseIcon(exercise)),
                              const SizedBox(width: 10),
                              Text(exercise),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedExercise = value;
                          _exerciseController.text = value ?? '';
                        });
                        _calculateDuration();
                      },
                      validator: (value) =>
                          value == null ? 'Please select an exercise' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _caloriesBurnedController,
                      decoration: const InputDecoration(
                        labelText: 'Calories (cal)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 300',
                        prefixIcon: Icon(Icons.local_fire_department),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter calories burned';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (min)',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., 60',
                        prefixIcon: const Icon(Icons.timer),
                        suffixText: _calculatedDuration != null
                            ? '(Calculated)'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 142, 56, 56),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'SAVE EXERCISE',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT EXERCISES',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      const Text("Filter: "),
                      DropdownButton<String>(
                        value: _filterPeriod,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Today', child: Text('Today')),
                          DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                        ],
                        onChanged: (value) {
                          setState(() => _filterPeriod = value!);
                          _filterExercises(); // Trigger filter after period change
                        },
                      ),
                      const SizedBox(width: 10),
                      const Text("Sort: "),
                      DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                          DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                          DropdownMenuItem(value: 'Calories', child: Text('Calories')),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                          _filterExercises(); // Trigger filter after sort change
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterExercises();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: _filteredExercises.isEmpty
                    ? const Center(child: Text('No exercises found for this filter/search.'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) => SizedBox(
                          width: 180,
                          child: ExerciseUIWidgets.buildExerciseCard(_filteredExercises[index]),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              ExerciseUIWidgets.buildWeeklySummary(_weeklyProgress, _userProfile?['weeklyTarget'] ?? 5000, _dataManager.getWeeklyCaloriesBurned(), _dataManager.getWeeklyMinutesBurned()),
            ],
          ),
        ),
      ),
    );
  }
}
