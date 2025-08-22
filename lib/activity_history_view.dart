import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActivityHistoryView extends StatefulWidget {
  final String residentId;

  const ActivityHistoryView({
    super.key,
    required this.residentId,
  });

  @override
  State<ActivityHistoryView> createState() => _ActivityHistoryViewState();
}

class _ActivityHistoryViewState extends State<ActivityHistoryView> {
  bool isLoading = true;
  List<Map<String, dynamic>> activityRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  DateTime? selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchActivityHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivityHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/activities/resident/${widget.residentId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          activityRecords = data
              .map((record) => {
                    'id': record['_id'],
                    'activity name': record['name'],
                    'date': record['date'],
                    'description': record['description'],
                    'status': record['status'],
                    'duration': record['duration']?.toString(),
                    'location': record['location'],
                    'notes': record['notes'],
                    'createdAt': record['createdAt'],
                  })
              .toList();
          filteredRecords = List.from(activityRecords);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load activity history');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching activity history: $e');
      }
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRecords(String searchText) {
    setState(() {
      if (searchText.isEmpty && selectedDate == null) {
        filteredRecords = List.from(activityRecords);
      } else {
        filteredRecords = activityRecords.where((record) {
          bool matchesSearch = true;
          bool matchesDate = true;

          if (searchText.isNotEmpty) {
            final searchLower = searchText.toLowerCase();
            matchesSearch = record['activity name']
                    .toString()
                    .toLowerCase()
                    .contains(searchLower) ||
                record['date'].toString().toLowerCase().contains(searchLower);
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
      filteredRecords = List.from(activityRecords);
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  Color _getStatusBgColor(String status) {
    switch (status) {
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

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getStatusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
          'Activity History',
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
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by activity name or date',
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(selectedDate == null
                                  ? 'Select Date'
                                  : _formatDate(
                                      selectedDate!.toIso8601String())),
                              onPressed: () => _selectDate(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: Colors.blue[700],
                                side: BorderSide.none,
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? Center(
                          child: Text(
                            'No activity records found',
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
                              _buildActivityCard(filteredRecords[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        // Changed to ExpansionTile
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                record['activity name'] == 'Physical Therapy'
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
                    record['activity name'] ?? 'Unknown Activity',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(record['date']),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(record['status'] ?? 'Scheduled'),
          ],
        ),
        children: [
          // Content when expanded
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Location:', record['location']),
                _buildInfoRow('Duration:', '${record['duration']} minutes'),
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
                  record['description'] ?? 'No description available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (record['notes'] != null && record['notes'].isNotEmpty) ...[
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
                    record['notes'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
}
