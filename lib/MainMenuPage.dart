import 'package:flutter/material.dart';
import 'ProfilePage.dart'; // Ensure ProfilePage is imported
import 'CaloriesCalculatorPage.dart'; // Assuming this is linked from MainMenu
import 'HistoryPage.dart'; // Assuming this is linked from MainMenu
import 'ExercisePage.dart'; // Assuming this is linked from MainMenu
import 'RecipeSuggestionPage.dart'; // Assuming this is linked from MainMenu

class MainMenuPage extends StatefulWidget {
  final String username;
  final String email; // NEW: Accept email here

  const MainMenuPage({super.key, required this.username, this.email = ''}); // Initialize email with empty string default

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0; // Index for the BottomNavigationBar

  // A list of widgets to display for each tab in the navigation bar.
  // We'll update the ProfilePage entry here to pass the username and email.
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize _pages here so we can use widget.username and widget.email
    _pages = <Widget>[
      // Placeholder for Dashboard/Home page
      Center(child: Text('Welcome, ${widget.username}!', style: TextStyle(fontSize: 24))),
      // History Page
      const HistoryPage(),
      // Calories Calculator Page
      const CaloriesCalculatorPage(),
      // Exercise Page (Placeholder or actual page)
      const ExercisePage(),
      // Profile Page - NEW: Pass username and email
      ProfilePage(name: widget.username, email: widget.email),
      // Recipe Suggestion Page (Placeholder or actual page)
      const RecipeSuggestionPage(),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme background color
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}!'), // Show username in app bar
        automaticallyImplyLeading: false, // Remove back button from Main Menu
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercise',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_dining),
            label: 'Recipes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Use theme primary color for selected item
        unselectedItemColor: Colors.grey, // Grey for unselected
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        backgroundColor: Colors.white, // White background for the bar
      ),
    );
  }
}
