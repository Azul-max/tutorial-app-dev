// lib/HistoryPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart'; // Import the calendar package

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Calendar state variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now(); // Initialize with today's date

  List<Map<String, dynamic>> _allMeals = []; // Stores all meals loaded from SharedPreferences
  List<Map<String, dynamic>> _historyEntries = []; // Stores filtered meals for the selected day
  bool _isLoading = true; // State to manage loading

  @override
  void initState() {
    super.initState();
    _loadAllMealsAndFilter(_selectedDay); // Load history for the initially selected day (today)
  }

  // Function to load all entries from SharedPreferences and then filter them by date
  Future<void> _loadAllMealsAndFilter(DateTime dateToFilter) async {
    setState(() {
      _isLoading = true; // Set loading to true when starting to load
    });

    final prefs = await SharedPreferences.getInstance();
    final List<String> mealListJson = prefs.getStringList('meals') ?? [];
    List<Map<String, dynamic>> loadedAllMeals = [];

    for (String entryJson in mealListJson) {
      try {
        final decoded = jsonDecode(entryJson) as Map<String, dynamic>;
        // Ensure 'imagePath' is removed if it exists, as per original logic
        decoded.remove('imagePath');
        loadedAllMeals.add(decoded);
      } catch (e) {
        print('Error parsing meal entry from storage: $e');
      }
    }

    // Update the master list of all meals
    _allMeals = loadedAllMeals;

    // Now, filter this master list based on the selected date
    final selectedDateOnly = DateTime(dateToFilter.year, dateToFilter.month, dateToFilter.day);
    List<Map<String, dynamic>> filteredEntries = [];

    for (var entry in _allMeals) {
      if (entry['dateTime'] != null) {
        try {
          final entryDateTime = DateTime.parse(entry['dateTime']);
          final entryDateOnly = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);

          if (entryDateOnly.isAtSameMomentAs(selectedDateOnly)) {
            filteredEntries.add(entry);
          }
        } catch (e) {
          print('Error parsing date for entry: ${entry['name']} - $e');
        }
      }
    }

    // Sort entries by dateTime (most recent first)
    filteredEntries.sort((a, b) {
      final DateTime dateA = DateTime.tryParse(a['dateTime'] ?? '') ?? DateTime(0);
      final DateTime dateB = DateTime.tryParse(b['dateTime'] ?? '') ?? DateTime(0);
      return dateB.compareTo(dateA); // Sort in descending order (latest first)
    });

    setState(() {
      _historyEntries = filteredEntries;
      _isLoading = false; // Set loading to false once data is loaded
    });
  }

  // Function to save the entire _allMeals list back to SharedPreferences
  Future<void> _saveAllMeals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> mealListJson = _allMeals.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('meals', mealListJson);
  }

  void _deleteMeal(int index) async {
    // Get the item to delete from the currently displayed filtered list
    final entryToDelete = _historyEntries[index];

    // Find and remove this item from the master list (_allMeals)
    // This is crucial to avoid data loss. We identify by content as there's no unique ID.
    _allMeals.removeWhere((entry) =>
        entry['name'] == entryToDelete['name'] &&
        entry['type'] == entryToDelete['type'] &&
        entry['cal'] == entryToDelete['cal'] &&
        entry['dateTime'] == entryToDelete['dateTime']); // Use all properties for a strong match

    await _saveAllMeals(); // Save the updated master list
    await _loadAllMealsAndFilter(_selectedDay); // Reload and re-filter for the current date
  }

  void _editMeal(int index) {
    // Get the item to edit from the currently displayed filtered list
    final entryToEdit = _historyEntries[index];
    
    TextEditingController nameController =
        TextEditingController(text: entryToEdit['name']);
    TextEditingController calController =
        TextEditingController(text: entryToEdit['cal'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Find the original item in the master list (_allMeals) and update it
              // Again, relying on matching properties for identification
              final originalEntryIndex = _allMeals.indexWhere((entry) =>
                  entry['name'] == entryToEdit['name'] &&
                  entry['type'] == entryToEdit['type'] &&
                  entry['cal'] == entryToEdit['cal'] &&
                  entry['dateTime'] == entryToEdit['dateTime']);

              if (originalEntryIndex != -1) {
                setState(() {
                  _allMeals[originalEntryIndex]['name'] = nameController.text;
                  _allMeals[originalEntryIndex]['cal'] =
                      int.tryParse(calController.text) ?? _allMeals[originalEntryIndex]['cal'];
                });
                await _saveAllMeals(); // Save the updated master list
                await _loadAllMealsAndFilter(_selectedDay); // Reload and re-filter for the current date
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList(List ingredients) {
    if (ingredients.isEmpty) return const SizedBox.shrink(); // Don't show if empty
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
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Calendar Widget
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1), // Start of the calendar range
              lastDay: DateTime.utc(2030, 12, 31), // End of the calendar range
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                // Use `selectedDayPredicate` to configure which days are marked as selected.
                // This returns true when the day is same as _selectedDay.
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay; // update `_focusedDay` here as well
                  });
                  _loadAllMealsAndFilter(selectedDay); // Load history for the newly selected day
                }
              },
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              // Corrected: Ensure 'leftMargin' and 'rightMargin' are used
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                todayTextStyle: TextStyle(color: Theme.of(context).primaryColor),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.grey[700]),
                weekendStyle: TextStyle(color: Colors.red[700]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Display for selected date's entries
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Entries for ${
                    _selectedDay.day}/${_selectedDay.month}/${_selectedDay.year
                }',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _historyEntries.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          'No entries for this date.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: _historyEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _historyEntries[index];
                          final String name = entry['name'] ?? 'Unknown';
                          final String type = entry['type'] ?? 'N/A'; // Food or Exercise
                          final int calories = entry['cal'] ?? 0;
                          final DateTime? entryTime = entry['dateTime'] != null
                              ? DateTime.tryParse(entry['dateTime'])?.toLocal()
                              : null;
                          final String formattedTime = entryTime != null
                              ? '${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}'
                              : 'No time';
                          final List ingredients = entry['ingredients'] ?? [];

                          IconData icon;
                          Color iconColor;
                          if (type == 'Food') {
                            icon = Icons.restaurant_menu;
                            iconColor = Colors.orange;
                          } else if (type == 'Exercise') {
                            icon = Icons.directions_run;
                            iconColor = Colors.blue;
                          } else {
                            icon = Icons.info_outline;
                            iconColor = Colors.grey;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '$name (${type == 'Food' ? 'Meal' : type})',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[850],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$calories kcal'),
                                        const SizedBox(height: 4),
                                        Text('Logged at: $formattedTime',
                                            style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      ],
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(icon, color: iconColor, size: 28),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () => _editMeal(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteMeal(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ingredients.isNotEmpty && type == 'Food') ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ingredients:',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildIngredientList(ingredients),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
