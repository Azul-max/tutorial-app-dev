import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _caloriesBurnedController = TextEditingController();
  final _durationController = TextEditingController();
  final _searchController = TextEditingController();
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _recentExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  List<String> _exerciseSuggestions = [
    'Running',
    'Cycling',
    'Swimming',
    'Walking',
    'Yoga',
    'Weight Training',
    'HIIT',
    'Pilates',
    'Dancing',
    'Jump Rope'
  ];
  String? _selectedExercise;
  int? _calculatedDuration;
  double _weeklyProgress = 0.0;
  bool _showMotivation = false;
  String _motivationMessage = '';
  String _filterPeriod = 'All';
  String _sortBy = 'Newest';

  final Map<String, double> _exerciseRates = {
    'Running': 10.0,
    'Cycling': 7.0,
    'Swimming': 8.0,
    'Walking': 4.0,
    'Yoga': 3.0,
    'Weight Training': 5.0,
    'HIIT': 12.0,
    'Pilates': 4.0,
    'Dancing': 6.0,
    'Jump Rope': 11.0,
  };

  final List<String> _motivationalMessages = [
    "You're doing amazing! Keep pushing! 💪",
    "Every minute counts! You've got this! 🔥",
    "Your future self will thank you! 🌟",
    "Stronger than yesterday! Keep going! 🚀",
    "Pain is temporary, pride is forever! ✨",
    "Make sweat your best accessory today! 💦",
    "You're one step closer to your goals! 👟",
    "The only bad workout is the one you didn't do! 👍",
    "Your effort today is your result tomorrow! 🌈",
    "Beast mode activated! 🦁"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadRecentExercises();
    _caloriesBurnedController.addListener(_calculateDuration);
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _caloriesBurnedController.removeListener(_calculateDuration);
    _searchController.removeListener(_filterExercises);
    super.dispose();
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _recentExercises.where((exercise) {
        return exercise['name'].toLowerCase().contains(query);
      }).toList();
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
      setState(() {
        _calculatedDuration = (calories / rate).ceil();
        _durationController.text = _calculatedDuration?.toString() ?? '';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userProfile = {
        'name': prefs.getString('userName') ?? 'User Name',
        'weight': prefs.getString('userWeight') ?? '-- kg',
        'height': prefs.getString('userHeight') ?? '-- cm',
        'goal': prefs.getString('userGoal') ?? 'Maintain weight',
        'weeklyTarget': prefs.getInt('weeklyTarget') ?? 5000,
      };
    });
  }

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

    // Filter berdasarkan periode
    DateTime now = DateTime.now();
    setState(() {
      _recentExercises = allExercises.where((ex) {
        if (_filterPeriod == 'Today') {
          return ex['dateTime'].day == now.day && 
                 ex['dateTime'].month == now.month &&
                 ex['dateTime'].year == now.year;
        }
        if (_filterPeriod == 'This Week') {
          return ex['dateTime'].isAfter(now.subtract(const Duration(days: 7)));
        }
        return true;
      }).toList();
      
      // Sorting
      _recentExercises.sort((a, b) {
        if (_sortBy == 'Newest') {
          return b['dateTime'].compareTo(a['dateTime']);
        }
        if (_sortBy == 'Oldest') {
          return a['dateTime'].compareTo(b['dateTime']);
        }
        if (_sortBy == 'Calories') {
          return b['calories'].compareTo(a['calories']);
        }
        return 0;
      });
      
      _filteredExercises = _recentExercises;
      _calculateWeeklyProgress();
    });
  }

  int _getTodayCalories() {
    DateTime today = DateTime.now();
    return _recentExercises
        .where((ex) => ex['dateTime'].day == today.day)
        .fold(0, (int sum, ex) => sum + (ex['calories'] as int));
  }

  int _getTodayMinutes() {
    DateTime today = DateTime.now();
    return _recentExercises
        .where((ex) => ex['dateTime'].day == today.day)
        .fold(0, (int sum, ex) => sum + (ex['duration'] as int));
  }

  void _calculateWeeklyProgress() {
    DateTime now = DateTime.now();
    DateTime weekAgo = now.subtract(const Duration(days: 7));
    
    List<Map<String, dynamic>> weeklyExercises = _recentExercises.where((ex) => 
      ex['dateTime'].isAfter(weekAgo)).toList();
    
    int weeklyCalorieTarget = _userProfile?['weeklyTarget'] ?? 5000;
    
    if (weeklyExercises.isNotEmpty && weeklyCalorieTarget > 0) {
      int totalCalories = weeklyExercises.fold(0, (int sum, ex) => sum + (ex['calories'] as int));
      setState(() {
        _weeklyProgress = (totalCalories / weeklyCalorieTarget).clamp(0.0, 1.0);
      });
    } else {
      setState(() {
        _weeklyProgress = 0.0;
      });
    }
  }

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

    // Animasi ikon centang - PERBAIKAN DI SINI
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
      Navigator.pop(context);
    });

    _loadRecentExercises();
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
            Text('Name: ${_userProfile?['name']}'),
            const SizedBox(height: 8),
            Text('Weight: ${_userProfile?['weight']}'),
            const SizedBox(height: 8),
            Text('Height: ${_userProfile?['height']}'),
            const SizedBox(height: 8),
            Text('Goal: ${_userProfile?['goal']}'),
            const SizedBox(height: 8),
            Text('Weekly Target: ${_userProfile?['weeklyTarget']} cal'),
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

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final exerciseImages = {
      'Running': 'assets/running.jpg',
      'Cycling': 'assets/cycling.jpeg',
      'Swimming': 'assets/swimming.jpg',
      'Walking': 'assets/walking.jpg',
      'Yoga': 'assets/yoga.jpg',
      'Weight Training': 'assets/weight training.jpg',
      'HIIT': 'assets/hiit.jpg',
      'Pilates': 'assets/pilates.jpg',
      'Dancing': 'assets/dancing.jpg',
      'Jump Rope': 'assets/jump rope.jpg',
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
                child: const Icon(Icons.image_not_supported),
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
                    Icon(_getExerciseIcon(exercise['name']), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      exercise['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildWeeklySummary() {
    DateTime now = DateTime.now();
    DateTime weekAgo = now.subtract(const Duration(days: 7));
    
    List<Map<String, dynamic>> weeklyExercises = _recentExercises.where((ex) => 
      ex['dateTime'].isAfter(weekAgo)).toList();
    
    int totalExercises = weeklyExercises.length;
    int totalCalories = weeklyExercises.fold(0, (int sum, ex) => sum + (ex['calories'] as int));
    int totalMinutes = weeklyExercises.fold(0, (int sum, ex) => sum + (ex['duration'] as int));
    int weeklyCalorieTarget = _userProfile?['weeklyTarget'] ?? 5000;
    double progress = weeklyCalorieTarget > 0 
        ? (totalCalories / weeklyCalorieTarget).clamp(0.0, 1.0)
        : 0.0;
        
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WEEKLY SUMMARY (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exercises:'),
                Text(
                  '$totalExercises',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            if (progress > 0.75)
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

  Color _getProgressColor(double value) {
    if (value < 0.25) return Colors.red;
    if (value < 0.5) return Colors.orange;
    if (value < 0.75) return Colors.lightGreen;
    return Colors.green;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('EXERCISE TRACKER', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.green[50],
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
                    color: Colors.green[100],
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
                children: _exerciseSuggestions.map((exercise) {
                  return FilterChip(
                    label: Text(exercise),
                    onSelected: (selected) {
                      setState(() {
                        _selectedExercise = exercise;
                        _exerciseController.text = exercise;
                      });
                    },
                    selected: _selectedExercise == exercise,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Daily Summary
              Card(
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
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter calories burned' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (min)',
                        border: const OutlineInputBorder(),
                        suffixText: _calculatedDuration != null
                            ? 'Calculated'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter duration' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
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
                    'RECENT EXERCISE',
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
                          _loadRecentExercises();
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
                          _loadRecentExercises();
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
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: _filteredExercises.isEmpty
                    ? const Center(child: Text('No exercises found'))
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
