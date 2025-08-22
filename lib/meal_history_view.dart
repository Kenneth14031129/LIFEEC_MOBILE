import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealHistoryView extends StatefulWidget {
  final String residentId;

  const MealHistoryView({
    super.key,
    required this.residentId,
  });

  @override
  State<MealHistoryView> createState() => _MealHistoryViewState();
}

class _MealHistoryViewState extends State<MealHistoryView> {
  bool isLoading = true;
  List<Map<String, dynamic>> mealRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  DateTime? selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMealHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMealHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/meals/resident/${widget.residentId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          mealRecords = data
              .map((record) => {
                    'id': record['_id'],
                    'date': record['date'],
                    'breakfast': List<String>.from(record['breakfast'] ?? []),
                    'lunch': List<String>.from(record['lunch'] ?? []),
                    'dinner': List<String>.from(record['dinner'] ?? []),
                    'snacks': List<String>.from(record['snacks'] ?? []),
                    'dietaryNeeds': record['dietaryNeeds'],
                    'nutritionalGoals': record['nutritionalGoals'],
                    'createdAt': record['createdAt'],
                  })
              .toList();
          filteredRecords = List.from(mealRecords);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load meal history');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching meal history: $e');
      }
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meal history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRecords(String searchText) {
    setState(() {
      if (searchText.isEmpty && selectedDate == null) {
        filteredRecords = List.from(mealRecords);
      } else {
        filteredRecords = mealRecords.where((record) {
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
      filteredRecords = List.from(mealRecords);
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
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
          'Meal History',
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
                            'No meal records found',
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
                              _buildMealRecordCard(filteredRecords[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMealRecordCard(Map<String, dynamic> record) {
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
              Icons.restaurant_menu,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Record - ${_formatDate(record['date'])}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                _buildMealSection('Breakfast', record['breakfast']),
                const Divider(),
                _buildMealSection('Lunch', record['lunch']),
                const Divider(),
                _buildMealSection('Dinner', record['dinner']),
                const Divider(),
                _buildMealSection('Snacks', record['snacks']),
                const Divider(),
                _buildSection('Dietary Requirements', [
                  _buildInfoRow('Dietary Needs:', record['dietaryNeeds']),
                  _buildInfoRow(
                      'Nutritional Goals:', record['nutritionalGoals']),
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

  Widget _buildMealSection(String title, dynamic content) {
    List<String> items = [];
    if (content is List) {
      items = List<String>.from(content);
    } else if (content != null) {
      items = [content.toString()];
    }

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
        if (items.isEmpty)
          Text(
            'Not specified',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          )
        else
          Column(
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
        const SizedBox(height: 8),
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
