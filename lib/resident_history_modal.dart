import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'residents_details.dart';

class ResidentHistoryModal extends StatefulWidget {
  final String userRole;

  const ResidentHistoryModal({
    super.key,
    required this.userRole,
  });

  @override
  State<ResidentHistoryModal> createState() => _ResidentHistoryModalState();
}

class _ResidentHistoryModalState extends State<ResidentHistoryModal> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  String _filterBy = 'all';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _residents = [];

  @override
  void initState() {
    super.initState();
    _fetchResidents();
  }

  Future<void> _fetchResidents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/residents/search'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> processedResidents =
            data.map((resident) {
          return {
            'id': resident['_id'],
            'fullName': resident['fullName'] ?? 'Unknown',
            'dateOfBirth': _formatDate(resident['dateOfBirth']),
            'gender': resident['gender'] ?? 'Not specified',
            'status': resident['status'] ?? 'active',
            'contactNumber': resident['contactNumber'] ?? 'No contact',
            'address': resident['address'] ?? 'No address',
            'createdAt': DateTime.parse(
                resident['createdAt'] ?? DateTime.now().toIso8601String()),
            'emergencyContact': {
              'name': resident['emergencyContact']?['name'] ?? 'Not provided',
              'phone': resident['emergencyContact']?['phone'] ?? 'Not provided',
              'email': resident['emergencyContact']?['email'] ?? 'Not provided',
              'relationship': resident['emergencyContact']?['relationship'] ??
                  'Not specified',
            },
          };
        }).toList();

        setState(() {
          _residents = processedResidents;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch residents');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load residents. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not provided';
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  List<Map<String, dynamic>> get filteredAndSortedResidents {
    List<Map<String, dynamic>> filtered = List.from(_residents);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((resident) {
        final name = (resident['fullName'] as String).toLowerCase();
        final address = (resident['address'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || address.contains(query);
      }).toList();
    }

    // Apply filter
    if (_filterBy != 'all') {
      filtered = filtered
          .where((resident) => resident['status'] == _filterBy)
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return _sortAscending
              ? (a['fullName'] as String).compareTo(b['fullName'] as String)
              : (b['fullName'] as String).compareTo(a['fullName'] as String);
        case 'date':
          return _sortAscending
              ? (a['createdAt'] as DateTime)
                  .compareTo(b['createdAt'] as DateTime)
              : (b['createdAt'] as DateTime)
                  .compareTo(a['createdAt'] as DateTime);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _buildResidentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchResidents,
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan[500]!,
            Colors.blue[600]!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Resident History',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search residents...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Sort dropdown with smaller flex
              Flexible(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ),
              const SizedBox(width: 8),
              // Sort direction icon
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _sortAscending = !_sortAscending),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResidentsList() {
    final residents = filteredAndSortedResidents;

    return residents.isEmpty
        ? Center(
            child: Text(
              'No residents found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: residents.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final resident = residents[index];
              Color statusColor;
              switch (resident['status']) {
                case 'active':
                  statusColor = Colors.green;
                  break;
                case 'inactive':
                  statusColor = Colors.grey;
                  break;
                case 'critical':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.blue;
              }

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResidentDetails(
                        residentId: resident['id'],
                        userRole: widget.userRole, // Pass the user role here
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Text(
                    resident['fullName'][0],
                    style: GoogleFonts.poppins(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resident['fullName'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident['address'],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          resident['dateOfBirth'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          );
  }
}
