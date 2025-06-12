import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MealSummaryPage extends StatefulWidget {
  final List<Map<String, dynamic>> mealItems;
  final String mealType; // The selected meal type (Breakfast, Lunch, etc.)

  const MealSummaryPage({
    super.key,
    required this.mealItems,
    required this.mealType,
  });

  @override
  State<MealSummaryPage> createState() => _MealSummaryPageState();
}

class _MealSummaryPageState extends State<MealSummaryPage> {
  List<Map<String, dynamic>> _currentMealItems = [];

  @override
  void initState() {
    super.initState();
    // Create a deep copy and ensure emoji is present, defaulting if not
    _currentMealItems = List<Map<String, dynamic>>.from(widget.mealItems.map((item) {
      final Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
      newItem['emoji'] ??= '🍔'; // Default emoji if not present
      return newItem;
    }));
  }

  int _getMealTotalCalories() {
    return _currentMealItems.fold(0, (sum, item) => sum + (item['calories'] as int));
  }

  void _removeMealItem(Map<String, dynamic> itemToRemove) {
    setState(() {
      _currentMealItems.remove(itemToRemove);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${itemToRemove['name']} removed from meal.')),
    );
  }

  /// Saves the entire summarized meal to the global history and also adds items to 'recentFoodItems'.
  Future<void> _saveMealToHistory() async {
    if (_currentMealItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal is empty. Add items before saving.')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 1. Save to main meal history (for HistoryPage)
    List<String> mealHistoryStrings = prefs.getStringList('meals') ?? [];
    final newMealEntry = {
      'name': widget.mealType,
      'type': 'Meal',
      'cal': _getMealTotalCalories(),
      'ingredients': _currentMealItems.map((item) => {
        'name': item['name'],
        'cal': item['calories'],
        'qty': item['serving'],
        'unit': item['unit'],
        'emoji': item['emoji'], // Include emoji in saved ingredient
      }).toList(),
      'dateTime': DateTime.now().toIso8601String(),
    };
    mealHistoryStrings.add(jsonEncode(newMealEntry));
    await prefs.setStringList('meals', mealHistoryStrings);

    // 2. Also save each item to the 'recentFoodItems' list
    List<String> recentFoodItemsStrings = prefs.getStringList('recentFoodItems') ?? [];
    for (var item in _currentMealItems) {
      final itemJson = jsonEncode(item);
      if (!recentFoodItemsStrings.contains(itemJson)) {
        recentFoodItemsStrings.insert(0, itemJson);
        if (recentFoodItemsStrings.length > 20) {
          recentFoodItemsStrings = recentFoodItemsStrings.sublist(0, 20);
        }
      }
    }
    await prefs.setStringList('recentFoodItems', recentFoodItemsStrings);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.mealType} meal saved to history!')),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F1EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F1EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        title: Text(
          widget.mealType,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  '${_getMealTotalCalories()} kcal',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentMealItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items added to this meal yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _currentMealItems.length,
                    itemBuilder: (context, index) {
                      final item = _currentMealItems[index];
                      final dateTime = item['dateTime'] != null
                          ? DateTime.tryParse(item['dateTime'])?.toLocal()
                          : null;
                      final formattedTime = dateTime != null
                          ? DateFormat('HH:mm').format(dateTime)
                          : 'No time';
                      final itemEmoji = item['emoji'] ?? '🍔'; // Get emoji from item, default to burger

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar( // Use CircleAvatar for emoji
                            backgroundColor: Colors.orange.shade100, // Light background for emoji
                            child: Text(itemEmoji, style: const TextStyle(fontSize: 24)), // Display item's emoji
                          ),
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item['calories']} kcal, ${item['serving']} ${item['unit']}'),
                              Text('Added at: $formattedTime', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => _removeMealItem(item),
                          ),
                          onTap: () {
                            // TODO: Show detailed view or edit item if desired
                          },
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F1EC),
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                  ),
                  onPressed: _saveMealToHistory,
                  child: const Text('Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
