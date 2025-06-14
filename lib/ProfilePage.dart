import 'package:flutter/material.dart';
import 'HistoryPage.dart'; // Import the HistoryPage

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  // Removed targetCalories as it's not being used dynamically here and was removed from constructor

  const ProfilePage({super.key, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center contents horizontally
            children: [
              // User Avatar/Icon
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), // Light primary color
                child: Icon(
                  Icons.person,
                  size: 70,
                  color: Theme.of(context).primaryColor, // Primary color for icon
                ),
              ),
              const SizedBox(height: 24),

              // Username and Email Display
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Profile Detail Cards
              _buildProfileCard(
                context,
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: email,
              ),
              const SizedBox(height: 16),
              _buildProfileCard(
                context,
                icon: Icons.star_border,
                title: 'Target Calories', // Placeholder, ideally dynamic
                value: '2000 kcal', // Hardcoded for now, could be dynamic
              ),
              const SizedBox(height: 16),
              // NEW: History Link Card
              Card(
                child: InkWell( // Use InkWell for a ripple effect on tap
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'View History',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement logout functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logout functionality coming soon!')),
                    );
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build a consistent profile detail card
  Widget _buildProfileCard(BuildContext context, {required IconData icon, required String title, required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
