import 'package:flutter/material.dart';
import 'ProfilePage.dart';
import 'HistoryPage.dart';


class MainMenuPage extends StatelessWidget {
  final String username;

  const MainMenuPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // Removed the Builder and Future.delayed that was automatically opening the drawer.
    // The drawer will now open normally when the user taps the menu icon.
    return Scaffold(
      drawer: AppDrawer(username: username),
      appBar: AppBar(title: const Text('Calorie Tracker - Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $username!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Track your meals and stay fit.'),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String username;

  const AppDrawer({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            child: Text(
              'Calorie Tracker',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Calories Calculator'),
            onTap: () {
              // Navigate to the NEW CaloriesCalculatorPage (the front page for calorie features)
              Navigator.pushNamed(context, '/calculator');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    name: username,
                    email: '$username@example.com',
                    targetCalories: 2000,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Exercise'),
            onTap: () {
              Navigator.pushNamed(context, '/exercise');
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Balanced Recipes'),
            onTap: () {
              Navigator.pushNamed(context, '/recipes');
            },
          ),
        ],
      ),
    );
  }
}
