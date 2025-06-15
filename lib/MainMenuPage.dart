// lib/MainMenuPage.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Needed for jsonDecode

// Import other pages for navigation
import 'ProfilePage.dart';
import 'HistoryPage.dart';
import 'CaloriesCalculatorPage.dart';
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
  double _targetCalories = 2000; // Default or loaded from profile
  int _caloriesConsumedToday = 0; // This would typically come from History/Meals
  int _caloriesBurnedToday = 0; // New: Calories burned from exercises

  // Placeholder values for Carbs, Protein, Fat for UI demonstration
  // These would ideally come from actual calculated daily macros from your food entries
  int _carbsToday = 0;
  int _proteinToday = 0;
  int _fatToday = 0;

  // Placeholder total targets for macros (you might store these in user profile)
  int _totalCarbsTarget = 250; // Example target in grams
  int _totalProteinTarget = 150; // Example target in grams
  int _totalFatTarget = 70; // Example target in grams


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen for lifecycle changes
    _currentUsername = widget.username;
    _currentUserEmail = widget.email;
    _loadUserData();
    _loadCaloriesBurned(); // Load calories burned on init
    _loadCaloriesConsumed(); // Load consumed calories
    // _calculateMacrosForDisplay(); // This will be called after _loadCaloriesConsumed
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data when the app comes back to the foreground
    if (state == AppLifecycleState.resumed) {
      _loadCaloriesBurned();
      _loadCaloriesConsumed();
      _loadUserData(); // Also reload user data, in case profile target calories changed
      // _calculateMacrosForDisplay(); // This will be called after _loadCaloriesConsumed
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
          // You might also load macro targets here if stored in user data
          // _totalCarbsTarget = int.tryParse(user['targetCarbs'] ?? '250') ?? 250;
          // _totalProteinTarget = int.tryParse(user['targetProtein'] ?? '150') ?? 150;
          // _totalFatTarget = int.tryParse(user['targetFat'] ?? '70') ?? 70;
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

        // Check if it's a food entry and from today
        if (mealEntry['type'] == 'Food' &&
            entryDate.year == today.year &&
            entryDate.month == today.month &&
            entryDate.day == today.day) {
          totalConsumed += (mealEntry['cal'] as int? ?? 0);
          // Assuming your mealEntry also stores macros as double
          totalCarbs += (mealEntry['carbohydrates'] as num? ?? 0).round();
          totalProtein += (mealEntry['protein'] as num? ?? 0).round();
          totalFat += (mealEntry['fat'] as num? ?? 0).round();
        }
      } catch (e) {
        print('Error parsing meal entry: $e');
      }
    }
    setState(() {
      _caloriesConsumedToday = totalConsumed;
      _carbsToday = totalCarbs; // Use actual loaded data
      _proteinToday = totalProtein;
      _fatToday = totalFat;
    });
  }

  Future<void> _loadCaloriesBurned() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> mealsJson = prefs.getStringList('meals') ?? []; // 'meals' key used by ExercisePage
    int totalBurned = 0;
    final today = DateTime.now();

    for (String entryJson in mealsJson) {
      try {
        final Map<String, dynamic> entry = jsonDecode(entryJson);
        final entryDate = DateTime.parse(entry['dateTime']);

        // Check if the entry is an 'Exercise' and from today
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
    // Calculate net calories (assuming target - consumed + burned)
    int netCalories = (_targetCalories - _caloriesConsumedToday + _caloriesBurnedToday).round();
    // Ensure calories remaining doesn't go negative for display purposes
    int caloriesLeftDisplay = netCalories > 0 ? netCalories : 0;
    // Calculate the percentage for the progress indicator based on consumed vs. target
    double progressConsumed = _targetCalories == 0 ? 0 : _caloriesConsumedToday / _targetCalories;
    if (progressConsumed < 0) progressConsumed = 0;
    if (progressConsumed > 1) progressConsumed = 1;

    // Calculate the percentage for the progress indicator based on burned vs. target (just for visual filling)
    // This isn't a direct "progress" but indicates activity.
    double progressBurned = _targetCalories == 0 ? 0 : _caloriesBurnedToday / _targetCalories;
    if (progressBurned < 0) progressBurned = 0;
    if (progressBurned > 1) progressBurned = 1;


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use background color for app bar
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
            icon: Icon(Icons.account_circle, color: Theme.of(context).primaryColor), // Use primary color for icon
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
                _loadUserData(); // Reload user data (including target calories)
                _loadCaloriesConsumed(); // In case profile affects meal tracking
                _loadCaloriesBurned(); // In case profile affects exercise tracking
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
            // Daily Calorie Summary Card (Mimicking the NEW image)
            Card(
              elevation: 6, // Increased elevation for a more prominent look
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
                            color: Colors.grey[850], // Darker text
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
                    SizedBox( // Fixed height for this section to control vertical spacing
                      height: 180, // Adjust height as needed to fit content
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute evenly
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Eaten Column (Left)
                          _buildTopCalorieStat('Eaten', _caloriesConsumedToday, Colors.grey[800]!),
                          
                          // Central Calories Remaining with Circular Progress Bar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150, // Smaller circle
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: progressConsumed, // Show progress based on eaten
                                  strokeWidth: 10,
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), // Lighter background for the circle
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor), // Green for the filled part
                                  strokeCap: StrokeCap.round, // Rounded ends for the progress
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$caloriesLeftDisplay', // Display calculated calories left
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith( // Adjusted font size
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor, // Green color for the main number
                                    ),
                                  ),
                                  Text(
                                    'Remaining', // "Remaining" under the number
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Burned Column (Right)
                          _buildTopCalorieStat('Burned', _caloriesBurnedToday, Colors.grey[800]!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25), // Increased spacing

                    // Carbs, Protein, Fat section (bottom of the card)
                    Column(
                      children: [
                        IntrinsicHeight( // Ensures all children in the row have the same height
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMacroProgressStat(
                                  'Carbs', _carbsToday, _totalCarbsTarget, Colors.blue.shade400),
                              VerticalDivider(color: Colors.grey.shade300, thickness: 1, indent: 5, endIndent: 5),
                              _buildMacroProgressStat(
                                  'Protein', _proteinToday, _totalProteinTarget, Colors.blue.shade400),
                              VerticalDivider(color: Colors.grey.shade300, thickness: 1, indent: 5, endIndent: 5),
                              _buildMacroProgressStat(
                                  'Fat', _fatToday, _totalFatTarget, Colors.blue.shade400),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Action Buttons (no changes in this section from previous step)
            _buildActionCard(
              context,
              Icons.restaurant_menu,
              'Log Meal',
              'Record your food intake',
              () async {
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

            // Daily Calorie Progress (This section will be redundant with the new card design,
            // but keeping it for now if you still want it. Otherwise, remove this block.)
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

  // NEW helper for the top "Eaten" / "Burned" stats
  Widget _buildTopCalorieStat(String label, int value, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toStringAsFixed(0), // Format to remove decimals
          style: Theme.of(context).textTheme.displaySmall?.copyWith( // Larger numbers
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Adjusted label size
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // NEW helper for Carbs, Protein, Fat with progress bars
  Widget _buildMacroProgressStat(String label, int current, int total, Color progressColor) {
    double progress = total == 0 ? 0 : current / total;
    if (progress < 0) progress = 0;
    if (progress > 1.0) progress = 1.0;

    return Expanded(
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
            width: double.infinity, // Take full width of expanded space
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8, // Thinner bar
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

  // Existing _buildProgressItem (from Daily Calorie Progress section at the bottom)
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