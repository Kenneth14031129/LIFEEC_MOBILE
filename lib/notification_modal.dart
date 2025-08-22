import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red[700],
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          count.toString(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class NotificationModal extends StatefulWidget {
  final Function(int) onUnreadCountChanged;

  const NotificationModal({
    super.key,
    required this.onUnreadCountChanged,
  });

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  bool isLoading = true;
  List<Map<String, dynamic>> alerts = [];
  String? error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _filterAlertsOlderThan24Hours();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Filter alerts older than 24 hours from the UI only
  void _filterAlertsOlderThan24Hours() {
    final now = DateTime.now();
    setState(() {
      alerts = alerts.where((alert) {
        final alertTime = alert['timestamp'] as DateTime;
        final difference = now.difference(alertTime);
        return difference.inHours < 24;
      }).toList();

      // Update unread count
      final unreadCount =
          alerts.where((alert) => !(alert['read'] as bool)).length;
      widget.onUnreadCountChanged(unreadCount);
    });
  }

  Future<void> _fetchAlerts() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    // Get user info from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userRole') ?? 'nurse';
    final userEmail = prefs.getString('userEmail') ?? '';
    final userId = prefs.getString('userId') ?? '';

    // Build query parameters
    final queryString = Uri(queryParameters: {
      'userType': userType,
      'email': userEmail,
      'userId': userId,
    }).query;

    final response = await http.get(
      Uri.parse('https://lifeec-mobile-1.onrender.com/api/emergency-alerts?$queryString'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final now = DateTime.now();

      // Process all alerts from the database
      List<Map<String, dynamic>> allAlerts = data
          .map((alert) => {
                'id': alert['_id'] ?? '',
                'residentName': alert['residentName'] ?? 'Unknown Resident',
                'message': alert['message'] ?? 'Emergency alert triggered',
                'timestamp': DateTime.tryParse(alert['timestamp'] ?? '') ?? now,
                'read': alert['read'] ?? false,
                'emergencyContact': {
                  'name': alert['emergencyContact']?['name'] ?? 'Not provided',
                  'phone': alert['emergencyContact']?['phone'] ?? 'Not provided',
                  'relation': alert['emergencyContact']?['relation'] ?? 'Not specified',
                  'email': alert['emergencyContact']?['email'] ?? 'Not provided',
                },
                // Add a flag to indicate if this alert is relevant for the current user
                'isRelevant': userType == 'relative' ? 
                    (alert['emergencyContact']?['email'] == userEmail) : true,
              })
          .toList();

      setState(() {
        // Only show alerts less than 24 hours old and relevant to the user
        alerts = allAlerts.where((alert) {
          final alertTime = alert['timestamp'] as DateTime;
          final difference = now.difference(alertTime);
          return difference.inHours < 24 && alert['isRelevant'] == true;
        }).toList();

        isLoading = false;

        // Update unread count for visible and relevant alerts only
        final unreadCount = alerts
            .where((alert) => 
                !(alert['read'] as bool) && 
                alert['isRelevant'] == true)
            .length;
        widget.onUnreadCountChanged(unreadCount);
      });
    } else {
      throw Exception('Failed to load alerts');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching alerts: $e');
    }
    setState(() {
      error = 'Failed to load alerts. Please try again.';
      isLoading = false;
    });
  }
}

  Future<void> _markAsRead(String alertId) async {
    if (alertId.isEmpty) return;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/emergency-alerts/$alertId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          alerts = alerts.map((alert) {
            if (alert['id'] == alertId) {
              return {...alert, 'read': true};
            }
            return alert;
          }).toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking alert as read: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _buildAlertsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[700] ?? Colors.red,
            Colors.red[900] ?? Colors.red,
          ],
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
          const Icon(
            Icons.notifications_active,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Emergency Alerts',
            style: GoogleFonts.poppins(
              fontSize: 20,
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

  Widget _buildAlertsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error!,
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAlerts,
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      );
    }

    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No emergency alerts',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final bool isRead = alert['read'] as bool? ?? false;
    final DateTime timestamp = alert['timestamp'] as DateTime;
    final Duration timeLeft =
        timestamp.add(const Duration(hours: 24)).difference(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: isRead ? Colors.white : Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey[200]! : Colors.red[100]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => !isRead ? _markAsRead(alert['id'] as String? ?? '') : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert['residentName'] as String? ?? 'Unknown Resident',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'New',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert['message'] as String? ?? 'Emergency alert triggered',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Emergency Contact',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildContactInfo(
                'Name',
                (alert['emergencyContact'] as Map<String, dynamic>)['name']
                        as String? ??
                    'Not provided',
              ),
              _buildContactInfo(
                'Phone',
                (alert['emergencyContact'] as Map<String, dynamic>)['phone']
                        as String? ??
                    'Not provided',
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeago.format(timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    'Expires in: ${timeLeft.inHours}h ${timeLeft.inMinutes.remainder(60)}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color:
                          timeLeft.inHours < 1 ? Colors.red : Colors.grey[500],
                      fontWeight: timeLeft.inHours < 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
