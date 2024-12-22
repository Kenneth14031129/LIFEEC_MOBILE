// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'resident_provider.dart';
import 'resident.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ActivitiesPage extends StatefulWidget {
  final List<String> residentNames;
  final Resident? selectedResident;

  const ActivitiesPage(
      {super.key, required this.residentNames, this.selectedResident});

  @override
  ActivitiesPageState createState() => ActivitiesPageState();
}

class ActivitiesPageState extends State<ActivitiesPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedResidentName;
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final logger = Logger();
  final Map<String, Map<String, List<Map<String, String>>>>
      _submittedActivities = {};

  @override
  void dispose() {
    _activityNameController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _activityNameController.clear();
    _dateController.clear();
    _descriptionController.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final residentProvider =
          Provider.of<ResidentProvider>(context, listen: false);
      final resident = residentProvider.residents
          .firstWhere((res) => res.name == _selectedResidentName);

      final activity = {
        'residentId': resident.id,
        'activityName': _activityNameController.text,
        'date': _dateController.text,
        'description': _descriptionController.text,
        'status': 'Pending',
      };

      // Use the API URL from the .env file
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
      final url = Uri.parse('$baseUrl/activities/add');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(activity),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Success if status code is 200 or 201
          final responseData = jsonDecode(response.body);

          // Log successful response data
          logger.i('Activity added successfully: $responseData');

          // Update resident with new activity
          final updatedResident = resident.copyWith(
            activityName: _activityNameController.text,
            date: _dateController.text,
            description: _descriptionController.text,
          );
          residentProvider.updateResidentHealthData(updatedResident);

          setState(() {
            _submittedActivities.putIfAbsent(_selectedResidentName!, () => {});
            _submittedActivities[_selectedResidentName!]!
                .putIfAbsent(_dateController.text, () => []);
            _submittedActivities[_selectedResidentName!]![_dateController.text]!
                .add(activity);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity Scheduled Successfully')),
          );

          _clearFields();
        } else {
          // Log server response and display error message
          logger.e(
              'Failed to add activity: StatusCode ${response.statusCode}, Response: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to add activity. Please try again.')),
          );
        }
      } catch (e) {
        // Log exception and display a generic error message
        logger.e('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server.')),
        );
      }
    } else {
      // Log validation failure
      logger.w('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
    }
  }

  void _editActivity(Map<String, String> activity) {
    setState(() {
      _activityNameController.text = activity['activityName']!;
      _dateController.text = activity['date']!;
      _descriptionController.text = activity['description']!;
    });
  }

  Future<void> _deleteActivity(Map<String, String> activity) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this activity?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _submittedActivities[_selectedResidentName!]!
            .forEach((date, activities) {
          activities.remove(activity);
          if (activities.isEmpty) {
            _submittedActivities[_selectedResidentName!]!.remove(date);
          }
        });

        if (_submittedActivities[_selectedResidentName!]!.isEmpty) {
          _submittedActivities.remove(_selectedResidentName!);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity Deleted')),
      );
    }
  }

  void _toggleActivityStatus(Map<String, String> activity) {
    setState(() {
      activity['status'] =
          activity['status'] == 'Completed' ? 'Pending' : 'Completed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final residentProvider = Provider.of<ResidentProvider>(context);
    final residentNames =
        residentProvider.residents.map((res) => res.name).toList();

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
              'Activities',
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
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchableDropdown(residentNames),
                    const SizedBox(height: 20),
                    _buildTextFormField(
                      _activityNameController,
                      'Activity Name',
                      'Please enter the activity name',
                    ),
                    const SizedBox(height: 10),
                    _buildDateFormField(),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      _descriptionController,
                      'Description',
                      'Please enter a description',
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Add Activity'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActivitiesList(),
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
    return DropdownSearch<String>(
      items: residentNames,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select Resident",
          hintText: "Select a resident",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(width: 1),
          ),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _selectedResidentName = value;
        });
      },
      selectedItem: _selectedResidentName,
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller, String label, String validationText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationText;
        }
        return null;
      },
    );
  }

  Widget _buildDateFormField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(),
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

  Widget _buildActivitiesList() {
    return Column(
      children: _submittedActivities.entries
          .map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Column(
                    children: entry.value.entries
                        .map((dateEntry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateEntry.key,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Column(
                                  children: dateEntry.value
                                      .map((activity) => ListTile(
                                            title: Text(activity[
                                                'activityName']!), // activity name
                                            subtitle: Text(activity[
                                                'description']!), // description
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () {
                                                    _editActivity(activity);
                                                  },
                                                ),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () {
                                                    _deleteActivity(activity);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    activity['status'] ==
                                                            'Completed'
                                                        ? Icons.check_circle
                                                        : Icons
                                                            .radio_button_unchecked,
                                                  ),
                                                  onPressed: () {
                                                    _toggleActivityStatus(
                                                        activity);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ))
          .toList(),
    );
  }
}
