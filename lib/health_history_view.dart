import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HealthHistoryView extends StatefulWidget {
  final String residentId;

  const HealthHistoryView({
    super.key,
    required this.residentId,
  });

  @override
  State<HealthHistoryView> createState() => _HealthHistoryViewState();
}

class _HealthHistoryViewState extends State<HealthHistoryView> {
  bool isLoading = true;
  List<Map<String, dynamic>> healthRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  DateTime? selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHealthHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHealthHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/healthplans/history/${widget.residentId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          healthRecords = data
              .map((record) => {
                    'id': record['_id'],
                    'date': record['date'],
                    'status': record['status'],
                    'allergies': record['allergies'] ?? [],
                    'medicalCondition': record['medicalCondition'] ?? [],
                    'medications': (record['medications'] as List?)
                            ?.map((med) => {
                                  'medication': med['name'],
                                  'dosage': med['dosage'],
                                  'quantity': med['quantity'],
                                  'time': med['medicationTime'],
                                  'status': med['isMedicationTaken']
                                      ? 'Taken'
                                      : 'Not taken'
                                })
                            .toList() ??
                        [],
                    'assessment': record['assessment'],
                    'instructions': record['instructions'],
                    'createdAt': record['createdAt'],
                  })
              .toList();
          filteredRecords = List.from(healthRecords);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load health history');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching health history: $e');
      }
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading health history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRecords(String searchText) {
    setState(() {
      if (searchText.isEmpty && selectedDate == null) {
        filteredRecords = List.from(healthRecords);
      } else {
        filteredRecords = healthRecords.where((record) {
          bool matchesSearch = true;
          bool matchesDate = true;

          if (searchText.isNotEmpty) {
            matchesSearch = record['date']
                .toString()
                .toLowerCase()
                .contains(searchText.toLowerCase());
          }

          if (selectedDate != null) {
            final recordDate = DateTime.parse(record['date']);
            matchesDate = recordDate.year == selectedDate!.year &&
                recordDate.month == selectedDate!.month &&
                recordDate.day == selectedDate!.day;
          }

          return matchesSearch && matchesDate;
        }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _filterRecords(_searchController.text);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedDate = null;
      _searchController.clear();
      filteredRecords = List.from(healthRecords);
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMedicationTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'Not specified';

    try {
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) return timeString;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : hour;
      hour = hour == 0 ? 12 : hour;

      return '${hour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
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
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by date (YYYY/MM/DD)',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty ||
                                  selectedDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearFilters,
                                )
                              : null,
                        ),
                        onChanged: _filterRecords,
                      ),
                      const SizedBox(height: 8),
                      // Date Picker Button
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(selectedDate == null
                                ? 'Select Date'
                                : _formatDate(selectedDate!.toIso8601String())),
                            onPressed: () => _selectDate(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: Colors.blue[700],
                              side: BorderSide
                                  .none, // Add this line to remove the border
                              backgroundColor: Colors.grey[
                                  100], // Optional: adds a light background
                              shape: RoundedRectangleBorder(
                                // Optional: adds rounded corners
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? Center(
                          child: Text(
                            'No health records found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) =>
                              _buildHealthRecordCard(filteredRecords[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHealthRecordCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Icon(
              Icons.event_note,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Record - ${_formatDate(record['date'])}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Status: ${record['status']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: record['status'] == 'Critical'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Medical Information', [
                  _buildAllergiesSection(record['allergies']),
                  _buildMedicalConditionsSection(record['medicalCondition']),
                ]),
                const SizedBox(height: 16),
                _buildSection('Medication Details', [
                  ...record['medications']
                      .map<Widget>((medication) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                  'Medication:', medication['medication']),
                              _buildInfoRow('Dosage:', medication['dosage']),
                              _buildInfoRow(
                                  'Quantity:', medication['quantity']),
                              _buildInfoRow('Time:',
                                  _formatMedicationTime(medication['time'])),
                              _buildInfoRow('Status:', medication['status']),
                              const Divider(),
                            ],
                          ))
                      .toList(),
                ]),
                const SizedBox(height: 16),
                _buildSection('Assessment & Instructions', [
                  _buildInfoRow('Assessment:', record['assessment']),
                  _buildInfoRow('Instructions:', record['instructions']),
                ]),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Created: ${_formatDate(record['createdAt'])}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesSection(List<dynamic> allergies) {
    return allergies.isEmpty
        ? _buildInfoRow('Allergies:', 'None')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allergies:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergies
                    .map((allergy) => Chip(
                          label: Text(
                            allergy,
                            style: GoogleFonts.poppins(color: Colors.red[700]),
                          ),
                          backgroundColor: Colors.red[50],
                        ))
                    .toList(),
              ),
            ],
          );
  }

  Widget _buildMedicalConditionsSection(List<dynamic> conditions) {
    return conditions.isEmpty
        ? _buildInfoRow('Medical Conditions:', 'None')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical Conditions:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conditions
                    .map((condition) => Chip(
                          label: Text(
                            condition,
                            style: GoogleFonts.poppins(color: Colors.red[700]),
                          ),
                          backgroundColor: Colors.red[50],
                        ))
                    .toList(),
              ),
            ],
          );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
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
              value?.toString() ?? 'Not specified',
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
}
