import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For loading meal data
import 'dart:convert'; // For JSON decoding
import 'package:intl/intl.dart'; // For date formatting

import 'ProfilePage.dart';
import 'ExercisePage.dart';
import 'RecipeSuggestionPage.dart';

class MainMenuPage extends StatefulWidget {
  final String username;
  final String email;

  const MainMenuPage({super.key, required this.username, this.email = ''});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0; // Default to Dashboard (Diary) tab
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      _FoodDiaryDashboard(username: widget.username), // Dashboard (Diary) is index 0
      const ExercisePage(), // Exercise is index 1
      const RecipeSuggestionPage(), // Recipes is index 2
      ProfilePage(name: widget.username, email: widget.email), // Profile is index 3
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is now within the Scaffold of MainMenuPage.
      // We are customizing it to match the screenshot: hamburger menu and calendar icon.
      appBar: AppBar(
        backgroundColor: Colors.white, // Match background of the main content
        elevation: 0, // No shadow for a flat design
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black), // Hamburger menu icon
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Opens the drawer
              },
            );
          },
        ),
        title: const Text(
          'Food Diary', // Consistent title
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.black), // Calendar icon
            onPressed: () {
              // TODO: Implement calendar view or date selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calendar view coming soon!')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer( // Your existing drawer for navigation
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Welcome, ${widget.username}!',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Diary (Dashboard)'),
              onTap: () {
                _onItemTapped(0); // Navigate to Dashboard
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Exercise'),
              onTap: () {
                _onItemTapped(1); // Navigate to Exercise
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_dining),
              title: const Text('Recipes'),
              onTap: () {
                _onItemTapped(2); // Navigate to Recipes
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                _onItemTapped(3); // Navigate to Profile
                Navigator.pop(context); // Close drawer
              },
            ),
            // History is now accessible via ProfilePage
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page content
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined), // Diary icon
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center), // Exercise icon
            label: 'Exercise',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_dining), // Recipes icon
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Profile icon
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        backgroundColor: Colors.white,
      ),
    );
  }
}

// The redesigned Food Diary Dashboard content
class _FoodDiaryDashboard extends StatefulWidget {
  final String username;

  const _FoodDiaryDashboard({required this.username});

  @override
  State<_FoodDiaryDashboard> createState() => _FoodDiaryDashboardState();
}

class _FoodDiaryDashboardState extends State<_FoodDiaryDashboard> {
  List<Map<String, dynamic>> _meals = [];
  int _dailyCalorieGoal = 2282; // Example daily calorie goal
  int _caloriesUsed = 0;
  int _bonusCalories = 0; // Could be from exercise, etc.

  @override
  void initState() {
    super.initState();
    _loadDailyMeals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDailyMeals();
  }

  Future<void> _loadDailyMeals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final mealList = prefs.getStringList('meals') ?? [];
    List<Map<String, dynamic>> loadedMeals = [];
    int totalCalories = 0;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (String mealJson in mealList) {
      final decoded = jsonDecode(mealJson) as Map<String, dynamic>;
      final mealDate = DateTime.parse(decoded['dateTime']).toLocal();
      if (DateFormat('yyyy-MM-dd').format(mealDate) == today) {
        loadedMeals.add(decoded);
        totalCalories += (decoded['cal'] as int);
      }
    }

    setState(() {
      _meals = loadedMeals;
      _caloriesUsed = totalCalories;
    });
  }

  @override
  Widget build(BuildContext context) {
    int caloriesRemaining = _dailyCalorieGoal - _caloriesUsed + _bonusCalories;
    double progressValue = _caloriesUsed / _dailyCalorieGoal;
    if (progressValue < 0) progressValue = 0;
    if (progressValue > 1) progressValue = 1;

    return RefreshIndicator(
      onRefresh: _loadDailyMeals,
      child: Stack( // Use Stack to position the FAB
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today : ${DateFormat('EEEE').format(DateTime.now())}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    // Removed calendar icon from here, it's in the AppBar now
                  ],
                ),
                const SizedBox(height: 24),

                // Main Calorie Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: progressValue,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  caloriesRemaining.toString(),
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'currently available',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryMetric(context, Icons.apple, 'Used', _caloriesUsed, Theme.of(context).primaryColor),
                            _buildSummaryMetric(context, Icons.card_giftcard, 'Bonus', _bonusCalories, Colors.orange),
                            _buildSummaryMetric(context, Icons.flag, 'Kcal Goal', _dailyCalorieGoal, Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Meal Sections
                Text(
                  'Your Meals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _meals.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No meals logged for today. Start tracking!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _meals.length,
                        itemBuilder: (context, index) {
                          final meal = _meals[index];
                          return _buildMealEntryCard(context, meal);
                        },
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // NEW: Floating Action Button for Add Food
          Positioned(
            top: 16, // Adjust position as needed, relative to the Stack
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/calculator');
              },
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(BuildContext context, IconData icon, String label, int value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMealEntryCard(BuildContext context, Map<String, dynamic> meal) {
    String emoji = meal['emoji'] ?? '🍔';
    if (meal['type'] == 'Exercise') {
      emoji = '🏃';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['name'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${meal['cal']} kcal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                if (meal['type'] != 'Exercise')
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onPressed: () {
                      Navigator.pushNamed(context, '/calculator');
                    },
                  ),
              ],
            ),
            if (meal['ingredients'] != null && meal['ingredients'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  ... (meal['ingredients'] as List).map((ingredient) {
                    return Text(
                      '- ${ingredient['name']} (${ingredient['qty']} ${ingredient['unit']}) - ${ingredient['cal']} kcal',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }).toList(),
                ],
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(DateTime.parse(meal['dateTime']).toLocal()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
