import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_history_modal.dart';
import 'login_page.dart';
import 'notification_modal.dart';
import 'profile_modal.dart';
import 'resident_history_modal.dart';
import 'role_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  int totalResidents = 0;
  int totalAlerts = 0;
  int activeNurses = 0;
  double alertsResolved = 0;
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> monthlyStats = [];
  bool showNotifications = false;
  int _selectedTimeRange = 2025;
  int _selectedIndex = 0;
  String? userId;
  String userInitial = 'N';
  String userRole = 'nurse';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchData();
  }

  Future<void> _loadUserData() async {
    if (userId != null) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://lifeec-mobile-1.onrender.com/api/users/profile/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          setState(() {
            userInitial =
                userData['fullName']?.substring(0, 1).toUpperCase() ?? 'N';
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading user data: $e');
        }
      }
    }
  }

  // In _loadUserId method in DashboardScreen:
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    if (userId != null) {
      _loadUserData(); // Add this line
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch emergency alerts
      final alertsResponse = await http.get(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/emergency-alerts'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch residents count
      final residentsResponse = await http.get(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/residents/search'),
        headers: {'Content-Type': 'application/json'},
      );

      if (alertsResponse.statusCode == 200 &&
          residentsResponse.statusCode == 200) {
        final List<dynamic> alerts = json.decode(alertsResponse.body);
        final List<dynamic> residents = json.decode(residentsResponse.body);

        // Calculate alerts statistics
        final unreadAlerts =
            alerts.where((alert) => !(alert['read'] ?? false)).length;
        final totalAlertsCount = alerts.length;

        // Process monthly statistics
        final Map<String, int> monthlyAlertCounts = {};
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];

        // Process alerts for monthly statistics
        for (var alert in alerts) {
          if (alert['timestamp'] != null) {
            final date = DateTime.tryParse(alert['timestamp']);
            if (date != null) {
              final monthName = months[date.month - 1];
              monthlyAlertCounts[monthName] =
                  (monthlyAlertCounts[monthName] ?? 0) + 1;
            }
          }
        }

        // Create monthly stats list with proper sorting
        final List<Map<String, dynamic>> monthlyStatsData = months.map((month) {
          return {
            'month': month,
            'alerts': monthlyAlertCounts[month] ?? 0,
          };
        }).toList();

        // Process recent unread notifications
        final List<Map<String, dynamic>> recentNotifications =
            alerts.where((alert) => !alert['read']).take(5).map((alert) {
          return {
            'id': alert['_id'] ?? '',
            'resident': alert['residentName'] ?? 'Unknown Resident',
            'message': alert['message'] ?? 'Emergency alert triggered',
            'type': 'emergency',
            'timestamp':
                DateTime.tryParse(alert['timestamp'] ?? '') ?? DateTime.now(),
            'read': alert['read'] ?? false,
            'emergencyContact': {
              'name': alert['emergencyContact']?['name'] ?? 'Not provided',
              'phone': alert['emergencyContact']?['phone'] ?? 'Not provided',
              'relation':
                  alert['emergencyContact']?['relation'] ?? 'Not specified',
            },
          };
        }).toList();

        // Update state with all the processed data
        setState(() {
          isLoading = false;
          totalResidents = residents.length;
          totalAlerts = totalAlertsCount; // Total alerts (both read and unread)
          monthlyStats = monthlyStatsData;
          notifications = recentNotifications;

          // Calculate alerts resolved percentage
          if (totalAlertsCount > 0) {
            alertsResolved =
                ((totalAlertsCount - unreadAlerts) / totalAlertsCount) * 100;
          } else {
            alertsResolved = 0.0;
          }

          activeNurses =
              12; // This could be fetched from a separate API endpoint if available
        });
      } else {
        throw Exception('Failed to fetch dashboard data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dashboard data: $e');
      }
      setState(() {
        isLoading = false;
        // Set default values in case of error
        totalResidents = 0;
        totalAlerts = 0;
        activeNurses = 0;
        alertsResolved = 0;
        notifications = [];
        monthlyStats = List.generate(
            12,
            (index) => {
                  'month': [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec'
                  ][index],
                  'alerts': 0,
                });
      });

      // Show error message to user
      if (mounted) {
        // Check if widget is still mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load dashboard data. Please try again.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchData,
            ),
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildChartSection(),
                        if (showNotifications) ...[
                          const SizedBox(height: 24),
                          _buildNotificationsPanel(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: RoleNavigation(
        userRole: userRole, // Get this from SharedPreferences or user state
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 2,
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
                Text(
                  'LIFEEC',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: Colors.white,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => NotificationModal(
                            onUnreadCountChanged: (count) {
                              setState(() {
                                // We'll refresh all data to update both the badge and stats
                                _fetchData();
                              });
                            },
                          ),
                        );
                      },
                    ),
                    if (notifications
                        .where((n) => !n['read'])
                        .isNotEmpty) // Show badge based on unread notifications
                      Positioned(
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
                            notifications
                                .where((n) => !n['read'])
                                .length
                                .toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: InkWell(
                    onTap: () {
                      if (userId != null) {
                        showDialog(
                          context: context,
                          builder: (context) => ProfileModal(
                            userId: userId!,
                            onLogout: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();

                              // Add proper navigation
                              if (mounted) {
                                Navigator.of(context, rootNavigator: true)
                                    .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => const LoginPage()),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                          ),
                        ).then((_) {
                          // Refresh user data when profile modal is closed
                          _loadUserData();
                        });
                      } else {
                        // Show error if userId is null
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Unable to load profile. Please try logging in again.',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                    },
                    child: Text(
                      userInitial,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Here's what's happening today",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatsCard(
          'Total Residents',
          totalResidents.toString(),
          Icons.people_alt_rounded,
          Colors.cyan[500]!,
          [Colors.cyan[500]!, Colors.blue[600]!],
        ),
        _buildStatsCard(
          'Total Alerts',
          totalAlerts.toString(),
          Icons.warning_rounded,
          Colors.red[700]!,
          [Colors.red[700]!, Colors.red[500]!],
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color,
      List<Color> gradientColors) {
    return GestureDetector(
      onTap: () {
        if (title == 'Total Residents') {
          showDialog(
            context: context,
            builder: (context) => ResidentHistoryModal(
              userRole: userRole, // Pass the user role here
            ),
          );
        } else if (title == 'Total Alerts') {
          showDialog(
            context: context,
            builder: (context) => const AlertHistoryModal(),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alert Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildTimeRangeSelector(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(_createBarData()),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: 2025,
            child: Text('2025', style: GoogleFonts.poppins()),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedTimeRange = value!);
        },
      ),
    );
  }

  BarChartData _createBarData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 60,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.blueGrey,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.round()} alerts',
              GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value >= monthlyStats.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  monthlyStats[value.toInt()]['month'],
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                value.toInt().toString(),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300] ?? Colors.grey,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      barGroups: monthlyStats.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value['alerts'].toDouble(),
              gradient: LinearGradient(
                colors: [
                  Colors.cyan[500] ?? Colors.cyan,
                  Colors.blue[600] ?? Colors.blue,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNotificationsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Alerts',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    notifications =
                        notifications.map((n) => {...n, 'read': true}).toList();
                  });
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  'Mark all as read',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _buildNotificationItem(notifications[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isEmergency = notification['type'] == 'emergency';
    final color = isEmergency ? Colors.red[600]! : Colors.orange[600]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEmergency
                  ? Icons.warning_rounded
                  : Icons.notifications_active_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      notification['resident'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEmergency ? 'Emergency' : 'Warning',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'],
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification['timestamp']),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!notification['read'])
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
