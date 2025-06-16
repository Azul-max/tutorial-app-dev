// lib/MainMenuPage.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Import other pages for navigation
import 'ProfilePage.dart';
import 'HistoryPage.dart';
import 'CaloriesCalculatorPage.dart'; // This is your "Create Food" page
import 'ExercisePage.dart';
import 'RecipeSuggestionPage.dart';

class MainMenuPage extends StatefulWidget {
  final String username;
  final String email;

  const MainMenuPage({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> with WidgetsBindingObserver {
  String _currentUsername = 'Guest';
  String _currentUserEmail = '';
  double _targetCalories = 2000;
  int _caloriesConsumedToday = 0;
  int _caloriesBurnedToday = 0;

  int _carbsToday = 0;
  int _proteinToday = 0;
  int _fatToday = 0;

  int _totalCarbsTarget = 250;
  int _totalProteinTarget = 150;
  int _totalFatTarget = 70;

  // Removed: TextEditingController _quickFoodNameController

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUsername = widget.username;
    _currentUserEmail = widget.email;
    _loadUserData();
    _loadCaloriesBurned();
    _loadCaloriesConsumed();
  }

  @override
  void dispose() {
    // Removed: _quickFoodNameController.dispose(); // Dispose the controller
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCaloriesBurned();
      _loadCaloriesConsumed();
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedUserJson = prefs.getString('registered_users');
    if (storedUserJson != null) {
      final Map<String, dynamic> decodedUsers = jsonDecode(storedUserJson);
      if (decodedUsers.containsKey(_currentUsername)) {
        final user = decodedUsers[_currentUsername];
        setState(() {
          _currentUserEmail = user['email'] ?? '';
          _targetCalories = double.tryParse(user['targetCalories'] ?? '2000') ?? 2000;
        });
      }
    }
  }

  Future<void> _loadCaloriesConsumed() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> mealsJson = prefs.getStringList('meals') ?? [];
    int totalConsumed = 0;
    int totalCarbs = 0;
    int totalProtein = 0;
    int totalFat = 0;

    final today = DateTime.now();

    for (String mealEntryJson in mealsJson) {
      try {
        final Map<String, dynamic> mealEntry = jsonDecode(mealEntryJson);
        final entryDate = DateTime.parse(mealEntry['dateTime']);

        // Check if the entry is for today and is either 'Food' OR 'Meal'
        if ((mealEntry['type'] == 'Food' || mealEntry['type'] == 'Meal') &&
            entryDate.year == today.year &&
            entryDate.month == today.month &&
            entryDate.day == today.day) {
          totalConsumed += (mealEntry['cal'] as int? ?? 0);

          // Corrected macro keys to match MealSummaryPage's saving format
          totalCarbs += (mealEntry['carbs'] as int? ?? 0);
          totalProtein += (mealEntry['protein'] as int? ?? 0);
          totalFat += (mealEntry['fat'] as int? ?? 0);
        }
      } catch (e) {
        print('Error parsing meal entry: $e');
      }
    }
    setState(() {
      _caloriesConsumedToday = totalConsumed;
      _carbsToday = totalCarbs;
      _proteinToday = totalProtein;
      _fatToday = totalFat;
    });
  }

  Future<void> _loadCaloriesBurned() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> mealsJson = prefs.getStringList('meals') ?? [];
    int totalBurned = 0;
    final today = DateTime.now();

    for (String entryJson in mealsJson) {
      try {
        final Map<String, dynamic> entry = jsonDecode(entryJson);
        final entryDate = DateTime.parse(entry['dateTime']);

        if (entry['type'] == 'Exercise' &&
            entryDate.year == today.year &&
            entryDate.month == today.month &&
            entryDate.day == today.day) {
          totalBurned += (entry['cal'] as int? ?? 0);
        }
      } catch (e) {
        print('Error parsing exercise entry: $e');
      }
    }
    setState(() {
      _caloriesBurnedToday = totalBurned;
    });
  }

  @override
  Widget build(BuildContext context) {
    int netCalories = (_targetCalories - _caloriesConsumedToday + _caloriesBurnedToday).round();
    int caloriesLeftDisplay = netCalories > 0 ? netCalories : 0;
    double progressConsumed = _targetCalories == 0 ? 0 : _caloriesConsumedToday / _targetCalories;
    if (progressConsumed < 0) progressConsumed = 0;
    if (progressConsumed > 1) progressConsumed = 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              _currentUsername,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    name: _currentUsername,
                    email: _currentUserEmail,
                  ),
                ),
              ).then((_) {
                _loadUserData();
                _loadCaloriesConsumed();
                _loadCaloriesBurned();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Calorie Summary Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Calorie Goal',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[850],
                          ),
                        ),
                        Text(
                          'Today',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildTopCalorieStat('Eaten', _caloriesConsumedToday, Colors.grey[800]!),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: progressConsumed,
                                  strokeWidth: 10,
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$caloriesLeftDisplay',
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'Remaining',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _buildTopCalorieStat('Burned', _caloriesBurnedToday, Colors.grey[800]!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMacroProgressStat(
                                  'Carbs', _carbsToday, _totalCarbsTarget, Theme.of(context).colorScheme.secondary),
                              VerticalDivider(color: Colors.grey.shade300, thickness: 1, indent: 5, endIndent: 5),
                              _buildMacroProgressStat(
                                  'Protein', _proteinToday, _totalProteinTarget, Theme.of(context).colorScheme.secondary),
                              VerticalDivider(color: Colors.grey.shade300, thickness: 1, indent: 5, endIndent: 5),
                              _buildMacroProgressStat(
                                  'Fat', _fatToday, _totalFatTarget, Theme.of(context).colorScheme.secondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Removed: Quick Food Input Section
            // Card(...), // This entire Card widget is removed

            // Main Action Buttons
            _buildActionCard(
              context,
              Icons.restaurant_menu,
              'Log Meal',
              'Record your food intake',
              () async {
                // This button will now navigate directly to CaloriesCalculatorPage
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CaloriesCalculatorPage()),
                );
                _loadCaloriesConsumed();
                _loadCaloriesBurned();
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              Icons.directions_run,
              'Log Exercise',
              'Track your burned calories',
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExercisePage()),
                );
                _loadCaloriesBurned();
                _loadCaloriesConsumed();
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              Icons.history,
              'View History',
              'Review past activities',
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
                _loadCaloriesConsumed();
                _loadCaloriesBurned();
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              Icons.lightbulb_outline,
              'Recipe Suggestions',
              'Discover healthy meals',
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipeSuggestionPage()),
                );
                _loadCaloriesConsumed();
                _loadCaloriesBurned();
              },
            ),
            const SizedBox(height: 20),

            // Daily Calorie Progress (You can choose to keep or remove this section
            // as the new summary card covers similar info)
            Text(
              'Daily Calorie Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15),
            _buildProgressItem(
              context,
              'Eaten',
              _caloriesConsumedToday,
              _targetCalories.round(),
              Colors.orange.shade700,
            ),
            const SizedBox(height: 10),
            _buildProgressItem(
              context,
              'Burned',
              _caloriesBurnedToday,
              _targetCalories.round(),
              Colors.blue.shade700,
            ),
            const SizedBox(height: 10),
            _buildProgressItem(
              context,
              'Remaining',
              caloriesLeftDisplay,
              _targetCalories.round(),
              Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Removed: _navigateToCaloriesCalculator method

  // Helper for the top "Eaten" / "Burned" stats
  Widget _buildTopCalorieStat(String label, int value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toStringAsFixed(0),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Helper for Carbs, Protein, Fat with progress bars
  Widget _buildMacroProgressStat(String label, int current, int total, Color progressColor) {
    double progress = total == 0 ? 0 : current / total;
    if (progress < 0) progress = 0;
    if (progress > 1.0) progress = 1.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding to separate columns slightly
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$current / $total g',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Existing _buildActionCard
  Widget _buildActionCard(
      BuildContext context, IconData icon, String title, String subtitle, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[850],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // Existing _buildProgressItem
  Widget _buildProgressItem(
      BuildContext context, String label, int current, int total, Color color) {
    double progress = total == 0 ? 0 : current / total;
    if (progress < 0) progress = 0;
    if (progress > 1.0) progress = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Text(
              '$current kcal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}