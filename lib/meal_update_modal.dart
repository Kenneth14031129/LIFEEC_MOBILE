import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MealUpdateModal extends StatefulWidget {
  final Map<String, dynamic> currentMealData;

  const MealUpdateModal({
    super.key,
    required this.currentMealData,
  });

  @override
  State<MealUpdateModal> createState() => _MealUpdateModalState();
}

class _MealUpdateModalState extends State<MealUpdateModal> {
  final List<TextEditingController> _breakfastControllers = [];
  final List<TextEditingController> _lunchControllers = [];
  final List<TextEditingController> _dinnerControllers = [];
  final List<TextEditingController> _snacksControllers = [];
  late TextEditingController _dietaryNeedsController;
  late TextEditingController _nutritionalGoalsController;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers from existing data
    _initializeControllers('breakfast', _breakfastControllers);
    _initializeControllers('lunch', _lunchControllers);
    _initializeControllers('dinner', _dinnerControllers);
    _initializeControllers('snacks', _snacksControllers);

    _dietaryNeedsController = TextEditingController(
      text: widget.currentMealData['dietary needs'] ?? '',
    );
    _nutritionalGoalsController = TextEditingController(
      text: widget.currentMealData['nutritional goals'] ?? '',
    );
  }

  void _initializeControllers(String mealType, List<TextEditingController> controllers) {
    final items = widget.currentMealData[mealType];
    if (items is List) {
      for (var item in items) {
        controllers.add(TextEditingController(text: item.toString()));
      }
    } else if (items != null && items.isNotEmpty) {
      // Handle legacy single string data
      controllers.add(TextEditingController(text: items.toString()));
    }
    
    // Always ensure at least one empty controller
    if (controllers.isEmpty) {
      controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in [..._breakfastControllers, ..._lunchControllers, 
                          ..._dinnerControllers, ..._snacksControllers]) {
      controller.dispose();
    }
    _dietaryNeedsController.dispose();
    _nutritionalGoalsController.dispose();
    super.dispose();
  }

  Widget _buildMealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Details',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDynamicMealFields('Breakfast', _breakfastControllers),
                const SizedBox(height: 16),
                _buildDynamicMealFields('Lunch', _lunchControllers),
                const SizedBox(height: 16),
                _buildDynamicMealFields('Dinner', _dinnerControllers),
                const SizedBox(height: 16),
                _buildDynamicMealFields('Snacks', _snacksControllers),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicMealFields(String label, List<TextEditingController> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  controllers.add(TextEditingController());
                });
              },
              icon: Icon(Icons.add, size: 20, color: Colors.blue[700]),
              label: Text(
                'Add Item',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[index],
                      decoration: InputDecoration(
                        hintText: 'Enter ${label.toLowerCase()} item',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue[400]!),
                        ),
                      ),
                    ),
                  ),
                  if (controllers.length > 1)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                      onPressed: () {
                        setState(() {
                          controllers.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDietarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Requirements',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  'Dietary Needs',
                  'Enter dietary restrictions and requirements',
                  _dietaryNeedsController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Nutritional Goals',
                  'Enter nutritional goals',
                  _nutritionalGoalsController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Meal Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMealSection(),
              const SizedBox(height: 24),
              _buildDietarySection(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan[500] ?? Colors.cyan,
                            Colors.blue[600] ?? Colors.blue,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue[700]!.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () {
                          final updatedMealData = {
                            'date': DateTime.now().toString().split(' ')[0],
                            'breakfast': _breakfastControllers
                                .map((controller) => controller.text)
                                .where((text) => text.isNotEmpty)
                                .toList(),
                            'lunch': _lunchControllers
                                .map((controller) => controller.text)
                                .where((text) => text.isNotEmpty)
                                .toList(),
                            'dinner': _dinnerControllers
                                .map((controller) => controller.text)
                                .where((text) => text.isNotEmpty)
                                .toList(),
                            'snacks': _snacksControllers
                                .map((controller) => controller.text)
                                .where((text) => text.isNotEmpty)
                                .toList(),
                            'dietary needs': _dietaryNeedsController.text,
                            'nutritional goals': _nutritionalGoalsController.text,
                          };
                          Navigator.pop(context, updatedMealData);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}