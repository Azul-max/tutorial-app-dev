// lib/Module/_exercise_data_manager.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExerciseDataManager {
  List<Map<String, dynamic>> _allExercises = [];
  Map<String, dynamic>? _userProfile; // To store main profile info (name, targetCalories)
  Map<String, dynamic>? _userGoals; // To store specific goal data (weight, height, goalType)

  List<Map<String, dynamic>> get recentExercises => _allExercises; // Getter for external access
  Map<String, dynamic>? get userProfile => _userProfile; // Getter for user profile

  Future<void> loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load logged-in user details to get username/email and target calories
    final String? loggedInUserJson = prefs.getString('loggedInUser');
    if (loggedInUserJson != null) {
      final Map<String, dynamic> loggedInUser = jsonDecode(loggedInUserJson);
      final String username = loggedInUser['username'] ?? 'User';

      // Now load the full user profile from 'registered_users' using the username
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

    // Load user goals data
    final String? userGoalsJson = prefs.getString('userGoals');
    if (userGoalsJson != null) {
      try {
        final Map<String, dynamic> goals = jsonDecode(userGoalsJson);
        _userGoals = {
          'currentWeight': (goals['currentWeight'] ?? 0.0),
          'targetWeight': (goals['targetWeight'] ?? 0.0),
          'gender': goals['gender'] ?? 'Not set',
          'height': (goals['height'] ?? 0.0),
          'age': (goals['age'] ?? 0),
          'activityLevel': goals['activityLevel'] ?? 'Not set',
          'goalType': goals['goalType'] ?? 'Not set',
        };
        // Update userProfile with more detailed goal info for display
        _userProfile ??= {}; // Initialize if null
        _userProfile!['weight'] = _userGoals!['currentWeight'].toStringAsFixed(1);
        _userProfile!['height'] = _userGoals!['height'].toStringAsFixed(1);
        _userProfile!['goal'] = _userGoals!['goalType'];
      } catch (e) {
        print('Error decoding user goals JSON in ExerciseDataManager: $e');
        _userGoals = null; // Clear if corrupted
      }
    }

    // Ensure weeklyTarget is set if not already from profile
    _userProfile ??= {};
    _userProfile!['weeklyTarget'] = (_userProfile!['targetCalories'] as int? ?? 2000) * 7; // Or a fixed 5000 as before
  }

  Future<void> loadRecentExercises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> exercises = prefs.getStringList('exercises') ?? [];

    _allExercises = exercises.map((e) {
      Map<String, dynamic> decoded = jsonDecode(e);
      return {
        'name': decoded['name'],
        'calories': decoded['cal'],
        'duration': decoded['duration'] ?? 0,
        'dateTime': DateTime.parse(decoded['dateTime']),
      };
    }).toList();
  }

  List<Map<String, dynamic>> filterExercises(String query, String filterPeriod, String sortBy) {
    List<Map<String, dynamic>> filtered = _allExercises.where((exercise) {
      final matchesQuery = exercise['name'].toLowerCase().contains(query);
      final DateTime now = DateTime.now();
      final DateTime exerciseDate = exercise['dateTime'];

      if (filterPeriod == 'Today') {
        return matchesQuery &&
               exerciseDate.year == now.year &&
               exerciseDate.month == now.month &&
               exerciseDate.day == now.day;
      }
      if (filterPeriod == 'This Week') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
        return matchesQuery && (exerciseDate.isAfter(startOfWeek) || exerciseDate.isAtSameMomentAs(startOfWeek));
      }
      return matchesQuery; // 'All'
    }).toList();

    filtered.sort((a, b) {
      if (sortBy == 'Newest') {
        return b['dateTime'].compareTo(a['dateTime']);
      }
      if (sortBy == 'Oldest') {
        return a['dateTime'].compareTo(b['dateTime']);
      }
      if (sortBy == 'Calories') {
        return b['calories'].compareTo(a['calories']);
      }
      return 0; // Default
    });
    return filtered;
  }

  Future<void> saveExercise(Map<String, dynamic> newEntry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> exercises = prefs.getStringList('exercises') ?? [];
    exercises.add(jsonEncode(newEntry));
    await prefs.setStringList('exercises', exercises);
    await loadRecentExercises(); // Reload internal list after saving
  }

  int getTodayCaloriesBurned() {
    DateTime today = DateTime.now();
    return _allExercises
        .where((ex) =>
            ex['dateTime'].day == today.day &&
            ex['dateTime'].month == today.month &&
            ex['dateTime'].year == today.year)
        .fold(0, (int sum, ex) => sum + (ex['calories'] as int));
  }

  int getTodayMinutesBurned() {
    DateTime today = DateTime.now();
    return _allExercises
        .where((ex) =>
            ex['dateTime'].day == today.day &&
            ex['dateTime'].month == today.month &&
            ex['dateTime'].year == today.year)
        .fold(0, (int sum, ex) => sum + (ex['duration'] as int));
  }

  int getWeeklyCaloriesBurned() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(
      hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return _allExercises
        .where((ex) => ex['dateTime'].isAfter(startOfWeek) || ex['dateTime'].isAtSameMomentAs(startOfWeek))
        .fold(0, (int sum, ex) => sum + (ex['calories'] as int));
  }

  int getWeeklyMinutesBurned() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(
      hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return _allExercises
        .where((ex) => ex['dateTime'].isAfter(startOfWeek) || ex['dateTime'].isAtSameMomentAs(startOfWeek))
        .fold(0, (int sum, ex) => sum + (ex['duration'] as int));
  }
}
