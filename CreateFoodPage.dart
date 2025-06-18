import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Required for local storage
import 'dart:convert'; // Required for JSON encoding/decoding

class CreateFoodPage extends StatefulWidget {
  // Add this static const for named routing.
  static const String routeName = '/createFood';

  const CreateFoodPage({super.key});

  @override
  _CreateFoodPageState createState() => _CreateFoodPageState();
}

class _CreateFoodPageState extends State<CreateFoodPage> {
  // GlobalKey for form validation, allows validating all fields in the form at once.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // TextEditingControllers for all input fields to read and clear their values.
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController calorieController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController servingController = TextEditingController();

  // State variable to hold the currently selected unit from the dropdown.
  String selectedUnit = 'gram (g)';

  // List to store food items created by the user.
  // This list is primarily for persistence (saving/loading), not for direct display on this page,
  // as per the provided design.
  List<Map<String, dynamic>> foodItems = [];

  // NEW: State variable for the selected emoji
  String _selectedEmoji = '🍔'; // Default emoji

  // NEW: A list of common food emojis for the picker
  final List<String> _foodEmojis = [
    '🍔', '🍟', '�', '🍣', '🍜', '🍝', '🌮', '🥗', '🍎', '🍓',
    '🥕', '🍞', '🧀', '🍗', '🍦', '🍩', '☕', '🥛', '🥦', '🍳'
  ];

  @override
  void initState() {
    super.initState();
    _loadFoodItems(); // Load any previously saved food items when the page first loads.
    _loadSelectedEmoji(); // NEW: Load the previously saved emoji
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers to prevent memory leaks when the widget is removed.
    foodNameController.dispose();
    calorieController.dispose();
    proteinController.dispose();
    fatController.dispose();
    carbsController.dispose();
    servingController.dispose();
    super.dispose();
  }

  /// Loads food items from the device's local storage using SharedPreferences.
  /// This method is called once when the page is initialized.
  Future<void> _loadFoodItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Attempt to retrieve a list of strings stored under the key 'customFoodItems'.
    final List<String>? storedItems = prefs.getStringList('customFoodItems');

    if (storedItems != null) {
      // If items are found, decode each JSON string back into a Map
      // and update the 'foodItems' list.
      foodItems = storedItems.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    }
  }

  /// NEW: Loads the previously selected emoji from SharedPreferences.
  Future<void> _loadSelectedEmoji() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedEmoji = prefs.getString('selectedFoodEmoji');
    if (storedEmoji != null) {
      setState(() {
        _selectedEmoji = storedEmoji;
      });
    }
  }

  /// NEW: Saves the currently selected emoji to SharedPreferences.
  Future<void> _saveSelectedEmoji(String emoji) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFoodEmoji', emoji);
  }

  /// Saves the current list of 'foodItems' to the device's local storage.
  /// This method is called whenever a new food item is added or an existing one is deleted.
  Future<void> _saveFoodItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Convert each food item Map into a JSON string before storing.
    List<String> itemsToStore = foodItems.map((item) => jsonEncode(item)).toList();
    // Save the list of JSON strings.
    await prefs.setStringList('customFoodItems', itemsToStore);
  }

  /// Handles the action of adding a new food item.
  /// It performs input validation, adds the item to the list, clears the form, and saves.
  void addFoodItem() {
    // Validate all form fields using the form key. If validation fails, stop.
    if (_formKey.currentState!.validate()) {
      // Extract text from controllers. Serving is kept as a String.
      final name = foodNameController.text;
      final calories = int.tryParse(calorieController.text) ?? 0;
      final protein = int.tryParse(proteinController.text) ?? 0;
      final fat = int.tryParse(fatController.text) ?? 0;
      final carbs = int.tryParse(carbsController.text) ?? 0;
      final serving = servingController.text;

      setState(() {
        // Add the new food item as a Map to the 'foodItems' list.
        foodItems.add({
          'name': name,
          'calories': calories,
          'protein': protein,
          'fat': fat,
          'carbs': carbs,
          'serving': serving,
          'unit': selectedUnit,
          'emoji': _selectedEmoji, // NEW: Save the selected emoji with the food item
        });
        // Clear all input fields and reset the selected unit.
        foodNameController.clear();
        calorieController.clear();
        proteinController.clear();
        fatController.clear();
        carbsController.clear();
        servingController.clear();
        selectedUnit = 'gram (g)'; // Reset unit to its default.
        // Keep _selectedEmoji as is, or reset to default if desired after adding food.
      });

      _saveFoodItems(); // Persist the updated list of food items to local storage.

      // Show a brief confirmation message to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food item added and saved!')),
      );
    }
  }

  /// This method is retained for potential future use (e.g., in a separate 'manage custom foods' page)
  /// It deletes a specific food item from the list and saves the changes.
  void deleteFoodItem(Map<String, dynamic> item) {
    setState(() {
      foodItems.remove(item); // Remove the specified item from the list.
    });
    _saveFoodItems(); // Persist the updated list.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Food item deleted.')),
    );
  }

  /// This getter calculates the total calories of all food items currently in the 'foodItems' list.
  /// It's not directly displayed on this page based on the current design, but is a useful utility.
  int get totalCalories => foodItems.fold(0, (sum, item) => sum + (item['calories'] as int));

  /// NEW: Function to show the emoji picker dialog
  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose an Emoji'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true, // Wrap content
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 5 emojis per row
                childAspectRatio: 1, // Square cells
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _foodEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _foodEmojis[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji; // Update selected emoji
                    });
                    _saveSelectedEmoji(emoji); // Save the new emoji to preferences
                    Navigator.pop(context); // Close the dialog
                  },
                  child: CircleAvatar(
                    backgroundColor: _selectedEmoji == emoji ? const Color.fromARGB(255, 230, 200, 200) : Colors.grey.shade100,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white as per design.
      appBar: AppBar(
        title: const Text('Create Food'), // Title for the AppBar.
        backgroundColor: Colors.white, // AppBar background matches body.
        elevation: 0, // Remove shadow for a flat design.
        foregroundColor: Colors.black, // Color for app bar icons and text.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the entire body content.
        child: Form( // Wrap the main content with a Form widget to enable validation.
          key: _formKey, // Assign the GlobalKey to this Form.
          child: SingleChildScrollView( // Allows the content to scroll if it overflows.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally to fill width.
              children: [
                // --- Emoji icon for food with a picker button ---
                Center(
                  child: Stack( // Use Stack to position the edit button over the CircleAvatar
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(_selectedEmoji, style: const TextStyle(fontSize: 30)), // Display selected emoji
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showEmojiPicker, // Call emoji picker
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.edit, size: 20, color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- END Emoji icon for food with a picker button ---
                const SizedBox(height: 24), // Spacer for vertical spacing.

                // Food Name Input Field.
                _buildInputField('Food Name', foodNameController,
                    hintText: 'e.g. Salad, Sandwich etc', // Placeholder text from design.
                    validator: (value) => value!.isEmpty ? 'Please enter a food name' : null,
                    keyboardType: TextInputType.text), // Appropriate keyboard type.

                // Row containing Serving and Unit input fields.
                Row(
                  children: [
                    Expanded( // Allows the text field to take available space.
                        child: _buildInputField('Serving', servingController,
                            hintText: 'e.g. 100', // Placeholder from design.
                            validator: (value) => value!.isEmpty ? 'Please enter serving' : null,
                            keyboardType: TextInputType.text)),
                    const SizedBox(width: 12), // Spacer between fields.
                    Expanded( // Allows the dropdown to take available space.
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit, // The currently selected unit.
                        onChanged: (value) => setState(() => selectedUnit = value!), // Update state on selection.
                        items: const [ // List of predefined unit options.
                          'gram (g)',
                          'ml',
                          'piece',
                          'serving',
                          'cup',
                          'tsp', // Teaspoon.
                          'tbsp', // Tablespoon.
                        ].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                        decoration: InputDecoration( // Styling to match the text fields.
                          labelText: 'Unit',
                          hintText: 'e.g. gram, ml', // Placeholder from design.
                          filled: true,
                          fillColor: Colors.grey[100], // Light grey background fill.
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners.
                            borderSide: BorderSide.none, // No visible border line.
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjust padding.
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12), // Spacer.

                // Calorie Input Field.
                _buildInputField('Calorie (kcal)', calorieController,
                    hintText: 'e.g. 100', // Placeholder from design.
                    validator: (value) => _validatePositiveNumber(value, 'calories'),
                    keyboardType: TextInputType.number), // Numeric keyboard.

                // Row containing Protein, Carbs, and Fat input fields.
                Row(
                  children: [
                    Expanded(
                        child: _buildInputField('Protein (g)', proteinController,
                            hintText: 'e.g. 10', // Placeholder from design.
                            validator: (value) => _validatePositiveNumber(value, 'protein'),
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 12), // Spacer.
                    Expanded(
                        child: _buildInputField('Carbs (g)', carbsController,
                            hintText: 'e.g. 10', // Placeholder from design.
                            validator: (value) => _validatePositiveNumber(value, 'carbs'),
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 12), // Spacer.
                    Expanded(
                        child: _buildInputField('Fat (g)', fatController,
                            hintText: 'e.g. 10', // Placeholder from design.
                            validator: (value) => _validatePositiveNumber(value, 'fat'),
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 24), // Spacer.

                // Add Food Item Button, styled to match the design.
                SizedBox(
                  height: 55, // Set a specific height for the button.
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A), // Specific green color from the design.
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)), // Slightly rounded corners.
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.white, // Text and icon color.
                      elevation: 0, // No shadow for a flat look.
                    ),
                    icon: const Icon(Icons.add), // Add icon.
                    label: const Text(
                      'Add', // Button label as per design.
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Bold text.
                    ),
                    onPressed: addFoodItem, // Call the method to add the food item.
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper function for building a TextFormField with consistent styling and validation.
  /// [label]: The text displayed as the label for the input field.
  /// [controller]: The TextEditingController to manage the text input.
  /// [hintText]: Optional placeholder text displayed when the field is empty.
  /// [validator]: An optional function to validate the input.
  /// [keyboardType]: The type of keyboard to display (e.g., number, text).
  Widget _buildInputField(String label, TextEditingController controller,
      {String? hintText, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Padding below each input field.
      child: TextFormField( // Using TextFormField for built-in validation capabilities.
        controller: controller,
        decoration: InputDecoration(
          labelText: label, // Label for the input field.
          hintText: hintText, // Placeholder text.
          filled: true, // Fill the input field with a color.
          fillColor: Colors.grey[100], // Light grey fill color.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Apply rounded corners.
            borderSide: BorderSide.none, // Hide the default border line.
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjust internal padding.
        ),
        keyboardType: keyboardType, // Set the keyboard type.
        validator: validator, // Assign the validator function.
      ),
    );
  }

  /// Helper function to validate if a string can be parsed into a non-negative integer.
  /// [value]: The string input from a TextFormField.
  /// [fieldName]: The name of the field (e.g., 'calories', 'protein') for error messages.
  /// Returns an error message string if invalid, otherwise null.
  String? _validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName'; // Error if empty.
    }
    final number = int.tryParse(value);
    if (number == null || number < 0) { // Error if not a number or is negative.
      return 'Enter a valid positive number for $fieldName';
    }
    return null; // Input is valid.
  }
}