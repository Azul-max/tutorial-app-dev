import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> meals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final mealList = prefs.getStringList('meals') ?? [];
    setState(() {
      meals = mealList.map((e) {
        final decoded = jsonDecode(e) as Map<String, dynamic>;
        decoded.remove('imagePath');
        return decoded;
      }).toList();
    });
    _saveMeals(); // Optional cleanup
  }

  Future<void> _saveMeals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> mealList = meals.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('meals', mealList);
  }

  void _deleteMeal(int index) async {
    setState(() {
      meals.removeAt(index);
    });
    await _saveMeals();
  }

  void _editMeal(int index) {
    TextEditingController nameController =
        TextEditingController(text: meals[index]['name']);
    TextEditingController calController =
        TextEditingController(text: meals[index]['cal'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Meal Name'),
            ),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Calories'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                meals[index]['name'] = nameController.text;
                meals[index]['cal'] =
                    int.tryParse(calController.text) ?? meals[index]['cal'];
              });
              _saveMeals();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList(List ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map<Widget>((ingredient) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 2.0),
          child: Text(
            '- ${ingredient['name']} (${ingredient['cal']} cal)',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meal & Exercise History')),
      body: meals.isEmpty
          ? Center(child: Text('No history found.'))
          : ListView.builder(
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                final ingredients = meal['ingredients'] ?? [];
                final dateTime = meal['dateTime'] != null
                ? DateTime.tryParse(meal['dateTime'])?.toLocal()
                : null;
                final formattedDate = dateTime != null
                ? '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'
                : 'No date';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${meal['name']} (${meal['type'] ?? "Meal"})',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${meal['cal']} calories'),
                              SizedBox(height: 4),
                              Text('Saved on: $formattedDate',
                                  style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _editMeal(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMeal(index),
                              ),
                            ],
                          ),
                        ),

                        if (ingredients.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            'Ingredients:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          _buildIngredientList(ingredients),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
