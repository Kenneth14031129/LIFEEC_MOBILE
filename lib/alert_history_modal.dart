import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AlertHistoryModal extends StatefulWidget {
  const AlertHistoryModal({
    super.key,
  });

  @override
  State<AlertHistoryModal> createState() => _AlertHistoryModalState();
}

class _AlertHistoryModalState extends State<AlertHistoryModal> {
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  String _filterBy = 'all';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/emergency-alerts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> processedAlerts = data.map((alert) {
          final Map<String, dynamic> processed = {
            '_id': alert['_id'] as String,
            'residentName': alert['residentName'] as String,
            'message': alert['message'] as String,
            'read': alert['read'] as bool? ?? false,
            'timestamp': DateTime.parse(alert['timestamp'] as String),
          };
          return processed;
        }).toList();

        setState(() {
          _alerts = processedAlerts;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch alerts');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load alerts. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String alertId) async {
    if (!mounted) return;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/emergency-alerts/$alertId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _alerts = _alerts.map((alert) {
            if (alert['_id'] == alertId) {
              return {...alert, 'read': true};
            }
            return alert;
          }).toList();
        });
      } else {
        throw Exception('Failed to mark alert as read');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to mark alert as read',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredAndSortedAlerts {
    List<Map<String, dynamic>> filtered = List.from(_alerts);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((alert) {
        final name = (alert['residentName'] as String).toLowerCase();
        final message = (alert['message'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    // Apply filter
    if (_filterBy != 'all') {
      filtered = filtered.where((alert) {
        return _filterBy == 'read'
            ? alert['read'] as bool
            : !(alert['read'] as bool);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date':
          return _sortAscending
              ? (a['timestamp'] as DateTime)
                  .compareTo(b['timestamp'] as DateTime)
              : (b['timestamp'] as DateTime)
                  .compareTo(a['timestamp'] as DateTime);
        case 'resident':
          return _sortAscending
              ? (a['residentName'] as String)
                  .compareTo(b['residentName'] as String)
              : (b['residentName'] as String)
                  .compareTo(a['residentName'] as String);
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
                      : _buildAlertsList(),
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
            onPressed: _fetchAlerts,
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
            'Alert History',
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
              hintText: 'Search alerts...',
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(
                        value: 'resident', child: Text('Resident')),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () =>
                    setState(() => _sortAscending = !_sortAscending),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    final alerts = filteredAndSortedAlerts;

    return alerts.isEmpty
        ? Center(
            child: Text(
              'No alerts found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              const color = Colors.red;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: color,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert['residentName'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!(alert['read'] as bool))
                      TextButton(
                        onPressed: () => _markAsRead(alert['_id'] as String),
                        child: Text(
                          'Mark as read',
                          style: GoogleFonts.poppins(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['message'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm')
                          .format(alert['timestamp'] as DateTime),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                trailing: !(alert['read'] as bool)
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          );
  }
}
