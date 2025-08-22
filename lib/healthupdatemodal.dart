import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CustomTimePicker extends StatefulWidget {
  final String initialTime;
  final Function(String) onTimeSelected;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late String displayTime;

  @override
  void initState() {
    super.initState();
    displayTime = _formatTime(widget.initialTime);
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    try {
      // Handle different time formats
      DateTime dateTime;
      if (time.contains(':')) {
        // If time is in HH:mm format
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute =
            int.parse(parts[1].split(' ')[0]); // Remove AM/PM if present
        dateTime = DateTime(2024, 1, 1, hour, minute);
      } else {
        return time; // Return original if format is unexpected
      }
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  String _convertTo24Hour(String time12) {
    try {
      final format = DateFormat('h:mm a');
      final dateTime = format.parse(time12);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return time12;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime;
    try {
      if (displayTime.isNotEmpty) {
        final format = DateFormat('h:mm a');
        final dateTime = format.parse(displayTime);
        initialTime = TimeOfDay.fromDateTime(dateTime);
      } else {
        initialTime = TimeOfDay.now();
      }
    } catch (e) {
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.blue[800],
              dialBackgroundColor: Colors.grey[100],
              dialHandColor: Colors.blue[600],
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final dateTime = DateTime(2024, 1, 1, picked.hour, picked.minute);
        displayTime = DateFormat('h:mm a').format(dateTime);
        widget.onTimeSelected(_convertTo24Hour(displayTime));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              displayTime.isEmpty ? 'Select time' : displayTime,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: displayTime.isEmpty ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthUpdateModal extends StatefulWidget {
  final Map<String, dynamic> currentHealthData;

  const HealthUpdateModal({
    super.key,
    required this.currentHealthData,
  });

  @override
  State<HealthUpdateModal> createState() => _HealthUpdateModalState();
}

class _HealthUpdateModalState extends State<HealthUpdateModal> {
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _assessmentNotesController;
  late TextEditingController _specialInstructionsController;
  late List<Map<String, dynamic>> medications;
  String _selectedStatus = 'Stable';

  @override
  void initState() {
    super.initState();

    // Initialize status with proper mapping of values
    final currentStatus = widget.currentHealthData['status'];
    if (currentStatus != null) {
      // Map any incoming status to our valid options
      switch (currentStatus.toString().toLowerCase()) {
        case 'active':
        case 'stable':
          _selectedStatus = 'Stable';
          break;
        case 'critical':
          _selectedStatus = 'Critical';
          break;
        default:
          _selectedStatus = 'Stable'; // Default fallback
      }
    }

    // Handle allergies that might be a string or a list
    final allergies = widget.currentHealthData['allergies'];
    String allergiesText = '';
    if (allergies != null) {
      if (allergies is List) {
        allergiesText = allergies.join(', ');
      } else {
        allergiesText = allergies.toString();
      }
    }
    _allergiesController = TextEditingController(text: allergiesText);

    // Handle conditions that might be a string or a list
    final conditions = widget.currentHealthData['conditions'];
    String conditionsText = '';
    if (conditions != null) {
      if (conditions is List) {
        conditionsText = conditions.join(', ');
      } else {
        conditionsText = conditions.toString();
      }
    }
    _conditionsController = TextEditingController(text: conditionsText);

    _assessmentNotesController = TextEditingController(
      text: widget.currentHealthData['assessment'] ??
          widget.currentHealthData['assessmentNotes'] ??
          'No specific notes at this time.',
    );

    _specialInstructionsController = TextEditingController(
      text: widget.currentHealthData['instructions'] ??
          widget.currentHealthData['specialInstructions'] ??
          'No special instructions at this time.',
    );

    // Replace the medications initialization with this new code
    if (widget.currentHealthData['medications'] is List) {
      medications = List<Map<String, dynamic>>.from(
        widget.currentHealthData['medications'].map((med) => {
              'medication':
                  med['medication'] ?? '', // This will be the 'name' field
              'dosage': med['dosage'] ?? '',
              'quantity': med['quantity'] ?? '',
              'time': med['time'] ??
                  med['medicationTime'] ??
                  '', // Handle both old and new format
              'status':
                  med['isMedicationTaken'] == true ? 'Taken' : 'Not taken',
              'medicationController': TextEditingController(
                  text: med['medication'] ?? med['name'] ?? ''),
              'dosageController':
                  TextEditingController(text: med['dosage'] ?? ''),
              'quantityController':
                  TextEditingController(text: med['quantity'] ?? ''),
            }),
      );
    } else if (widget.currentHealthData['medications'] != null) {
      medications = [
        {
          'medication': widget.currentHealthData['medications'],
          'dosage': widget.currentHealthData['dosage'] ?? '',
          'quantity': widget.currentHealthData['quantity'] ?? '',
          'time': widget.currentHealthData['medicationTime'] ?? '',
          'status': widget.currentHealthData['isMedicationTaken']
              ? 'Taken'
              : 'Not taken',
          'medicationController': TextEditingController(
              text: widget.currentHealthData['medications']),
          'dosageController': TextEditingController(
              text: widget.currentHealthData['dosage'] ?? ''),
          'quantityController': TextEditingController(
              text: widget.currentHealthData['quantity'] ?? ''),
        }
      ];
    } else {
      medications = [];
    }
  }

  void _addNewMedication() {
    setState(() {
      medications.add({
        'medication': '',
        'dosage': '',
        'quantity': '',
        'time': '',
        'status': 'Not taken',
        'medicationController': TextEditingController(),
        'dosageController': TextEditingController(),
        'quantityController': TextEditingController(),
      });
    });
  }

  @override
  void dispose() {
    for (var medication in medications) {
      medication['medicationController'].dispose();
      medication['dosageController'].dispose();
      medication['quantityController'].dispose();
    }
    _allergiesController.dispose();
    _conditionsController.dispose();
    _assessmentNotesController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
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
                    'Update Health Plan',
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
              // Add status selection
              Text(
                'Resident Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  underline: Container(),
                  items: ['Stable', 'Critical'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          color: value == 'Critical'
                              ? Colors.red
                              : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Allergies',
                'Enter allergies (comma-separated)',
                _allergiesController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Medical Conditions',
                'Enter medical conditions (comma-separated)',
                _conditionsController,
              ),
              const SizedBox(height: 24),
              Text(
                'Medication Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              _buildMedicationsList(),
              const SizedBox(height: 24),
              Text(
                'Health Assessment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              _buildHealthAssessment(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _addNewMedication,
              icon: Icon(Icons.add_circle_outline, color: Colors.blue[600]),
              label: Text(
                'Add Medication',
                style: GoogleFonts.poppins(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Medication ${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              medications.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMedicationField(
                      'Medication',
                      medication['medication'] ?? '',
                      (value) {
                        setState(() {
                          medication['medication'] = value;
                        });
                      },
                      controller: medication['medicationController'],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMedicationField(
                            'Dosage',
                            medication['dosage'] ?? '',
                            (value) {
                              setState(() {
                                medication['dosage'] = value;
                              });
                            },
                            controller: medication['dosageController'],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMedicationField(
                            'Quantity',
                            medication['quantity'] ?? '',
                            (value) {
                              setState(() {
                                medication['quantity'] = value;
                              });
                            },
                            controller: medication['quantityController'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMedicationField(
                      'Time',
                      medication['time'] is List
                          ? medication['time'].join(', ')
                          : medication['time'] ?? '',
                      (value) {
                        setState(() {
                          medication['time'] = [value];
                        });
                      },
                      isTimeField: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: medication['status'] == 'Taken',
                          onChanged: (bool? value) {
                            setState(() {
                              medication['status'] =
                                  value == true ? 'Taken' : 'Not taken';
                            });
                          },
                          activeColor: Colors.blue[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMedicationField(
    String label,
    String initialValue,
    Function(String) onChanged, {
    bool isTimeField = false,
    TextEditingController? controller,
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
        if (isTimeField)
          CustomTimePicker(
            initialTime:
                initialValue, // Remove the List check since we now store as string
            onTimeSelected: (value) {
              onChanged(value); // This will be stored directly as a string
            },
          )
        else
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
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

  Widget _buildHealthAssessment() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assessment Notes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _assessmentNotesController,
                  maxLines: 3,
                  decoration: InputDecoration(
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
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _specialInstructionsController,
                  maxLines: 3,
                  decoration: InputDecoration(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
                  color: Colors.blue[700]!.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                final updatedHealthData = {
                  'status': _selectedStatus,
                  'allergies': _allergiesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  'conditions': _conditionsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  'medications': medications
                      .map((med) => {
                            'name': med['medicationController'].text,
                            'dosage': med['dosageController'].text,
                            'quantity': med['quantityController'].text,
                            'medicationTime': med['time'] is List
                                ? med['time'][0]
                                : med['time'], // Convert array to single string
                            'isMedicationTaken': med['status'] == 'Taken'
                          })
                      .toList(),
                  'assessmentNotes': _assessmentNotesController.text,
                  'specialInstructions': _specialInstructionsController.text,
                };

                if (kDebugMode) {
                  print('Sending updated data: $updatedHealthData');
                }

                Navigator.pop(context, updatedHealthData);
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
    );
  }
}
