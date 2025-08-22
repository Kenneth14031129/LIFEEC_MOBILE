import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'HealthUpdateModal.dart';
import 'activity_history_view.dart';
import 'activity_update_modal.dart';
import 'health_history_view.dart';
import 'meal_history_view.dart';
import 'meal_update_modal.dart';

class ResidentDetails extends StatefulWidget {
  final String residentId;
  final String userRole;

  const ResidentDetails({
    super.key,
    required this.residentId,
    required this.userRole,
  });

  @override
  State<ResidentDetails> createState() => _ResidentDetailsState();
}

class _ResidentDetailsState extends State<ResidentDetails> {
  bool isLoading = true;
  Map<String, dynamic> residentData = {};
  Map<String, dynamic> healthData = {};
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      await Future.wait([
        _fetchResidentData(),
        _fetchHealthData(),
        _fetchMealData(),
        _fetchActivityData(),
      ]);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchResidentData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/residents/${widget.residentId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          residentData = {
            'id': data['_id'],
            'name': data['fullName'] ?? 'Unknown',
            'dateOfBirth': _formatDate(data['dateOfBirth']),
            'status': data['status'] == 'critical' ? 'Critical' : 'Active',
            'location': data['address'] ?? 'No address',
            'gender': data['gender'] ?? 'Not specified',
            'phone': data['contactNumber'] ?? 'No phone',
            'emergencyContact': {
              'name': data['emergencyContact']['name'] ?? 'No name',
              'relation':
                  data['emergencyContact']['relation'] ?? 'Not specified',
              'phone': data['emergencyContact']['phone'] ?? 'No phone',
              'email': data['emergencyContact']['email'] ?? 'No email',
            },
            'nurseAssigned': data['createdBy']?['fullName'] ?? 'Not Assigned',
          };
        });
      } else {
        throw Exception('Failed to load resident data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching resident data: $e');
      }
    }
  }

  Future<void> _fetchHealthData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/healthplans/resident/${widget.residentId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          healthData = {
            'id': data['_id'],
            'allergies': List<String>.from(data['allergies'] ?? []),
            'medications': (data['medications'] as List<dynamic>?)
                    ?.map((med) => {
                          'medication': med['name'] ?? '',
                          'dosage': med['dosage'] ?? '',
                          'quantity': med['quantity'] ?? '',
                          'time': med['medicationTime'] ?? '',
                          'status':
                              med['isMedicationTaken'] ? 'Taken' : 'Not taken'
                        })
                    .toList() ??
                [],
            'conditions': List<String>.from(data['medicalCondition'] ?? []),
            'assessment': data['assessment'] ?? 'No assessment available',
            'instructions': data['instructions'] ?? 'No special instructions',
            'status': data['status'] ?? 'Stable',
            'date': data['date'] ?? 'Not specified',
          };
        });
      } else {
        throw Exception('Failed to load health data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching health data: $e');
      }
      setState(() {
        healthData = {
          'allergies': <String>[],
          'medications': <Map<String, dynamic>>[],
          'conditions': <String>[],
          'assessment': 'No assessment available',
          'instructions': 'No special instructions',
          'status': 'Stable',
          'date': 'Not specified',
        };
      });
    }
  }

  Future<void> _updateHealthPlan(Map<String, dynamic> updatedData) async {
    try {
      if (healthData['id'] == null) {
        throw Exception('Health plan ID not found');
      }

      // Create the request body with proper array handling
      final requestBody = {
        'date': DateTime.now().toIso8601String().split('T')[0],
        'status': updatedData['status'] ?? 'Stable',
        'allergies': updatedData['allergies'] ?? [],
        'medicalCondition': updatedData['conditions'] ?? [],
        'medications': updatedData['medications']
                ?.map((med) => {
                      'name': med['name'],
                      'dosage': med['dosage'],
                      'quantity': med['quantity'],
                      'medicationTime': med['medicationTime'] is List
                          ? med['medicationTime'][0]
                          : med['medicationTime'], // Ensure it's a string
                      'isMedicationTaken': med['isMedicationTaken']
                    })
                .toList() ??
            [],
        'assessment': updatedData['assessmentNotes'] ?? '',
        'instructions': updatedData['specialInstructions'] ?? ''
      };

      if (kDebugMode) {
        print('Updating health plan with data: $requestBody');
      }

      final response = await http.put(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/healthplans/${healthData['id']}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Server response: ${response.body}');
        }
        throw Exception('Failed to update health plan: ${response.statusCode}');
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health plan updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the health data
        await _fetchHealthData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating health plan: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update health plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Update the _fetchMealData method
  Future<void> _fetchMealData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/meals/resident/${widget.residentId}/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final meal = json.decode(response.body);
        setState(() {
          meals = [
            {
              'id': meal['_id'],
              'date': meal['date'] ?? 'Not specified',
              'breakfast': List<String>.from(meal['breakfast'] ?? []),
              'lunch': List<String>.from(meal['lunch'] ?? []),
              'snacks': List<String>.from(meal['snacks'] ?? []),
              'dinner': List<String>.from(meal['dinner'] ?? []),
              'dietary needs': meal['dietaryNeeds'] ?? 'None specified',
              'nutritional goals': meal['nutritionalGoals'] ?? 'None specified',
              'completed': false
            }
          ];
        });
      } else if (response.statusCode == 404) {
        setState(() {
          meals = [];
        });
      } else {
        throw Exception('Failed to load meal data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching meal data: $e');
      }
      setState(() {
        meals = [];
      });
    }
  }

  Future<void> _updateMealPlan(Map<String, dynamic> updatedData) async {
    try {
      if (meals.isEmpty || meals[0]['id'] == null) {
        throw Exception('No meal record ID found to update');
      }

      // Create request body with array handling
      final requestBody = {
        'date': updatedData['date'],
        'breakfast': List<String>.from(updatedData['breakfast'] ?? []),
        'lunch': List<String>.from(updatedData['lunch'] ?? []),
        'dinner': List<String>.from(updatedData['dinner'] ?? []),
        'snacks': List<String>.from(updatedData['snacks'] ?? []),
        'dietaryNeeds': updatedData['dietary needs'],
        'nutritionalGoals': updatedData['nutritional goals']
      };

      if (kDebugMode) {
        print('Updating meal plan with data: $requestBody');
      }

      final response = await http.put(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/meals/${meals[0]['id']}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal plan updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the meal data
          await _fetchMealData();
        }
      } else {
        if (kDebugMode) {
          print('Server response: ${response.body}');
        }
        throw Exception('Failed to update meal plan: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating meal plan: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update meal plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Update the _fetchActivityData method
  Future<void> _fetchActivityData() async {
    try {
      // Change the endpoint to get the latest activity record
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/activities/resident/${widget.residentId}/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final activity =
            json.decode(response.body); // Now it's a single object, not a list
        setState(() {
          activities = [
            // Wrap single activity in a list since UI expects a list
            {
              'id': activity['_id'],
              'activity name': activity['name'],
              'date': activity['date'] ?? 'Not specified',
              'description':
                  activity['description'] ?? 'No description available',
              'status':
                  activity['status'] ?? 'Scheduled', // Default to Scheduled
              'duration': activity['duration']?.toString() ?? 'Not specified',
              'location': activity['location'] ?? 'Not specified',
              'notes': activity['notes'] ?? '',
            }
          ];
        });
      } else if (response.statusCode == 404) {
        // Handle case when no activities exist
        setState(() {
          activities = [];
        });
      } else {
        throw Exception('Failed to load activity data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching activity data: $e');
      }
      setState(() {
        activities = [];
      });
    }
  }

  Future<void> _updateActivityPlan(Map<String, dynamic> updatedData) async {
    try {
      if (activities.isEmpty || activities[0]['id'] == null) {
        throw Exception('No activity record ID found to update');
      }

      final response = await http.put(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/activities/${activities[0]['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': updatedData['activity name'],
          'date': updatedData['date'],
          'description': updatedData['description'],
          'status': updatedData['status'], // Default status for update
          'duration': int.tryParse(updatedData['duration'].toString()) ?? 0,
          'location': updatedData['location'],
          'notes': updatedData['notes']
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity plan updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the activity data
          await _fetchActivityData();
        }
      } else {
        throw Exception(
            'Failed to update activity plan: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating activity plan: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update activity plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTimeToStandard(String? militaryTime) {
    if (militaryTime == null || militaryTime.isEmpty) {
      return 'Not specified';
    }

    try {
      // Handle different time formats
      DateTime dateTime;
      if (militaryTime.contains(':')) {
        final parts = militaryTime.split(':');
        final hour = int.parse(parts[0]);
        final minute =
            int.parse(parts[1].split(' ')[0]); // Remove AM/PM if present
        dateTime = DateTime(2024, 1, 1, hour, minute);
      } else {
        final hour = int.parse(militaryTime);
        dateTime = DateTime(2024, 1, 1, hour, 0);
      }

      // Format to 12-hour time
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final hourString = hour == 0 ? '12' : hour.toString();
      final minuteString = dateTime.minute.toString().padLeft(2, '0');

      return '$hourString:$minuteString $period';
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting time: $e');
      }
      return militaryTime; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildExpandableSections(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 2,
      leading: null,
      automaticallyImplyLeading: false,
      expandedHeight: 70,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan[500] ?? Colors.cyan,
                Colors.blue[600] ?? Colors.blue,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Resident Details',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Get status from healthData instead of residentData
    final status = healthData['status'] ?? 'Stable';
    final isCritical = status == 'Critical';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan[500] ?? Colors.cyan,
            Colors.blue[600] ?? Colors.blue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[700]!.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              residentData['name']?.toString()[0] ?? 'U',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  residentData['name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      residentData['location'] ?? 'No location',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isCritical
                  ? Colors.red[700]!.withOpacity(0.2)
                  : Colors.green[700]!.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCritical
                    ? Colors.red[700]!.withOpacity(0.6)
                    : Colors.green[700]!.withOpacity(0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 4),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSections() {
    return Column(
      children: [
        _buildExpandableSection(
          'Personal Information',
          Icons.person_outline,
          _buildPersonalInformation(),
          0,
        ),
        _buildExpandableSection(
          'Health Plan',
          Icons.favorite_outline,
          _buildHealth(),
          1,
        ),
        _buildExpandableSection(
          'Meal Plan',
          Icons.restaurant_outlined,
          _buildMeals(),
          2,
        ),
        _buildExpandableSection(
          'Activity Plan',
          Icons.directions_run_outlined,
          _buildActivities(),
          3,
        ),
      ],
    );
  }

  Widget _buildExpandableSection(
      String title, IconData icon, Widget content, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.blue.shade600),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [content],
        ),
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('DOB:', residentData['dateOfBirth'] ?? 'Not specified'),
        _buildInfoRow('Gender:', residentData['gender'] ?? 'Not specified'),
        _buildInfoRow('Phone:', residentData['phone'] ?? 'Not specified'),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Emergency Contact',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Name:',
          residentData['emergencyContact']?['name'] ?? 'Not specified',
        ),
        _buildInfoRow(
          'Relation:',
          residentData['emergencyContact']?['relation'] ?? 'Not specified',
        ),
        _buildInfoRow(
          'Phone:',
          residentData['emergencyContact']?['phone'] ?? 'Not specified',
        ),
        _buildInfoRow(
          'Email:',
          residentData['emergencyContact']?['email'] ?? 'Not specified',
        ),
      ],
    );
  }

  Widget _buildHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConditionsAndAllergies(),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildMedications(),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildHealthAssessment(),
        const SizedBox(height: 24),
        Row(
          children: [
            if (widget.userRole.toLowerCase() == 'nurse') // Add this condition
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: _buildGradientButton(
                    'Update Health Plan',
                    () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => HealthUpdateModal(
                          currentHealthData: healthData,
                        ),
                      );

                      if (result != null) {
                        await _updateHealthPlan(result);
                        await _fetchHealthData();
                      }
                    },
                  ),
                ),
              ),
            if (widget.userRole.toLowerCase() == 'nurse') // Add this condition
              const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: _buildGradientButton(
                  'View Health History',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HealthHistoryView(
                          residentId: widget.residentId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildConditionsAndAllergies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Allergies Section
        Text(
          'Allergies',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (healthData['allergies'] as List<String>).isEmpty
              ? [
                  Chip(
                    label: Text(
                      'No Allergies',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    backgroundColor: Colors.grey[100],
                  )
                ]
              : (healthData['allergies'] as List<String>).map((allergy) {
                  return Chip(
                    label: Text(
                      allergy,
                      style: GoogleFonts.poppins(color: Colors.red[700]),
                    ),
                    backgroundColor: Colors.red[50],
                  );
                }).toList(),
        ),

        const SizedBox(height: 16),

        // Medical Conditions Section
        Text(
          'Medical Conditions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (healthData['conditions'] as List<String>).isEmpty
              ? [
                  Chip(
                    label: Text(
                      'No Medical Conditions',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    backgroundColor: Colors.grey[100],
                  )
                ]
              : (healthData['conditions'] as List<String>).map((condition) {
                  return Chip(
                    label: Text(
                      condition,
                      style: GoogleFonts.poppins(color: Colors.red[700]),
                    ),
                    backgroundColor: Colors.red[50],
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildMedications() {
    // Properly cast the medications data
    final List<Map<String, dynamic>> medications =
        (healthData['medications'] as List<dynamic>?)
                ?.map((med) => med as Map<String, dynamic>)
                .toList() ??
            [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication Details',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        Text(
          healthData['date'] ?? 'Not specified',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        if (medications.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.medication_outlined,
                      color: Colors.grey[400], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'No medications prescribed',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...medications.map((medication) {
            final isTaken = medication['status'] == 'Taken';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isTaken ? Colors.green.shade200 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.transparent,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.medication,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medication['medication'] ??
                                      'Unknown Medication',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                Text(
                                  '${medication['dosage']} • ${medication['quantity']} unit(s)',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isTaken
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              medication['status'] ?? 'Not taken',
                              style: GoogleFonts.poppins(
                                color: isTaken
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Schedule',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeToStandard(
                                      medication['time'].toString()),
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHealthAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Assessment',
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
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Assessment Notes Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assessment_outlined,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assessment Notes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            healthData['assessment'] ??
                                'No specific notes at this time.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Special Instructions Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Instructions',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            healthData['instructions'] ??
                                'No special instructions at this time.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meals.isEmpty)
          Center(
            child: Text(
              'No meal plans available',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              return _buildMealCard(meals[index]);
            },
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                'Update Meal Plan',
                () async {
                  final currentMeal =
                      meals.isNotEmpty ? meals[0] : <String, dynamic>{};
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => MealUpdateModal(
                      currentMealData: currentMeal,
                    ),
                  );

                  if (result != null) {
                    await _updateMealPlan(result);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGradientButton(
                'View Meal History',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MealHistoryView(
                        residentId: widget.residentId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  meal['date'] ?? 'No date',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Meal Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildMealTime('Breakfast:', meal['breakfast']),
            _buildMealTime('Lunch:', meal['lunch']),
            _buildMealTime('Snacks:', meal['snacks']),
            _buildMealTime('Dinner:', meal['dinner']),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Dietary Needs:', meal['dietary needs']),
            _buildInfoRow('Nutritional Goals:', meal['nutritional goals']),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTime(String time, dynamic mealItems) {
    List<String> items = [];
    if (mealItems is List) {
      items = List<String>.from(mealItems);
    } else if (mealItems != null) {
      items = [mealItems.toString()];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Text(
                    'Not specified',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activities.isEmpty)
          Center(
            child: Text(
              'No activities scheduled',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(activities[index]);
            },
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (widget.userRole.toLowerCase() == 'nurse') // Add this condition
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: _buildGradientButton(
                    'Update Activity Plan',
                    () async {
                      final currentActivity = activities.isNotEmpty
                          ? activities[0]
                          : <String, dynamic>{};
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => ActivityUpdateModal(
                          currentActivityData: currentActivity,
                        ),
                      );

                      if (result != null) {
                        await _updateActivityPlan(result);
                      }
                    },
                  ),
                ),
              ),
            if (widget.userRole.toLowerCase() == 'nurse') // Add this condition
              const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: _buildGradientButton(
                  'View Activity History',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityHistoryView(
                          residentId: widget.residentId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity['activity name'] == 'Physical Therapy'
                        ? Icons.fitness_center
                        : Icons.groups,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['activity name'] ?? 'Unknown Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        activity['date'] ?? 'No date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(activity['status']),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Location:', activity['location']),
            _buildInfoRow('Duration:', activity['duration']),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activity['description'] ?? 'No description available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (activity['notes'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Notes:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity['notes'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(dynamic status) {
    // If status is a boolean, handle the old way
    if (status is bool) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: status ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status ? 'Completed' : 'Scheduled',
          style: GoogleFonts.poppins(
            color: status ? Colors.green[700] : Colors.orange[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Handle status string
    Color getStatusColor(String statusValue) {
      switch (statusValue) {
        case 'Completed':
          return Colors.green[700]!;
        case 'In Progress':
          return Colors.orange[700]!;
        case 'Cancelled':
          return Colors.red[700]!;
        case 'Scheduled':
        default:
          return Colors.blue[700]!;
      }
    }

    Color getStatusBgColor(String statusValue) {
      switch (statusValue) {
        case 'Completed':
          return Colors.green[50]!;
        case 'In Progress':
          return Colors.orange[50]!;
        case 'Cancelled':
          return Colors.red[50]!;
        case 'Scheduled':
        default:
          return Colors.blue[50]!;
      }
    }

    String statusValue = (status as String?) ?? 'Scheduled';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: getStatusBgColor(statusValue),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusValue,
        style: GoogleFonts.poppins(
          color: getStatusColor(statusValue),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
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
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
