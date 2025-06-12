import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  // Update constructor to accept username and email
  final String name; // This will now be the username
  final String email; // NEW: Accept email

  // Removed targetCalories as it wasn't being used dynamically before,
  // and we're focusing on displaying passed info.
  // If targetCalories is needed, it should be passed from a user object or fetched.
  const ProfilePage({super.key, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color will now be inherited from ThemeData in main.dart
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        // AppBar styles (background, foreground, elevation, centerTitle)
        // are now defined in ThemeData in main.dart, so we don't need to repeat them here.
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
                  size: 80,
                  color: Theme.of(context).primaryColor, // Use primary color for icon
                ),
              ),
              const SizedBox(height: 24),

              // Username Display
              Text(
                name, // Display the passed username
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black87), // Use theme text style
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Email Display
              Text(
                email.isNotEmpty ? email : 'No email provided', // Display the passed email
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]), // Use theme text style
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Profile Details - Example Cards
              _buildProfileCard(
                context,
                icon: Icons.track_changes,
                title: 'Daily Calorie Goal',
                value: '2000 kcal', // Placeholder, ideally dynamic
              ),
              _buildProfileCard(
                context,
                icon: Icons.height,
                title: 'Height',
                value: '175 cm', // Placeholder, ideally dynamic
              ),
              _buildProfileCard(
                context,
                icon: Icons.monitor_weight,
                title: 'Weight',
                value: '70 kg', // Placeholder, ideally dynamic
              ),
              _buildProfileCard(
                context,
                icon: Icons.accessibility_new,
                title: 'Activity Level',
                value: 'Moderately Active', // Placeholder, ideally dynamic
              ),
              const SizedBox(height: 32),

              // Logout Button (Example)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement logout logic (e.g., clear SharedPreferences, navigate to SignInPage)
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out!')),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  // Button style is inherited from ThemeData.elevatedButtonTheme
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
      // Card theme is inherited from ThemeData.cardTheme
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor), // Icon with primary color
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // Arrow icon
          ],
        ),
      ),
    );
  }
}
