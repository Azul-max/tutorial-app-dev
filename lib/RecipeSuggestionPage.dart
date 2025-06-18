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

    // Expanded recipe list with images
    List<Map<String, dynamic>> recipes = [
      {
        'title': 'Grilled Chicken with Quinoa Salad',
        'calories': 500,
        'description': 'High in protein with lean meat and complex carbs.',
        'image': 'assets/images/Grilled Chicken with Quinoa Salad.jpeg',
      },
      {
        'title': 'Oats with Fruits & Nuts',
        'calories': 400,
        'description': 'Fiber-rich oats, healthy fats, and natural sugars.',
        'image': 'assets/images/Healthy Oatmeal Breakfast Bowl for Busy Mornings.jpeg',
      },
      {
        'title': 'Steamed Salmon with Brown Rice',
        'calories': 600,
        'description': 'Omega-3 rich salmon with low-GI carbs.',
        'image': 'assets/images/Delicious Savory Salmon Rice Bowl.jpeg',
      },
      {
        'title': 'Tofu Stir Fry with Vegetables',
        'calories': 450,
        'description': 'Plant-based protein and fiber from veggies.',
        'image': 'assets/images/Easy Vegan Tofu Stir-Fry Recipe with Fresh Veggies.jpeg',
      },
      {
        'title': 'Egg Avocado Toast',
        'calories': 350,
        'description': 'Good fats from avocado and protein from eggs.',
        'image': 'assets/images/Egg Avocado Toast.jpeg',
      },
      {
        'title': 'Greek Yogurt Parfait',
        'calories': 300,
        'description': 'Protein-rich yogurt with fruits and granola.',
        'image': 'assets/images/Greek Yogurt Parfait.jpeg',
      },
      {
        'title': 'Vegetable Soup with Whole Wheat Bread',
        'calories': 380,
        'description': 'Low-calorie, warm, and full of fiber.',
        'image': 'assets/images/Vegetable Soup with Whole Wheat Bread.jpeg',
      },
      {
        'title': 'Chicken Caesar Wrap',
        'calories': 550,
        'description': 'Grilled chicken with crisp veggies in a wrap.',
        'image': 'assets/images/Chicken Caesar Wrap.jpeg',
      },
      {
        'title': 'Shrimp Stir Fry with Broccoli',
        'calories': 480,
        'description': 'Lean protein and low-carb greens.',
        'image': 'assets/images/Shrimp Stir Fry with Broccoli.jpeg',
      },
      {
        'title': 'Baked Sweet Potato with Beans',
        'calories': 420,
        'description': 'Complex carbs and fiber-rich beans.',
        'image': 'assets/images/Baked Sweet Potato with Beans.jpeg',
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
      appBar: AppBar(
        title: Text('Balanced Diet Recipes'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _calorieTargetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your target calories (e.g. 2000)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _generateRecipes,
              child: Text('Get Recipe Suggestions'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _suggestedMeals.isEmpty
                  ? Center(
                      child: Text(
                        'Enter a calorie target to get recipes.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _suggestedMeals.length,
                      itemBuilder: (context, index) {
                        final meal = _suggestedMeals[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(10),
                            leading: meal['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      meal['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : null,
                            title: Text(meal['title'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            subtitle: Text(
                                '${meal['description']}\nCalories: ${meal['calories']}'),
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
