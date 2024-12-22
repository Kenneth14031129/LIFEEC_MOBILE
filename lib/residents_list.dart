import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'resident_provider.dart';
import 'resident.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ResidentsListPage extends StatefulWidget {
  const ResidentsListPage({super.key, required List residents});

  @override
  ResidentsListPageState createState() => ResidentsListPageState();
}

class ResidentsListPageState extends State<ResidentsListPage> {
  Resident? _selectedResident;
  final Uuid uuid = const Uuid();
  Map<String, dynamic> _healthProgressData = {};
  Map<String, List<dynamic>> _activitiesData = {};
  Map<String, List<dynamic>> _mealData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchResidents();
      _fetchActivities();
      _fetchHealthProgress();
      _fetchMeals();
    });
  }

  String formatDateForDisplay(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: $e');
      }
      return 'Invalid Date';
    }
  }

  String formatDateForInput(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: $e');
      }
      return '';
    }
  }

  String formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 'N/A';
    }
    try {
      // Parse the time string
      DateTime time = DateFormat.Hm().parse(timeString);
      // Format the time in 12-hour format with AM/PM
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return timeString; // Return original string if parsing fails
    }
  }

  Future<void> _fetchResidents() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/api/patient/list'));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<Resident> residents = jsonData.map((data) {
          return Resident(
            id: data['_id'],
            name: data['name'],
            age: data['age'],
            gender: data['gender'],
            contact: data['contact'] ?? '',
            emergencyContactName: data['emergencyContact']['name'] ?? '',
            emergencyContactPhone: data['emergencyContact']['phone'] ?? '',
            medicalCondition: data['medicalCondition'] ?? '',
            date: formatDateForDisplay(data['date']),
            status: data['status'] ?? '',
            medication: data['medication'] ?? '',
            dosage: data['dosage'] ?? '',
            quantity: data['quantity'] ?? '',
            time: data['time'] ?? '',
            takenOrNot: data['takenorNot'] ?? '',
            allergies: data['allergies'] ?? '',
            healthAssessment: data['healthAssessment'] ?? '',
            administrationInstruction: data['administrationInstruction'] ?? '',
            dietaryNeeds: data['dietaryNeeds'] ?? '',
            nutritionGoals: data['nutritionGoals'] ?? '',
            activityName: data['activityName'] ?? '',
            description: data['description'] ?? '',
            breakfast: data['breakfast'] ?? '',
            lunch: data['lunch'] ?? '',
            snacks: data['snacks'] ?? '',
            dinner: data['dinner'] ?? '',
          );
        }).toList();

        if (mounted) {
          Provider.of<ResidentProvider>(context, listen: false)
              .setResidents(residents);
          setState(() {
            _selectedResident = residents.isNotEmpty ? residents.first : null;
          });
        }
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/api/activities/list'));
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        List<dynamic> activities = jsonData['activities'];
        Map<String, List<dynamic>> activitiesMap = {};

        for (var activity in activities) {
          String residentId = activity['residentId'];
          if (!activitiesMap.containsKey(residentId)) {
            activitiesMap[residentId] = [];
          }
          activitiesMap[residentId]!.add(activity);
        }

        setState(() {
          _activitiesData = activitiesMap;
        });
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      debugPrint('Error fetching activities: ${e.toString()}');
    }
  }

  Future<void> updateActivity(
      String id, String activityName, String date, String description) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/activities/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'activityName': activityName,
          'date': date,
          'description': description,
        }),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Activity updated successfully
        _fetchActivities(); // Refresh the activities list
      } else {
        throw Exception(
            'Failed to update activity: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating activity: ${e.toString()}');
      }
      // You might want to show an error message to the user here
    }
  }

  void _showUpdateActivityDialog(dynamic activity) {
    TextEditingController nameController =
        TextEditingController(text: activity['activityName']);
    TextEditingController dateController =
        TextEditingController(text: formatDateForInput(activity['date']));
    TextEditingController descriptionController =
        TextEditingController(text: activity['description']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Activity'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Activity Name'),
                ),
                TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                updateActivity(
                  activity['_id'],
                  nameController.text,
                  dateController.text,
                  descriptionController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchHealthProgress() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/api/health-progress/list'));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        Map<String, dynamic> healthProgressMap = {};
        for (var item in jsonData) {
          String residentId = item['residentId'];
          if (!healthProgressMap.containsKey(residentId)) {
            healthProgressMap[residentId] = [];
          }
          healthProgressMap[residentId].add(item);
        }
        setState(() {
          _healthProgressData = healthProgressMap;
        });
      } else {
        throw Exception('Failed to load health progress data');
      }
    } catch (e) {
      debugPrint('Error fetching health progress: ${e.toString()}');
    }
  }

  Future<void> updateHealthProgress(
      String id, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/health-progress/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        // Health progress updated successfully
        _fetchHealthProgress(); // Refresh the health progress list
      } else {
        throw Exception(
            'Failed to update health progress: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating health progress: ${e.toString()}');
      }
      // You might want to show an error message to the user here
    }
  }

  void _showUpdateHealthProgressDialog(dynamic healthProgress) {
    TextEditingController allergyController =
        TextEditingController(text: healthProgress['allergy']);
    TextEditingController medicalConditionController =
        TextEditingController(text: healthProgress['medicalCondition']);
    TextEditingController dateController =
        TextEditingController(text: formatDateForInput(healthProgress['date']));
    TextEditingController statusController =
        TextEditingController(text: healthProgress['status']);
    TextEditingController currentMedicationController =
        TextEditingController(text: healthProgress['currentMedication']);
    TextEditingController dosageController =
        TextEditingController(text: healthProgress['dosage']);
    TextEditingController quantityController =
        TextEditingController(text: healthProgress['quantity'].toString());
    TextEditingController medicationController =
        TextEditingController(text: healthProgress['medication']);
    TextEditingController timeController =
        TextEditingController(text: formatTime(healthProgress['time']));
    TextEditingController healthAssessmentController =
        TextEditingController(text: healthProgress['healthAssessment']);
    TextEditingController administrationInstructionController =
        TextEditingController(
            text: healthProgress['administrationInstruction']);

    bool isTaken = healthProgress['taken'] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Health Progress'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: allergyController,
                    decoration: const InputDecoration(labelText: 'Allergy'),
                  ),
                  TextField(
                    controller: medicalConditionController,
                    decoration:
                        const InputDecoration(labelText: 'Medical Condition'),
                  ),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date'),
                  ),
                  TextField(
                    controller: statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  TextField(
                    controller: currentMedicationController,
                    decoration:
                        const InputDecoration(labelText: 'Current Medication'),
                  ),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: medicationController,
                    decoration: const InputDecoration(labelText: 'Medication'),
                  ),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Time'),
                  ),
                  SwitchListTile(
                    title: const Text('Taken'),
                    value: isTaken,
                    onChanged: (bool value) {
                      setState(() {
                        isTaken = value;
                      });
                    },
                  ),
                  TextField(
                    controller: healthAssessmentController,
                    decoration:
                        const InputDecoration(labelText: 'Health Assessment'),
                    maxLines: 3,
                  ),
                  TextField(
                    controller: administrationInstructionController,
                    decoration: const InputDecoration(
                        labelText: 'Administration Instruction'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Update'),
                onPressed: () {
                  updateHealthProgress(
                    healthProgress['_id'],
                    {
                      'allergy': allergyController.text,
                      'medicalCondition': medicalConditionController.text,
                      'date': dateController.text,
                      'status': statusController.text,
                      'currentMedication': currentMedicationController.text,
                      'dosage': dosageController.text,
                      'quantity': int.parse(quantityController.text),
                      'medication': medicationController.text,
                      'time': timeController.text,
                      'taken': isTaken,
                      'healthAssessment': healthAssessmentController.text,
                      'administrationInstruction':
                          administrationInstructionController.text,
                    },
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _fetchMeals() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/api/v1/meal/list'));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        Map<String, List<dynamic>> mealMap = {};
        for (var meal in jsonData) {
          String residentId = meal['residentId'];
          if (!mealMap.containsKey(residentId)) {
            mealMap[residentId] = [];
          }
          mealMap[residentId]!.add(meal);
        }
        setState(() {
          _mealData = mealMap;
        });
      } else {
        throw Exception('Failed to load meal data');
      }
    } catch (e) {
      debugPrint('Error fetching meals: ${e.toString()}');
    }
  }

  Future<void> updateMeal(String id, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/meal/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        // Meal updated successfully
        _fetchMeals(); // Refresh the meal list
      } else {
        throw Exception(
            'Failed to update meal: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating meal: ${e.toString()}');
      }
      // You might want to show an error message to the user here
    }
  }

  void _showUpdateMealDialog(dynamic meal) {
    TextEditingController dietaryNeedsController =
        TextEditingController(text: meal['dietaryNeeds']);
    TextEditingController nutritionalGoalsController =
        TextEditingController(text: meal['nutritionalGoals']);
    TextEditingController dateController =
        TextEditingController(text: formatDateForInput(meal['date']));
    TextEditingController breakfastController =
        TextEditingController(text: meal['breakfast'].join(', '));
    TextEditingController lunchController =
        TextEditingController(text: meal['lunch'].join(', '));
    TextEditingController snacksController =
        TextEditingController(text: meal['snacks'].join(', '));
    TextEditingController dinnerController =
        TextEditingController(text: meal['dinner'].join(', '));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Meal'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: dietaryNeedsController,
                  decoration: const InputDecoration(labelText: 'Dietary Needs'),
                ),
                TextField(
                  controller: nutritionalGoalsController,
                  decoration:
                      const InputDecoration(labelText: 'Nutritional Goals'),
                ),
                TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: breakfastController,
                  decoration: const InputDecoration(
                      labelText: 'Breakfast (comma-separated)'),
                ),
                TextField(
                  controller: lunchController,
                  decoration: const InputDecoration(
                      labelText: 'Lunch (comma-separated)'),
                ),
                TextField(
                  controller: snacksController,
                  decoration: const InputDecoration(
                      labelText: 'Snacks (comma-separated)'),
                ),
                TextField(
                  controller: dinnerController,
                  decoration: const InputDecoration(
                      labelText: 'Dinner (comma-separated)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                updateMeal(
                  meal['_id'],
                  {
                    'dietaryNeeds': dietaryNeedsController.text,
                    'nutritionalGoals': nutritionalGoalsController.text,
                    'date': dateController.text,
                    'breakfast': breakfastController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    'lunch': lunchController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    'snacks': snacksController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    'dinner': dinnerController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                  },
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final residents = Provider.of<ResidentProvider>(context).residents;

    if (_selectedResident != null && !residents.contains(_selectedResident)) {
      _selectedResident = null;
    }

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
              'Residents List',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchableDropdown(residents),
                const SizedBox(height: 10),
                if (_selectedResident != null)
                  Expanded(
                    child: ListView(
                      children: [
                        _buildBasicInformation(_selectedResident!),
                        const SizedBox(height: 10),
                        _buildHealthManagement(_selectedResident!),
                        const SizedBox(height: 10),
                        _buildMealManagement(_selectedResident!),
                        const SizedBox(height: 10),
                        _buildActivities(_selectedResident!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown(List<Resident> residents) {
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
          child: DropdownSearch<Resident>(
            items: residents,
            selectedItem: _selectedResident,
            itemAsString: (Resident u) => u.name,
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
              if (value == null) {
                return 'Please select a resident';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInformation(Resident resident) {
    return _buildSection(
      'Basic Information',
      [
        _buildDetailRow('Name:', resident.name),
        _buildDetailRow('Age:', resident.age.toString()),
        _buildDetailRow('Gender:', resident.gender),
        _buildDetailRow('Contact:', resident.contact),
        const SizedBox(height: 10),
        Text(
          'Emergency Contacts',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        _buildDetailRow(
            'Emergency Contact Name:', resident.emergencyContactName),
        _buildDetailRow(
            'Emergency Contact Phone:', resident.emergencyContactPhone),
      ],
    );
  }

  Widget _buildHealthManagement(Resident resident) {
    List<dynamic> residentHealthProgress =
        _healthProgressData[resident.id] ?? [];
    return _buildSection(
      'Health Management',
      [
        Text(
          'Health Progress',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        ...residentHealthProgress.map((progress) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Allergies:', progress['allergy'] ?? 'N/A'),
                _buildDetailRow('Medical Condition:',
                    progress['medicalCondition'] ?? 'N/A'),
                _buildDetailRow(
                    'Date:', formatDateForDisplay(progress['date'])),
                _buildDetailRow('Status:', progress['status'] ?? 'N/A'),
                Text(
                  'Medications',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                _buildDetailRow('Current Medication:',
                    progress['currentMedication'] ?? 'N/A'),
                _buildDetailRow('Dosage:', progress['dosage'] ?? 'N/A'),
                _buildDetailRow(
                    'Quantity:', progress['quantity']?.toString() ?? 'N/A'),
                Text(
                  'Medication Schedule',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                _buildDetailRow('Medication:', progress['medication'] ?? 'N/A'),
                _buildDetailRow('Time:', formatTime(progress['time'])),
                _buildDetailRow(
                    'Taken:', progress['taken'] == true ? 'Yes' : 'No'),
                Text(
                  'Care Plans',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                _buildDetailRow('Health Assessment:',
                    progress['healthAssessment'] ?? 'N/A'),
                _buildDetailRow('Administration Instruction:',
                    progress['administrationInstruction'] ?? 'N/A'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _showUpdateHealthProgressDialog(progress);
                  },
                  child: const Text('Update Health Progress'),
                ),
                const Divider(),
              ],
            )),
        if (residentHealthProgress.isEmpty)
          const Text('No health progress data available for this resident.'),
      ],
    );
  }

  Widget _buildMealManagement(Resident resident) {
    List<dynamic> residentMeals = _mealData[resident.id] ?? [];
    return _buildSection(
      'Meal Management',
      [
        ...residentMeals.map((meal) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Dietary Needs:', meal['dietaryNeeds']),
                _buildDetailRow('Nutritional Goals:', meal['nutritionalGoals']),
                _buildDetailRow('Date:', formatDateForDisplay(meal['date'])),
                const SizedBox(height: 10),
                Text(
                  'Meals',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                _buildDetailRow('Breakfast:', meal['breakfast'].join(', ')),
                _buildDetailRow('Lunch:', meal['lunch'].join(', ')),
                _buildDetailRow('Snacks:', meal['snacks'].join(', ')),
                _buildDetailRow('Dinner:', meal['dinner'].join(', ')),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _showUpdateMealDialog(meal);
                  },
                  child: const Text('Update Meal'),
                ),
                const Divider(),
              ],
            )),
        if (residentMeals.isEmpty)
          const Text('No meal data available for this resident.'),
      ],
    );
  }

  Widget _buildActivities(Resident resident) {
    List<dynamic> residentActivities = _activitiesData[resident.id] ?? [];
    return _buildSection(
      'Activities',
      [
        ...residentActivities.map((activity) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Activity Name:', activity['activityName'] ?? 'N/A'),
                _buildDetailRow(
                    'Date:', formatDateForDisplay(activity['date'])),
                _buildDetailRow(
                    'Description:', activity['description'] ?? 'N/A'),
                ElevatedButton(
                  onPressed: () {
                    _showUpdateActivityDialog(activity);
                  },
                  child: const Text('Update Activity'),
                ),
                const Divider(),
              ],
            )),
        if (residentActivities.isEmpty)
          const Text('No activities data available for this resident.'),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(3, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            detail,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
