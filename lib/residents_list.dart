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
      DateTime time = DateFormat.Hm().parse(timeString);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return timeString;
    }
  }

  Future<void> _fetchResidents() async {
    try {
      final response = await http.get(Uri.parse(
          'https://lifeec-mobile-hzo4.onrender.com/api/patient/list'));
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
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final response = await http.get(Uri.parse(
          'https://lifeec-mobile-hzo4.onrender.com/api/activities/list'));
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
      }
    } catch (e) {
      debugPrint('Error fetching activities: ${e.toString()}');
    }
  }

  Future<void> _fetchHealthProgress() async {
    try {
      final response = await http.get(Uri.parse(
          'https://lifeec-mobile-hzo4.onrender.com/api/health-progress/list'));
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
      }
    } catch (e) {
      debugPrint('Error fetching health progress: ${e.toString()}');
    }
  }

  Future<void> _fetchMeals() async {
    try {
      final response = await http.get(Uri.parse(
          'https://lifeec-mobile-hzo4.onrender.com/api/v1/meal/list'));
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
      }
    } catch (e) {
      debugPrint('Error fetching meals: ${e.toString()}');
    }
  }

  Future<void> updateHealthProgress(
      String id, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://lifeec-mobile-hzo4.onrender.com/api/health-progress/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _fetchHealthProgress();
      } else {
        throw Exception('Failed to update health progress');
      }
    } catch (e) {
      debugPrint('Error updating health progress: ${e.toString()}');
    }
  }

  Future<void> updateActivity(
      String id, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse('https://lifeec-mobile-hzo4.onrender.com/api/activities/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _fetchActivities();
      } else {
        throw Exception('Failed to update activity');
      }
    } catch (e) {
      debugPrint('Error updating activity: ${e.toString()}');
    }
  }

  Future<void> updateMeal(String id, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse('https://lifeec-mobile-hzo4.onrender.com/api/v1/meal/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _fetchMeals();
      } else {
        throw Exception('Failed to update meal');
      }
    } catch (e) {
      debugPrint('Error updating meal: ${e.toString()}');
    }
  }

  void _showUpdateHealthProgressDialog(dynamic healthProgress) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateHealthProgressDialog(
          healthProgress: healthProgress,
          onUpdate: updateHealthProgress,
        );
      },
    );
  }

  void _showUpdateActivityDialog(dynamic activity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateActivityDialog(
          activity: activity,
          onUpdate: updateActivity,
        );
      },
    );
  }

  void _showUpdateMealDialog(dynamic meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateMealDialog(
          meal: meal,
          onUpdate: updateMeal,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final residents = Provider.of<ResidentProvider>(context).residents;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildBody(residents),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E88E5), // Darker blue
            Color(0xFF64B5F6), // Lighter blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Residents List',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Resident> residents) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSearchDropdown(residents),
          const SizedBox(height: 20),
          if (_selectedResident != null)
            Expanded(
              child: _buildResidentDetails(_selectedResident!),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchDropdown(List<Resident> residents) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownSearch<Resident>(
        items: residents,
        selectedItem: _selectedResident,
        itemAsString: (Resident u) => u.name,
        onChanged: (value) {
          setState(() {
            _selectedResident = value;
          });
        },
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            hintText: 'Search residents...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
            ),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildResidentDetails(Resident resident) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildResidentHeader(resident),
            _buildInfoSection('Basic Information', Icons.person_outline,
                _buildBasicInformation(resident)),
            _buildInfoSection('Health Management', Icons.favorite_border,
                _buildHealthManagement(resident)),
            _buildInfoSection('Meal Management', Icons.restaurant_menu,
                _buildMealManagement(resident)),
            _buildInfoSection(
                'Activities', Icons.directions_run, _buildActivities(resident)),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentHeader(Resident resident) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              resident.name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${resident.age} years • ${resident.gender}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, Widget content) {
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

  Widget _buildBasicInformation(Resident resident) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard([
          _buildDetailRow('Contact:', resident.contact),
          _buildDetailRow(
              'Emergency Contact Name:', resident.emergencyContactName),
          _buildDetailRow(
              'Emergency Contact Phone:', resident.emergencyContactPhone),
        ]),
      ],
    );
  }

  Widget _buildHealthManagement(Resident resident) {
    List<dynamic> residentHealthProgress =
        _healthProgressData[resident.id] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...residentHealthProgress
            .map((progress) => _buildHealthProgressCard(progress))
            .toList(),
        if (residentHealthProgress.isEmpty)
          _buildEmptyState('No health records available'),
      ],
    );
  }

  Widget _buildHealthProgressCard(dynamic progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Title
          Text(
            'Health Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Basic Health Information
          _buildDetailRow('Allergies:', progress['allergy'] ?? 'N/A'),
          _buildDetailRow(
              'Medical Condition:', progress['medicalCondition'] ?? 'N/A'),
          _buildDetailRow('Date:', formatDateForDisplay(progress['date'])),
          _buildDetailRow('Status:', progress['status'] ?? 'N/A'),
          const SizedBox(height: 16),

          // Medications Section
          Text(
            'Medications',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
              'Current Medication:', progress['currentMedication'] ?? 'N/A'),
          _buildDetailRow('Dosage:', progress['dosage'] ?? 'N/A'),
          _buildDetailRow(
              'Quantity:', progress['quantity']?.toString() ?? 'N/A'),
          const SizedBox(height: 16),

          // Medication Schedule Section
          Text(
            'Medication Schedule',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Medication:', progress['medication'] ?? 'N/A'),
          _buildDetailRow('Time:', formatTime(progress['time'])),
          _buildDetailRow('Taken:', progress['taken'] == true ? 'Yes' : 'No'),
          const SizedBox(height: 16),

          // Care Plans Section
          Text(
            'Care Plans',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
              'Health Assessment:', progress['healthAssessment'] ?? 'N/A'),
          _buildDetailRow('Administration Instruction:',
              progress['administrationInstruction'] ?? 'N/A'),
          const SizedBox(height: 16),

          // Update Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showUpdateHealthProgressDialog(progress),
              icon: const Icon(Icons.edit),
              label: const Text('Update Health Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealManagement(Resident resident) {
    List<dynamic> residentMeals = _mealData[resident.id] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...residentMeals.map((meal) => _buildMealCard(meal)).toList(),
        if (residentMeals.isEmpty)
          _buildEmptyState('No meal records available'),
      ],
    );
  }

  Widget _buildMealCard(dynamic meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Date:', formatDateForDisplay(meal['date'])),
          _buildDetailRow('Dietary Needs:', meal['dietaryNeeds'] ?? 'N/A'),
          _buildDetailRow(
              'Nutritional Goals:', meal['nutritionalGoals'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSubsection('Meals', [
            _buildDetailRow('Breakfast:',
                (meal['breakfast'] as List?)?.join(', ') ?? 'N/A'),
            _buildDetailRow(
                'Lunch:', (meal['lunch'] as List?)?.join(', ') ?? 'N/A'),
            _buildDetailRow(
                'Snacks:', (meal['snacks'] as List?)?.join(', ') ?? 'N/A'),
            _buildDetailRow(
                'Dinner:', (meal['dinner'] as List?)?.join(', ') ?? 'N/A'),
          ]),
          const SizedBox(height: 12),
          // Center the button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showUpdateMealDialog(meal),
              icon: const Icon(Icons.edit),
              label: const Text('Update Meal Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities(Resident resident) {
    List<dynamic> residentActivities = _activitiesData[resident.id] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...residentActivities
            .map((activity) => _buildActivityCard(activity))
            .toList(),
        if (residentActivities.isEmpty)
          _buildEmptyState('No activities recorded'),
      ],
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Activity:', activity['activityName'] ?? 'N/A'),
          _buildDetailRow('Date:', formatDateForDisplay(activity['date'])),
          _buildDetailRow('Description:', activity['description'] ?? 'N/A'),
          const SizedBox(height: 12),
          // Center the button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showUpdateActivityDialog(activity),
              icon: const Icon(Icons.edit),
              label: const Text('Update Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              detail,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateHealthProgressDialog extends StatefulWidget {
  final dynamic healthProgress;
  final Function(String, Map<String, dynamic>) onUpdate;

  const UpdateHealthProgressDialog({
    super.key,
    required this.healthProgress,
    required this.onUpdate,
  });

  @override
  UpdateHealthProgressDialogState createState() =>
      UpdateHealthProgressDialogState();
}

class UpdateHealthProgressDialogState
    extends State<UpdateHealthProgressDialog> {
  late TextEditingController allergyController;
  late TextEditingController medicalConditionController;
  late TextEditingController dateController;
  late TextEditingController statusController;
  late TextEditingController currentMedicationController;
  late TextEditingController dosageController;
  late TextEditingController quantityController;
  late TextEditingController medicationController;
  late TextEditingController timeController;
  late TextEditingController healthAssessmentController;
  late TextEditingController administrationInstructionController;
  bool isTaken = false;

  @override
  void initState() {
    super.initState();
    allergyController =
        TextEditingController(text: widget.healthProgress['allergy']);
    medicalConditionController =
        TextEditingController(text: widget.healthProgress['medicalCondition']);
    dateController = TextEditingController(text: widget.healthProgress['date']);
    statusController =
        TextEditingController(text: widget.healthProgress['status']);
    currentMedicationController =
        TextEditingController(text: widget.healthProgress['currentMedication']);
    dosageController =
        TextEditingController(text: widget.healthProgress['dosage']);
    quantityController = TextEditingController(
        text: widget.healthProgress['quantity']?.toString() ?? '');
    medicationController =
        TextEditingController(text: widget.healthProgress['medication']);
    timeController = TextEditingController(text: widget.healthProgress['time']);
    healthAssessmentController =
        TextEditingController(text: widget.healthProgress['healthAssessment']);
    administrationInstructionController = TextEditingController(
        text: widget.healthProgress['administrationInstruction']);
    isTaken = widget.healthProgress['taken'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Health Management',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 24),

            // Basic Health Information Section
            _buildSectionTitle('Health Progress'),
            _buildTextField('Allergies', allergyController),
            _buildTextField('Medical Condition', medicalConditionController),
            _buildTextField('Date (MM/DD/YYYY)', dateController),
            _buildTextField('Status', statusController),
            const SizedBox(height: 16),

            // Medications Section
            _buildSectionTitle('Medications'),
            _buildTextField('Current Medication', currentMedicationController),
            _buildTextField('Dosage', dosageController),
            _buildTextField('Quantity', quantityController,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            // Medication Schedule Section
            _buildSectionTitle('Medication Schedule'),
            _buildTextField('Medication', medicationController),
            _buildTextField('Time (HH:MM AM/PM)', timeController),
            SwitchListTile(
              title: Text(
                'Medication Taken',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              value: isTaken,
              onChanged: (value) => setState(() => isTaken = value),
              activeColor: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),

            // Care Plans Section
            _buildSectionTitle('Care Plans'),
            _buildTextField('Health Assessment', healthAssessmentController,
                maxLines: 3),
            _buildTextField('Administration Instruction',
                administrationInstructionController,
                maxLines: 3),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onUpdate(
                      widget.healthProgress['_id'],
                      {
                        'allergy': allergyController.text,
                        'medicalCondition': medicalConditionController.text,
                        'date': dateController.text,
                        'status': statusController.text,
                        'currentMedication': currentMedicationController.text,
                        'dosage': dosageController.text,
                        'quantity': int.tryParse(quantityController.text) ?? 0,
                        'medication': medicationController.text,
                        'time': timeController.text,
                        'taken': isTaken,
                        'healthAssessment': healthAssessmentController.text,
                        'administrationInstruction':
                            administrationInstructionController.text,
                      },
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class UpdateActivityDialog extends StatefulWidget {
  final dynamic activity;
  final Function(String, Map<String, dynamic>) onUpdate;

  const UpdateActivityDialog({
    super.key,
    required this.activity,
    required this.onUpdate,
  });

  @override
  UpdateActivityDialogState createState() => UpdateActivityDialogState();
}

class UpdateActivityDialogState extends State<UpdateActivityDialog> {
  late TextEditingController activityNameController;
  late TextEditingController dateController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    activityNameController =
        TextEditingController(text: widget.activity['activityName']);
    dateController = TextEditingController(text: widget.activity['date']);
    descriptionController =
        TextEditingController(text: widget.activity['description']);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Activity',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 24),

            // Activity Details Section
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Activity Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  _buildTextField('Activity Name', activityNameController,
                      hint: 'e.g., Morning Walk, Board Games, Art Class'),
                  _buildTextField('Date (MM/DD/YYYY)', dateController,
                      hint: 'e.g., 12/24/2024'),
                  _buildTextField('Description', descriptionController,
                      maxLines: 3,
                      hint:
                          'Describe the activity details and any special requirements'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onUpdate(
                      widget.activity['_id'],
                      {
                        'activityName': activityNameController.text,
                        'date': dateController.text,
                        'description': descriptionController.text,
                      },
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Update',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class UpdateMealDialog extends StatefulWidget {
  final dynamic meal;
  final Function(String, Map<String, dynamic>) onUpdate;

  const UpdateMealDialog({
    Key? key,
    required this.meal,
    required this.onUpdate,
  }) : super(key: key);

  @override
  UpdateMealDialogState createState() => UpdateMealDialogState();
}

class UpdateMealDialogState extends State<UpdateMealDialog> {
  late TextEditingController dietaryNeedsController;
  late TextEditingController nutritionalGoalsController;
  late TextEditingController dateController;
  late TextEditingController breakfastController;
  late TextEditingController lunchController;
  late TextEditingController snacksController;
  late TextEditingController dinnerController;

  @override
  void initState() {
    super.initState();
    dietaryNeedsController =
        TextEditingController(text: widget.meal['dietaryNeeds']);
    nutritionalGoalsController =
        TextEditingController(text: widget.meal['nutritionalGoals']);
    dateController = TextEditingController(text: widget.meal['date']);
    breakfastController = TextEditingController(
        text: (widget.meal['breakfast'] as List?)?.join(', ') ?? '');
    lunchController = TextEditingController(
        text: (widget.meal['lunch'] as List?)?.join(', ') ?? '');
    snacksController = TextEditingController(
        text: (widget.meal['snacks'] as List?)?.join(', ') ?? '');
    dinnerController = TextEditingController(
        text: (widget.meal['dinner'] as List?)?.join(', ') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Meal Plan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField('Date (MM/DD/YYYY)', dateController),
            _buildTextField('Dietary Needs', dietaryNeedsController,
                maxLines: 3),
            _buildTextField('Nutritional Goals', nutritionalGoalsController,
                maxLines: 3),
            const SizedBox(height: 16),

            // Daily Meals Section
            _buildSectionTitle('Meals'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Separate multiple items with commas',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Breakfast', breakfastController,
                      hint: 'e.g., Toast, Eggs, Orange Juice'),
                  _buildTextField('Lunch', lunchController,
                      hint: 'e.g., Sandwich, Salad, Apple'),
                  _buildTextField('Snacks', snacksController,
                      hint: 'e.g., Yogurt, Nuts, Fruit'),
                  _buildTextField('Dinner', dinnerController,
                      hint: 'e.g., Chicken, Rice, Vegetables'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onUpdate(
                      widget.meal['_id'],
                      {
                        'date': dateController.text,
                        'dietaryNeeds': dietaryNeedsController.text,
                        'nutritionalGoals': nutritionalGoalsController.text,
                        'breakfast': breakfastController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        'lunch': lunchController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        'snacks': snacksController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        'dinner': dinnerController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                      },
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Update',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
