import 'package:flutter/material.dart';

class RecipeSuggestionPage extends StatefulWidget {
  const RecipeSuggestionPage({super.key});

  @override
  _RecipeSuggestionPageState createState() => _RecipeSuggestionPageState();
}

class _RecipeSuggestionPageState extends State<RecipeSuggestionPage> {
  final _calorieTargetController = TextEditingController();
  List<Map<String, dynamic>> _suggestedMeals = [];

  void _generateRecipes() {
    int target = int.tryParse(_calorieTargetController.text) ?? 2000;

    // Simple logic for balanced macros
    List<Map<String, dynamic>> recipes = [
      {
        'title': 'Grilled Chicken with Quinoa Salad',
        'calories': 500,
        'description':
            'High in protein with lean meat and complex carbs from quinoa and veggies.',
      },
      {
        'title': 'Oats with Fruits & Nuts',
        'calories': 400,
        'description':
            'Great breakfast: fiber-rich oats, healthy fats, and natural sugars.',
      },
      {
        'title': 'Steamed Salmon with Brown Rice',
        'calories': 600,
        'description':
            'Omega-3 rich salmon with low-GI carbs and essential nutrients.',
      },
      {
        'title': 'Tofu Stir Fry with Vegetables',
        'calories': 450,
        'description':
            'Plant-based protein and fiber from veggies, low in saturated fat.',
      },
    ];

    setState(() {
      _suggestedMeals = recipes
          .where((meal) => meal['calories'] <= target)
          .take(3)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Balanced Diet Recipes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _calorieTargetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your target calories (e.g. 2000)',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _generateRecipes,
              child: Text('Get Recipe Suggestions'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _suggestedMeals.isEmpty
                  ? Text('Enter a calorie target to get recipes.')
                  : ListView.builder(
                      itemCount: _suggestedMeals.length,
                      itemBuilder: (context, index) {
                        final meal = _suggestedMeals[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(meal['title']),
                            subtitle: Text('${meal['description']} \n(${meal['calories']} cal)'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
