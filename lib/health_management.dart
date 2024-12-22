import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'resident_provider.dart';
import 'resident.dart';

class HealthManagementPage extends StatefulWidget {
  final List<String> residentNames;
  final Resident? selectedResident;

  const HealthManagementPage(
      {super.key, required this.residentNames, this.selectedResident});

  @override
  HealthManagementPageState createState() => HealthManagementPageState();
}

class HealthManagementPageState extends State<HealthManagementPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedResidentName;
  String? _selectedCondition;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _currentMedicationsController =
      TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medsScheduleMedicationController =
      TextEditingController();
  final TextEditingController _medsScheduleTimeController =
      TextEditingController();
  final TextEditingController _healthAssessmentController =
      TextEditingController();
  final TextEditingController _administrationInstructionController =
      TextEditingController();
  bool? _medicationTaken = false;

  final logger = Logger();

  @override
  void dispose() {
    _dateController.dispose();
    _statusController.dispose();
    _currentMedicationsController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _allergiesController.dispose();
    _medsScheduleMedicationController.dispose();
    _medsScheduleTimeController.dispose();
    _healthAssessmentController.dispose();
    _administrationInstructionController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _selectedCondition = null;
    _dateController.clear();
    _statusController.clear();
    _currentMedicationsController.clear();
    _dosageController.clear();
    _quantityController.clear();
    _allergiesController.clear();
    _medsScheduleMedicationController.clear();
    _medsScheduleTimeController.clear();
    _healthAssessmentController.clear();
    _administrationInstructionController.clear();
    setState(() {
      _medicationTaken = false;
    });
  }

  // Method to fetch resident data from the backend
  Future<void> fetchResidentData(String selectedResidentId) async {
    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/api/patient/$selectedResidentId'), // Replace with your actual API URL
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final residentData = jsonDecode(response.body);
      // Populate the form fields with resident data
      setState(() {
        _selectedCondition = residentData['medicalCondition'];
        _dateController.text = residentData['date'];
        _statusController.text = residentData['status'];
        _currentMedicationsController.text = residentData['currentMedication'];
        _dosageController.text = residentData['dosage'];
        _quantityController.text = residentData['quantity'];
        _allergiesController.text = residentData['allergy'];
        _medsScheduleMedicationController.text = residentData['medication'];
        _medsScheduleTimeController.text = residentData['time'];
        _medicationTaken = residentData['taken'] == true;
        _healthAssessmentController.text = residentData['healthAssessment'];
        _administrationInstructionController.text =
            residentData['administrationInstruction'];
      });
    } else {
      logger.e('Failed to fetch resident data');
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final residentProvider =
          Provider.of<ResidentProvider>(context, listen: false);
      final resident = residentProvider.residents
          .firstWhere((res) => res.name == _selectedResidentName);

      final updatedResident = resident.copyWith(
        medicalCondition: _selectedCondition ?? resident.medicalCondition,
        date: _dateController.text,
        status: _statusController.text,
        dosage: _dosageController.text,
        quantity: _quantityController.text,
        allergies: _allergiesController.text,
        medication: _medsScheduleMedicationController.text,
        time: _medsScheduleTimeController.text,
        takenOrNot: _medicationTaken == true ? 'Taken' : 'Not Taken',
        healthAssessment: _healthAssessmentController.text,
        administrationInstruction: _administrationInstructionController.text,
      );

      residentProvider.updateResidentHealthData(updatedResident);

      logger.i('Updated resident: $updatedResident');

      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health Management Submitted')),
      );
    } else {
      logger.w('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form validation failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final residentProvider = Provider.of<ResidentProvider>(context);
    final residentNames =
        residentProvider.residents.map((res) => res.name).toList();
    final medicalConditions = [
      'Arthritis',
      'Asthma',
      'Cancer',
      'Chronic Kidney Disease',
      'COPD',
      'Dementia',
      'Depression',
      'Diabetes',
      'Epilepsy',
      'Heart Disease',
      'Hypertension',
      'Osteoporosis',
      'Stroke'
    ]..sort();

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
            title: const Text(
              'Health Management',
              style: TextStyle(
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
              padding: const EdgeInsets.only(
                  bottom: 16, left: 16, right: 16, top: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchableDropdown(residentNames),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Health Progress', 'assets/images/fill_icon.png'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      children: [
                        _buildDropdownMedicalConditions(medicalConditions),
                        const SizedBox(height: 10),
                        _buildTextFormField(
                            _dateController, 'Date', 'Please enter a date'),
                        const SizedBox(height: 10),
                        _buildTextFormField(_statusController, 'Status',
                            'Please enter the status'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Medications', 'assets/images/fill_icon.png'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      children: [
                        _buildTextFormField(
                            _currentMedicationsController,
                            'Current Medications',
                            'Please enter current medications'),
                        const SizedBox(height: 10),
                        _buildTextFormField(_dosageController, 'Dosage',
                            'Please enter the dosage'),
                        const SizedBox(height: 10),
                        _buildTextFormField(_quantityController, 'Quantity',
                            'Please enter the quantity'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Allergies', 'assets/images/fill_icon.png'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      children: [
                        _buildTextFormField(_allergiesController, 'Allergies',
                            'Please enter allergies'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Medication Schedule', 'assets/images/fill_icon.png'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      children: [
                        _buildTextFormField(_medsScheduleMedicationController,
                            'Medication', 'Please enter medication'),
                        const SizedBox(height: 10),
                        _buildTextFormField(_medsScheduleTimeController, 'Time',
                            'Please enter time'),
                        const SizedBox(height: 10),
                        _buildCheckboxField('Taken or Not', _medicationTaken,
                            (bool? value) {
                          setState(() {
                            _medicationTaken = value;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                        'Health Assessment', 'assets/images/fill_icon.png'),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      children: [
                        _buildTextFormField(
                            _healthAssessmentController,
                            'Health Assessment',
                            'Please enter health assessment'),
                        const SizedBox(height: 10),
                        _buildTextFormField(
                            _administrationInstructionController,
                            'Administration Instruction',
                            'Please enter administration instruction'),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Submit'),
                      ),
                    ),
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
            selectedItem: _selectedResidentName,
            onChanged: (value) async {
              setState(() {
                _selectedResidentName = value;
              });
              if (value != null) {
                // Find the selected resident ID
                final selectedResidentId = context
                    .read<ResidentProvider>()
                    .residents
                    .firstWhere((resident) => resident.name == value)
                    .id;

                // Fetch and populate the resident's health data
                await fetchResidentData(selectedResidentId);
              }
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

  Widget _buildDropdownMedicalConditions(List<String> conditions) {
    return DropdownButtonFormField<String>(
      value: _selectedCondition,
      decoration: const InputDecoration(
        labelText: 'Medical Condition',
        border: OutlineInputBorder(),
      ),
      items: conditions.map((String condition) {
        return DropdownMenuItem<String>(
          value: condition,
          child: Text(condition),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedCondition = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a medical condition';
        }
        return null;
      },
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String labelText,
      String validationMessage) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage;
        }
        return null;
      },
    );
  }

  Widget _buildCheckboxField(
      String label, bool? value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String imagePath) {
    return Row(
      children: [
        Image.asset(imagePath, width: 24, height: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
