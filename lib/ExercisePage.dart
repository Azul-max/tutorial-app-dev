import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  ExercisePageState createState() => ExercisePageState();
}

class ExercisePageState extends State<ExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _caloriesBurnedController = TextEditingController();
  final _durationController = TextEditingController();
  final _searchController = TextEditingController();

  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _recentExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  String? _selectedExercise;
  int? _calculatedDuration;
  double _weeklyProgress = 0.0;
  bool _showMotivation = false;
  String _motivationMessage = '';
  String _filterPeriod = 'All';
  String _sortBy = 'Newest';

  // Constants for exercise suggestions and rates
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
    "You're doing amazing! Keep pushing! 💪", "Every minute counts! You've got this! �",
    "Your future self will thank you! 🌟", "Stronger than yesterday! Keep going! 🚀",
    "Pain is temporary, pride is forever! ✨", "Make sweat your best accessory today! 💦",
    "You're one step closer to your goals! 👟", "The only bad workout is the one you didn't do! 👍",
    "Your effort today is your result tomorrow! 🌈", "Beast mode activated! 🦁"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load user profile first
    _loadRecentExercises(); // Then load exercises and update progress
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

  // Filters exercises based on search query, period, and sort order.
  // This method updates _filteredExercises without calling setState,
  // expecting the caller to trigger setState.
  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    DateTime now = DateTime.now();

    List<Map<String, dynamic>> filtered = _recentExercises.where((exercise) {
      final matchesQuery = exercise['name'].toLowerCase().contains(query);
      final DateTime exerciseDate = exercise['dateTime'];

      if (_filterPeriod == 'Today') {
        return matchesQuery &&
            exerciseDate.year == now.year &&
            exerciseDate.month == now.month &&
            exerciseDate.day == now.day;
      }
      if (_filterPeriod == 'This Week') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
        return matchesQuery && (exerciseDate.isAfter(startOfWeek) || exerciseDate.isAtSameMomentAs(startOfWeek));
      }
      return matchesQuery; // 'All'
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'Newest') {
        return b['dateTime'].compareTo(a['dateTime']);
      }
      if (_sortBy == 'Oldest') {
        return a['dateTime'].compareTo(b['dateTime']);
      }
      if (_sortBy == 'Calories') {
        return b['calories'].compareTo(a['calories']);
      }
      return 0; // Default
    });

    _filteredExercises = filtered; // Update directly
  }

  // Displays a random motivational message as a temporary notification.
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

  // Calculates the duration of an exercise based on calories burned and exercise rate.
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

  // Loads user profile information from SharedPreferences.
  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? loggedInUserJson = prefs.getString('loggedInUser');
    if (loggedInUserJson != null) {
      final Map<String, dynamic> loggedInUser = jsonDecode(loggedInUserJson);
      final String username = loggedInUser['username'] ?? 'User';

      final String? storedUsersJson = prefs.getString('registered_users');
      if (storedUsersJson != null) {
        final Map<String, dynamic> decodedUsers = jsonDecode(storedUsersJson);
        final String normalizedUsername = username.toLowerCase();

        if (decodedUsers.containsKey(normalizedUsername)) {
          final user = decodedUsers[normalizedUsername];
          _userProfile = {
            'name': user['username'] ?? 'User Name',
            'targetCalories': int.tryParse(user['targetCalories']?.toString() ?? '0') ?? 2000,
          };
        }
      }
    }

    final String? userGoalsJson = prefs.getString('userGoals');
    if (userGoalsJson != null) {
      try {
        final Map<String, dynamic> goals = jsonDecode(userGoalsJson);
        _userProfile ??= {}; // Initialize if null
        _userProfile!['weight'] = (goals['currentWeight'] ?? 0.0).toStringAsFixed(1);
        _userProfile!['height'] = (goals['height'] ?? 0.0).toStringAsFixed(1);
        _userProfile!['goal'] = goals['goalType'] ?? 'Not set';
      } catch (e) {
        print('Error decoding user goals JSON: $e');
      }
    }

    _userProfile ??= {};
    _userProfile!['weeklyTarget'] = (_userProfile!['targetCalories'] as int? ?? 2000) * 7;

    setState(() {}); // Trigger rebuild after profile is loaded
  }

  // Loads recent exercises from SharedPreferences and applies filters/sorting.
  // Then triggers a single setState for UI update.
  Future<void> _loadRecentExercises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> exercises = prefs.getStringList('exercises') ?? [];

    List<Map<String, dynamic>> allExercises = exercises.map((e) {
      Map<String, dynamic> decoded = jsonDecode(e);
      return {
        'name': decoded['name'],
        'calories': decoded['cal'],
        'duration': decoded['duration'] ?? 0,
        'dateTime': DateTime.parse(decoded['dateTime']),
      };
    }).toList();

    _recentExercises = allExercises; // Update the master list immediately

    // Recalculate filtered exercises and weekly progress without separate setState calls
    _filterExercises();
    _calculateWeeklyProgress(); // This will update _weeklyProgress

    // Finally, trigger a single setState to rebuild the UI with all updated data
    setState(() {});
  }

  // Gets total calories burned for today.
  int _getTodayCalories() {
    DateTime today = DateTime.now();
    return _recentExercises
        .where((ex) =>
            ex['dateTime'].day == today.day &&
            ex['dateTime'].month == today.month &&
            ex['dateTime'].year == today.year)
        .fold(0, (int sum, ex) => sum + (ex['calories'] as int));
  }

  // Gets total active minutes for today.
  int _getTodayMinutes() {
    DateTime today = DateTime.now();
    return _recentExercises
        .where((ex) =>
            ex['dateTime'].day == today.day &&
            ex['dateTime'].month == today.month &&
            ex['dateTime'].year == today.year)
        .fold(0, (int sum, ex) => sum + (ex['duration'] as int));
  }

  // Calculates and updates the weekly progress (state variable).
  // This method updates _weeklyProgress, and is designed to be called
  // by _loadRecentExercises or directly by _saveExercise for immediate updates.
  void _calculateWeeklyProgress() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(
      hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    List<Map<String, dynamic>> weeklyExercises = _recentExercises.where((ex) =>
        ex['dateTime'].isAfter(startOfWeek) || ex['dateTime'].isAtSameMomentAs(startOfWeek)).toList();

    int weeklyCalorieTarget = _userProfile?['weeklyTarget'] ?? 5000;
    double progressValue;
    if (weeklyExercises.isNotEmpty && weeklyCalorieTarget > 0) {
      int totalCalories = weeklyExercises.fold(0, (int sum, ex) => sum + (ex['calories'] as int));
      progressValue = (totalCalories / weeklyCalorieTarget).clamp(0.0, 1.0);
    } else {
      progressValue = 0.0;
    }

    _weeklyProgress = progressValue; // Update _weeklyProgress directly
  }

  // Saves a new exercise entry to SharedPreferences.
  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> exercises = prefs.getStringList('exercises') ?? [];

    final newEntry = {
      'name': _exerciseController.text,
      'type': 'Exercise',
      'cal': int.tryParse(_caloriesBurnedController.text) ?? 0,
      'duration': int.tryParse(_durationController.text) ?? 0,
      'dateTime': DateTime.now().toIso8601String(),
    };

    exercises.add(jsonEncode(newEntry));
    await prefs.setStringList('exercises', exercises);

    // Clear controllers and reset selected exercise
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

    // Checkmark animation dialog
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
          child: const Icon(Icons.check, color: Colors.green, size: 50),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Pop the dialog
    });

    // Explicitly reload data and update progress within a setState
    // to ensure the UI rebuilds with the latest _weeklyProgress
    await _loadRecentExercises(); // This will update _recentExercises, _filteredExercises, and _weeklyProgress internally
    _showMotivationalNotification();
  }

  // Shows a dialog with user profile information.
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
            Text('Weight: ${_userProfile?['weight'] ?? 'N/A'} kg'),
            const SizedBox(height: 8),
            Text('Height: ${_userProfile?['height'] ?? 'N/A'} cm'),
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

  // Determines the appropriate icon for a given exercise name.
  IconData _getExerciseIcon(String exerciseName) {
    switch (exerciseName.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'walking':
        return Icons.directions_walk;
      case 'yoga':
        return Icons.self_improvement;
      case 'weight training':
        return Icons.fitness_center;
      case 'hiit':
        return Icons.timer;
      case 'pilates':
        return Icons.airline_seat_recline_normal;
      case 'dancing':
        return Icons.music_note;
      case 'jump rope':
        return Icons.cable;
      default:
        return Icons.sports;
    }
  }

  // Builds a card widget to display individual exercise details.
  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final exerciseImages = {
      'Running': 'assets/running.jpg',
      'Cycling': 'assets/cycling.jpeg', // Adjusted to .jpeg based on common image extensions
      'Swimming': 'assets/swimming.jpg',
      'Walking': 'assets/walking.jpg',
      'Yoga': 'assets/yoga.jpg',
      'Weight Training': 'assets/weight_training.jpg',
      'HIIT': 'assets/hiit.jpg',
      'Pilates': 'assets/pilates.jpg',
      'Dancing': 'assets/dancing.jpg',
      'Jump Rope': 'assets/jump_rope.jpg',
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              exerciseImages[exercise['name']] ?? 'assets/default.jpg',
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getExerciseIcon(exercise['name'])),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        exercise['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${exercise['calories']} cal'),
                    Text('${exercise['duration']} mins'),
                    Text(
                      DateFormat('hh:mm a').format(exercise['dateTime']),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Determines the color for the progress bar based on its value.
  Color _getProgressColor(double value) {
    if (value < 0.25) return Colors.red;
    if (value < 0.5) return Colors.orange;
    if (value < 0.75) return Colors.lightGreen;
    return Colors.green;
  }

  // Builds a summary card for weekly exercise progress.
  Widget _buildWeeklySummary() {
    int weeklyCalorieTarget = _userProfile?['weeklyTarget'] ?? 5000;
    // Recalculate totalCalories and totalMinutes here based on _recentExercises
    // to ensure they reflect the latest data for display in this widget.
    int totalCalories = _recentExercises
        .where((ex) => ex['dateTime'].isAfter(
            DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).copyWith(
              hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)))
        .fold(0, (int sum, ex) => sum + (ex['calories'] as int));
    int totalMinutes = _recentExercises
        .where((ex) => ex['dateTime'].isAfter(
            DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).copyWith(
              hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)))
        .fold(0, (int sum, ex) => sum + (ex['duration'] as int));

    // The _weeklyProgress field is now correctly updated by _calculateWeeklyProgress
    double progress = _weeklyProgress; 

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WEEKLY SUMMARY (Current Week)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calories Burned:'),
                Text(
                  '$totalCalories cal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Minutes:'),
                Text(
                  '$totalMinutes min',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress)),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}% of weekly goal'),
                Text(
                  '${(weeklyCalorieTarget - totalCalories).ceil()} cal remaining',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (progress >= 1.0)
              Text(
                'Congratulations! You\'ve reached your weekly goal! 🎉',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (progress > 0.75)
              Text(
                'You\'re crushing your goals! Keep it up! 🎯',
                style: TextStyle(
                  color: Colors.green[700],
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (progress > 0.5)
              Text(
                'Great progress! Halfway there! 💪',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (progress > 0.25)
              Text(
                'Good start! Keep going strong! 🔥',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 227, 227),
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
                            _getTodayCalories().toString(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text("calories"),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("ACTIVE TIME"),
                          Text(
                            "${_getTodayMinutes()} min",
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
                              Icon(_getExerciseIcon(exercise)),
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
                          setState(() {
                            _filterPeriod = value!;
                            _filterExercises(); // Trigger filter after period change
                          });
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
                          setState(() {
                            _sortBy = value!;
                            _filterExercises(); // Trigger filter after sort change
                          });
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
                          child: _buildExerciseCard(_filteredExercises[index]),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              _buildWeeklySummary(),
            ],
          ),
        ),
      ),
    );
  }
}
