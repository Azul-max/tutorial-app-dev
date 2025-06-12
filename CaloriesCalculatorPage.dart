import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'CreateFoodPage.dart';
import 'MealSummaryPage.dart';

class CaloriesCalculatorPage extends StatefulWidget {
  const CaloriesCalculatorPage({super.key});

  @override
  _CaloriesCalculatorPageState createState() => _CaloriesCalculatorPageState();
}

class _CaloriesCalculatorPageState extends State<CaloriesCalculatorPage> {
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  String _selectedMealType = 'Breakfast';

  final TextEditingController _searchController = TextEditingController();
  String _currentTab = 'Personal';

  List<Map<String, dynamic>> _personalFoodItems = [];
  List<Map<String, dynamic>> _recentFoodItems = [];
  List<Map<String, dynamic>> _favoriteFoodItems = [];

  List<Map<String, dynamic>> _filteredFoodItems = [];

  List<Map<String, dynamic>> _selectedItemsForMeal = [];

  RangeValues _calorieRangeFilter = const RangeValues(0, 1000);
  bool _filterHighProtein = false;
  bool _filterLowCarb = false;
  bool _filterHighFat = false;
  String? _sortBy;


  @override
  void initState() {
    super.initState();
    _loadAllFoodItems();
    _searchController.addListener(_filterFoodItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFoodItems);
    _searchController.dispose();
    super.dispose();
  }

  // --- Data Loading & Filtering ---

  Future<void> _loadAllFoodItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String>? storedPersonalItems = prefs.getStringList('customFoodItems');
    final List<String>? storedRecentItems = prefs.getStringList('recentFoodItems');
    final List<String>? storedFavoriteItems = prefs.getStringList('favoriteFoodItems');

    setState(() {
      // Ensure 'emoji' is parsed if it exists, otherwise default to '🍔'
      _personalFoodItems = storedPersonalItems?.map((item) {
        final Map<String, dynamic> decodedItem = jsonDecode(item) as Map<String, dynamic>;
        decodedItem['emoji'] ??= '🍔'; // Default emoji if not present
        return decodedItem;
      }).toList() ?? [];

      _recentFoodItems = storedRecentItems?.map((item) {
        final Map<String, dynamic> decodedItem = jsonDecode(item) as Map<String, dynamic>;
        decodedItem['emoji'] ??= '🍔';
        return decodedItem;
      }).toList() ?? [];

      _favoriteFoodItems = storedFavoriteItems?.map((item) {
        final Map<String, dynamic> decodedItem = jsonDecode(item) as Map<String, dynamic>;
        decodedItem['emoji'] ??= '🍔';
        return decodedItem;
      }).toList() ?? [];

      _filterFoodItems();
    });
  }

  void _filterFoodItems() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> sourceList;

    if (_currentTab == 'Personal') {
      sourceList = _personalFoodItems;
    } else if (_currentTab == 'Recent') {
      sourceList = _recentFoodItems;
    } else if (_currentTab == 'Favorites') {
      sourceList = _favoriteFoodItems;
    } else {
      sourceList = [];
    }

    setState(() {
      _filteredFoodItems = sourceList.where((item) {
        final matchesSearch = query.isEmpty || item['name'].toLowerCase().contains(query);

        bool matchesFilters = true;

        final itemCalories = item['calories'] as int;
        if (itemCalories < _calorieRangeFilter.start || itemCalories > _calorieRangeFilter.end) {
          matchesFilters = false;
        }

        final itemProtein = item['protein'] as int;
        final itemCarbs = item['carbs'] as int;
        final itemFat = item['fat'] as int;

        if (_filterHighProtein && itemProtein < 15) matchesFilters = false;
        if (_filterLowCarb && itemCarbs > 10) matchesFilters = false;
        if (_filterHighFat && itemFat < 15) matchesFilters = false;

        return matchesSearch && matchesFilters;
      }).toList();

      if (_sortBy != null) {
        if (_sortBy == 'nameAsc') {
          _filteredFoodItems.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        } else if (_sortBy == 'nameDesc') {
          _filteredFoodItems.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));
        } else if (_sortBy == 'caloriesAsc') {
          _filteredFoodItems.sort((a, b) => (a['calories'] as int).compareTo(b['calories'] as int));
        } else if (_sortBy == 'caloriesDesc') {
          _filteredFoodItems.sort((a, b) => (b['calories'] as int).compareTo(a['calories'] as int));
        } else if (_sortBy == 'proteinDesc') {
          _filteredFoodItems.sort((a, b) => (b['protein'] as int).compareTo(a['protein'] as int));
        }
      }
    });
  }

  // --- Actions ---

  void _toggleFoodItemSelection(Map<String, dynamic> foodItem) {
    setState(() {
      if (_selectedItemsForMeal.contains(foodItem)) {
        _selectedItemsForMeal.remove(foodItem);
      } else {
        _selectedItemsForMeal.add(foodItem);
      }
    });
  }

  int _getTotalSelectedCalories() {
    return _selectedItemsForMeal.fold(0, (sum, item) => sum + (item['calories'] as int));
  }

  void _toggleFavoriteStatus(Map<String, dynamic> foodItem) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteItemsStrings = prefs.getStringList('favoriteFoodItems') ?? [];

    final itemJson = jsonEncode(foodItem);

    setState(() {
      if (favoriteItemsStrings.contains(itemJson)) {
        favoriteItemsStrings.remove(itemJson);
        _favoriteFoodItems.removeWhere((item) => jsonEncode(item) == itemJson);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${foodItem['name']} removed from favorites!')),
        );
      } else {
        favoriteItemsStrings.add(itemJson);
        _favoriteFoodItems.add(foodItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${foodItem['name']} added to favorites!')),
        );
      }
      if (_currentTab == 'Favorites') {
        _filterFoodItems();
      }
    });
    await prefs.setStringList('favoriteFoodItems', favoriteItemsStrings);
  }


  void _deletePersonalFoodItem(Map<String, dynamic> itemToDelete) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Food Item?'),
          content: Text('Are you sure you want to delete "${itemToDelete['name']}" from your personal food items?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                setState(() {
                  _personalFoodItems.remove(itemToDelete);
                  _selectedItemsForMeal.remove(itemToDelete);
                  final itemToDeleteJson = jsonEncode(itemToDelete);
                  _favoriteFoodItems.removeWhere((item) => jsonEncode(item) == itemToDeleteJson);
                  _recentFoodItems.removeWhere((item) => jsonEncode(item) == itemToDeleteJson);
                  _filterFoodItems();
                });
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('customFoodItems', _personalFoodItems.map((item) => jsonEncode(item)).toList());
                await prefs.setStringList('favoriteFoodItems', _favoriteFoodItems.map((item) => jsonEncode(item)).toList());
                await prefs.setStringList('recentFoodItems', _recentFoodItems.map((item) => jsonEncode(item)).toList());

                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${itemToDelete['name']} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterOptions() {
    RangeValues tempCalorieRange = _calorieRangeFilter;
    bool tempHighProtein = _filterHighProtein;
    bool tempLowCarb = _filterLowCarb;
    bool tempHighFat = _filterHighFat;
    String? tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempCalorieRange = const RangeValues(0, 1000);
                              tempHighProtein = false;
                              tempLowCarb = false;
                              tempHighFat = false;
                              tempSortBy = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.red)),
                        ),
                        const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    const Text('Calories (kcal)', style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: tempCalorieRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      labels: RangeLabels(
                        tempCalorieRange.start.round().toString(),
                        tempCalorieRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues newValues) {
                        setModalState(() {
                          tempCalorieRange = newValues;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text('${tempCalorieRange.start.round()} - ${tempCalorieRange.end.round()} kcal'),
                    ),
                    const SizedBox(height: 20),

                    const Text('Macronutrients', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('High Protein (>15g)'),
                      value: tempHighProtein,
                      onChanged: (bool? newValue) {
                        setModalState(() { tempHighProtein = newValue!; });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Low Carb (<10g)'),
                      value: tempLowCarb,
                      onChanged: (bool? newValue) {
                        setModalState(() { tempLowCarb = newValue!; });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('High Fat (>15g)'),
                      value: tempHighFat,
                      onChanged: (bool? newValue) {
                        setModalState(() { tempHighFat = newValue!; });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 20),

                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: tempSortBy,
                      hint: const Text('Select sorting option'),
                      items: const [
                        DropdownMenuItem(value: 'nameAsc', child: Text('Name (A-Z)')),
                        DropdownMenuItem(value: 'nameDesc', child: Text('Name (Z-A)')),
                        DropdownMenuItem(value: 'caloriesAsc', child: Text('Calories (Low to High)')),
                        DropdownMenuItem(value: 'caloriesDesc', child: Text('Calories (High to Low)')),
                        DropdownMenuItem(value: 'proteinDesc', child: Text('Protein (High to Low)')),
                      ],
                      onChanged: (String? newValue) {
                        setModalState(() { tempSortBy = newValue; });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 3,
                        ),
                        onPressed: () {
                          setState(() {
                            _calorieRangeFilter = tempCalorieRange;
                            _filterHighProtein = tempHighProtein;
                            _filterLowCarb = tempLowCarb;
                            _filterHighFat = tempHighFat;
                            _sortBy = tempSortBy;
                          });
                          _filterFoodItems();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F1EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F1EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedMealType,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMealType = newValue!;
              });
            },
            items: _mealTypes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        centerTitle: true,
        actions: const [], // Removed favorite and delete icons from AppBar
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.sort, color: Colors.grey),
                        onPressed: _showFilterOptions,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Create Food Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, CreateFoodPage.routeName).then((_) {
                            _loadAllFoodItems(); // Reload all items after creating a new one
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Food'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent / Favorites / Personal Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('Recent'),
                    _buildTabButton('Favorites'),
                    _buildTabButton('Personal'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredFoodItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No ${_currentTab.toLowerCase()} food items. Try another tab or create one!'
                            : 'No results found for "${_searchController.text}".',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredFoodItems.length,
                    itemBuilder: (context, index) {
                      final foodItem = _filteredFoodItems[index];
                      return _buildFoodItemCard(
                        foodItem,
                        _selectedItemsForMeal.contains(foodItem),
                        _favoriteFoodItems.any((favItem) =>
                            favItem['name'] == foodItem['name'] &&
                            favItem['calories'] == foodItem['calories'] &&
                            favItem['serving'] == foodItem['serving'] &&
                            favItem['unit'] == foodItem['unit']),
                      );
                    },
                  ),
          ),
          // --- Bottom Bar for Total Calories and Add Button ---
          if (_selectedItemsForMeal.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F1EC),
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Text(
                      'kcal ${_getTotalSelectedCalories()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealSummaryPage(
                                mealItems: _selectedItemsForMeal,
                                mealType: _selectedMealType,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              setState(() {
                                _selectedItemsForMeal.clear();
                                _loadAllFoodItems();
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text('Add (${_selectedItemsForMeal.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabName) {
    final isSelected = _currentTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tabName;
          _filterFoodItems();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8BC34A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a card for each food item in the list.
  /// Includes swipe-to-delete functionality for 'Personal' items.
  /// Also takes `isSelected` to show a checkmark and `isFavorite` to show a heart icon.
  Widget _buildFoodItemCard(Map<String, dynamic> foodItem, bool isSelected, bool isFavorite) {
    final bool canDismiss = _currentTab == 'Personal';
    final String emoji = foodItem['emoji'] ?? '🍔'; // Get emoji from item, default to burger

    Widget leadingWidget;
    if (isSelected) {
      leadingWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8BC34A), // Solid green when selected
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)), // Display emoji
      );
      // You could also overlay a checkmark if you want to be explicit about selection
      // child: Stack(
      //   alignment: Alignment.center,
      //   children: [
      //     Text(emoji, style: const TextStyle(fontSize: 24)),
      //     const Icon(Icons.check, color: Colors.white, size: 20),
      //   ],
      // ),
    } else {
      leadingWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8BC34A).withOpacity(0.2), // Light green when unselected
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)), // Display emoji
      );
    }

    Widget cardContent = ListTile(
      leading: leadingWidget,
      title: Text(foodItem['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${foodItem['calories']} kcal, ${foodItem['serving']} ${foodItem['unit']}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Favorite Button
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () => _toggleFavoriteStatus(foodItem),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: () {
        _toggleFoodItemSelection(foodItem);
      },
    );

    if (canDismiss) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Dismissible(
          key: ValueKey(foodItem['name'] + foodItem['calories'].toString() + foodItem.hashCode.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: Text('Are you sure you want to delete "${foodItem['name']}"?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deletePersonalFoodItem(foodItem);
          },
          child: cardContent,
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: cardContent,
      );
    }
  }
}
