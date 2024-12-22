import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'resident_provider.dart';
import 'resident.dart';

class MealManagementPage extends StatefulWidget {
  final List<String> residentNames;
  final Resident? selectedResident;

  const MealManagementPage({super.key, required this.residentNames, this.selectedResident});

  @override
  MealManagementPageState createState() => MealManagementPageState();
}

class MealManagementPageState extends State<MealManagementPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedResident;
  DateTime? _selectedDate;
  List<String> _selectedBreakfast = [];
  List<String> _selectedLunch = [];
  List<String> _selectedSnacks = [];
  List<String> _selectedDinner = [];

  final List<Map<String, dynamic>> _mealsList = [];
  Map<String, dynamic>? _editingMeal;

  final List<String> _breakfastList = [
    'Apple Pie', 'Bagel', 'Cereal', 'Doughnut', 'Eggs', 'French Toast', 'Granola', 'Hash Browns',
    'Iced Coffee', 'Juice', 'Kale Smoothie', 'Lox', 'Muffin', 'Nuts', 'Oatmeal', 'Pancakes',
    'Quiche', 'Raisin Bran', 'Sausage', 'Toast', 'Udon', 'Vanilla Yogurt', 'Waffles', 'Xylocarp',
    'Yogurt', 'Zucchini Bread'
  ];

  final List<String> _lunchList = [
    'Apple', 'BLT Sandwich', 'Chicken Salad', 'Dumplings', 'Egg Salad', 'Fried Rice', 'Grilled Cheese',
    'Hamburger', 'Ice Cream', 'Jambalaya', 'Kebab', 'Linguine', 'Meatloaf', 'Noodles', 'Onion Rings',
    'Pizza', 'Quesadilla', 'Ravioli', 'Soup', 'Tacos', 'Udon', 'Vegetable Stir Fry', 'Wrap', 'Xiaolongbao',
    'Yakisoba', 'Ziti'
  ];

  final List<String> _snacksList = [
    'Almonds', 'Berries', 'Chips', 'Dried Fruit', 'Energy Bar', 'Fruit Salad', 'Granola Bar',
    'Hummus', 'Ice Cream', 'Jelly Beans', 'Kale Chips', 'Lemonade', 'Muffins', 'Nuts', 'Olives',
    'Popcorn', 'Quiche', 'Raisins', 'Smoothie', 'Trail Mix', 'Ugli Fruit', 'Vegetable Sticks', 'Walnuts',
    'Xylocarp', 'Yogurt', 'Zucchini Bread'
  ];

  final List<String> _dinnerList = [
    'Apple Salad', 'Beef Stew', 'Chicken Parmesan', 'Duck Confit', 'Eggplant Parmesan', 'Fish Tacos',
    'Goulash', 'Hamburger', 'Indian Curry', 'Jambalaya', 'Kebabs', 'Lasagna', 'Meatballs', 'Noodle Soup',
    'Omelette', 'Pasta', 'Quiche', 'Risotto', 'Spaghetti', 'Tuna Casserole', 'Udon', 'Vegetable Stir Fry',
    'Wiener Schnitzel', 'Xiaolongbao', 'Yellow Curry', 'Ziti'
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _clearFields() {
    _selectedDate = null;
    _selectedBreakfast.clear();
    _selectedLunch.clear();
    _selectedSnacks.clear();
    _selectedDinner.clear();
    setState(() {
      _selectedResident = null;
      _editingMeal = null;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final initialDate = _selectedDate ?? DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  void _editMeal(Map<String, dynamic> meal) {
    setState(() {
      _selectedResident = meal['resident'];
      _selectedDate = meal['date'];
      _selectedBreakfast = (meal['breakfast'] as String).split(', ');
      _selectedLunch = (meal['lunch'] as String).split(', ');
      _selectedSnacks = (meal['snacks'] as String).split(', ');
      _selectedDinner = (meal['dinner'] as String).split(', ');
      _editingMeal = meal;
    });
  }

  void _deleteMeal(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this meal entry?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _mealsList.remove(meal);
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _toggleMealStatus(Map<String, dynamic> meal) {
    setState(() {
      meal['status'] = meal['status'] == 'Completed' ? 'Pending' : 'Completed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final residentNames = Provider.of<ResidentProvider>(context).residents.map((resident) => resident.name).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              'Meal Management',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchableDropdown(residentNames),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Input Meals', 'assets/images/fill_icon.png'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      children: [
                        _buildDatePickerField(context),
                        const SizedBox(height: 10),
                        _buildMultiSelectField(
                          selectedItems: _selectedBreakfast,
                          labelText: 'Breakfast',
                          errorText: 'Please select a breakfast item',
                          items: _breakfastList,
                          icon: FontAwesomeIcons.breadSlice,
                        ),
                        const SizedBox(height: 10),
                        _buildMultiSelectField(
                          selectedItems: _selectedLunch,
                          labelText: 'Lunch',
                          errorText: 'Please select a lunch item',
                          items: _lunchList,
                          icon: FontAwesomeIcons.burger,
                        ),
                        const SizedBox(height: 10),
                        _buildMultiSelectField(
                          selectedItems: _selectedSnacks,
                          labelText: 'Snacks',
                          errorText: 'Please select a snack item',
                          items: _snacksList,
                          icon: FontAwesomeIcons.cookieBite,
                        ),
                        const SizedBox(height: 10),
                        _buildMultiSelectField(
                          selectedItems: _selectedDinner,
                          labelText: 'Dinner',
                          errorText: 'Please select a dinner item',
                          items: _dinnerList,
                          icon: FontAwesomeIcons.utensils,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedResident != null && _selectedDate != null) {
                              final provider = Provider.of<ResidentProvider>(context, listen: false);
                              final resident = provider.residents.firstWhere((r) => r.name == _selectedResident);

                              final updatedResident = resident.copyWith(
                                date: _selectedDate!.toIso8601String(),
                                breakfast: _selectedBreakfast.join(', '),
                                lunch: _selectedLunch.join(', '),
                                snacks: _selectedSnacks.join(', '),
                                dinner: _selectedDinner.join(', '),
                              );

                              provider.updateResidentHealthData(updatedResident);

                              setState(() {
                                if (_editingMeal != null) {
                                  _editingMeal!['date'] = _selectedDate!;
                                  _editingMeal!['resident'] = _selectedResident!;
                                  _editingMeal!['breakfast'] = _selectedBreakfast.join(', ');
                                  _editingMeal!['lunch'] = _selectedLunch.join(', ');
                                  _editingMeal!['snacks'] = _selectedSnacks.join(', ');
                                  _editingMeal!['dinner'] = _selectedDinner.join(', ');
                                } else {
                                  _mealsList.add({
                                    'date': _selectedDate!,
                                    'resident': _selectedResident!,
                                    'breakfast': _selectedBreakfast.join(', '),
                                    'lunch': _selectedLunch.join(', '),
                                    'snacks': _selectedSnacks.join(', '),
                                    'dinner': _selectedDinner.join(', '),
                                    'status': 'Pending', // Initialize status as Pending
                                  });
                                }
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Meal Management Submitted')),
                              );

                              _clearFields();
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form validation failed')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                          shadowColor: Colors.black.withOpacity(0.5),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blueAccent, Colors.lightBlueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Submit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedResident != null)
                      ..._mealsList
                          .where((meal) => meal['resident'] == _selectedResident)
                          .map((meal) => _buildMealTable(meal)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown(List<String> residentNames) {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownSearch<String>(
            items: residentNames,
            selectedItem: _selectedResident,
            onChanged: (value) {
              setState(() {
                _selectedResident = value;
              });
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Select Resident',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  labelText: 'Search Resident',
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a resident';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String iconPath) {
    return Row(
      children: [
        Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(iconPath, color: Colors.white, width: 24, height: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children, bool border = true}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
        ],
        border: border ? Border.all(color: Colors.black) : null,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMultiSelectField({
    required List<String> selectedItems,
    required String labelText,
    required String errorText,
    required List<String> items,
    required IconData icon,
  }) {
    return DropdownSearch<String>.multiSelection(
      items: items,
      selectedItems: selectedItems,
      onChanged: (value) {
        setState(() {
          selectedItems.clear();
          selectedItems.addAll(value);
        });
      },
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          prefixIcon: Icon(icon),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorText;
        }
        return null;
      },
    );
  }

  Widget _buildDatePickerField(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '',
          ),
          decoration: const InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a date';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildMealTable(Map<String, dynamic> meal) {
  final isCompleted = meal['status'] == 'Completed';

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 20),
    decoration: BoxDecoration(
      color: isCompleted ? Colors.green.withOpacity(0.8) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(3, 3),
          blurRadius: 6,
        ),
      ],
      border: Border.all(color: Colors.black),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(meal['date'])}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      meal['status'] == 'Completed' ? Icons.check_circle : Icons.check_circle_outline,
                      color: meal['status'] == 'Completed' ? Colors.teal : Colors.grey,
                    ),
                    onPressed: () {
                      _toggleMealStatus(meal);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () {
                      _editMeal(meal);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      _deleteMeal(meal);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.black),
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              _buildTableRow('Breakfast', meal['breakfast']),
              _buildTableRow('Lunch', meal['lunch']),
              _buildTableRow('Snacks', meal['snacks']),
              _buildTableRow('Dinner', meal['dinner']),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Status: ${meal['status']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String mealType, String meal) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            mealType,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meal,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}