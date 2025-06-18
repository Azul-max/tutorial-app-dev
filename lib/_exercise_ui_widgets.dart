// lib/Module/_exercise_ui_widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExerciseUIWidgets {
  // Private constructor to prevent instantiation
  ExerciseUIWidgets._();

  static IconData getExerciseIcon(String exerciseName) {
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

  static Widget buildExerciseCard(Map<String, dynamic> exercise) {
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
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
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
                    Icon(ExerciseUIWidgets.getExerciseIcon(exercise['name'])),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        exercise['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  static Color _getProgressColor(double value) {
    if (value < 0.25) return Colors.red;
    if (value < 0.5) return Colors.orange;
    if (value < 0.75) return Colors.lightGreen;
    return Colors.green;
  }

  static Widget buildWeeklySummary(double progress, int weeklyCalorieTarget, int totalCalories, int totalMinutes) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WEEKLY SUMMARY (Current Week)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
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
            if (progress >= 1.0)
              Text(
                'Congratulations! You\'ve reached your weekly goal! 🎉',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (progress > 0.75)
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
}
