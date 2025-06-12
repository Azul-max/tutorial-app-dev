import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final int targetCalories;

  const ProfilePage({super.key, 
    required this.name,
    required this.email,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_pic.png'),
            ),
            SizedBox(height: 16),
            Text('Name: $name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Email: $email', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Target Daily Calories:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$targetCalories kcal/day',
                style: TextStyle(fontSize: 18, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
