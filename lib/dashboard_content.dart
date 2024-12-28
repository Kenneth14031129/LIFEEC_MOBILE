import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_alert.dart';

class DashboardContent extends StatefulWidget {
  final Function(BuildContext, Widget) navigateToPage;
  final String userType;

  const DashboardContent({
    super.key,
    required this.navigateToPage,
    required this.userType,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isLoading = false;
  String errorMessage = '';
  List<int> alertsPerMonth = List.generate(12, (_) => 0);
  Map<String, dynamic> dashboardSummary = {};
  List<Map<String, dynamic>> notifications = [];
  bool isLoadingNotifications = false;
  String notificationsErrorMessage = '';
  bool showStatsTooltip = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _initializeData() {
    if (widget.userType == 'Family Member') {
      _fetchNotifications();
    } else {
      _loadDashboardData();
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoadingNotifications = true;
      notificationsErrorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? residentId = prefs.getString('residentId');

      if (residentId == null) {
        throw Exception('Resident ID is required to fetch notifications.');
      }

      final url = Uri.parse(
          'https://lifeec-mobile-hzo4.onrender.com/api/emergency-alerts?residentId=$residentId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          notifications = data.cast<Map<String, dynamic>>();
          isLoadingNotifications = false;
        });
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      setState(() {
        notificationsErrorMessage = 'Failed to load notifications: $e';
        isLoadingNotifications = false;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchAlertsPerMonth(DateTime.now().year),
        _fetchDashboardSummary(),
      ]);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAlertsPerMonth(int year) async {
    final url = Uri.parse(
        'https://lifeec-mobile-hzo4.onrender.com/api/emergency-alerts/alerts/countByMonth?year=$year');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          alertsPerMonth = data.cast<int>();
        });
      } else {
        throw Exception('Failed to fetch alerts count');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchDashboardSummary() async {
    final url = Uri.parse(
        'https://lifeec-mobile-hzo4.onrender.com/api/emergency-alerts/dashboard/summary');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          dashboardSummary = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to fetch dashboard summary');
      }
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildNotificationList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildNotificationContent(),
      ),
    );
  }

  Widget _buildNotificationContent() {
    if (isLoadingNotifications) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificationsErrorMessage.isNotEmpty) {
      return _buildErrorState(notificationsErrorMessage);
    }

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index]);
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.red[300],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No notifications available",
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notification_important,
                    color: Colors.blue[900],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification['residentName'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification['message'] ?? 'No message provided',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTimestamp(notification['timestamp']),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'No timestamp';
    final DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userType == 'Family Member') {
      return _buildNotificationList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout();
        } else {
          return _buildTabletLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCards(),
            const SizedBox(height: 5),
            _buildChartSection(),
            const SizedBox(height: 5),
            Center(child: _buildEmergencyButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(),
                const SizedBox(height: 5),
                _buildChartSection(),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildEmergencyButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState(errorMessage);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern header with animated indicator
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 30),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 35,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Real-time monitoring and analytics',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Glass-morphism inspired stat cards
          SizedBox(
            height: 200, // Fixed height for cards
            child: Row(
              children: [
                Expanded(
                  child: _buildGlassCard(
                    icon: Icons.groups_rounded,
                    title: 'Total Residents',
                    value: '${dashboardSummary['totalResidents'] ?? 0}',
                    primaryColor: const Color(0xFF3B82F6),
                    secondaryColor: const Color(0xFF6C63FF),
                    gradientColors: const [
                      Color(0xFFEEF2FF),
                      Color(0xFFDBEAFE)
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGlassCard(
                    icon: Icons.warning_rounded,
                    title: 'Total Alerts',
                    value: '${dashboardSummary['totalAlerts'] ?? 0}',
                    primaryColor: const Color(0xFFEF4444),
                    secondaryColor: const Color(0xFFDC2626),
                    gradientColors: const [
                      Color(0xFFFEF2F2),
                      Color(0xFFFEE2E2)
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

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String value,
    required Color primaryColor,
    required Color secondaryColor,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Monthly emergency alerts overview',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        const Text('Refresh Data'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        const Text('Export Data'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 1) {
                    _loadDashboardData();
                  }
                  // Handle other menu options
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChartSample7(alertsPerMonth: alertsPerMonth),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              widget.navigateToPage(context, const EmergencyAlertPage()),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.red[300]!.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Emergency Alert',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
}

class BarChartSample7 extends StatelessWidget {
  final List<int> alertsPerMonth;

  const BarChartSample7({super.key, required this.alertsPerMonth});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        borderData: FlBorderData(
          show: true,
          border: Border.symmetric(
            horizontal: BorderSide(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
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
                final index = value.toInt();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Transform.rotate(
                      angle: -math.pi / 4,
                      child: Text(
                        months[index % months.length],
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        barGroups: _buildBarGroups(),
        maxY: alertsPerMonth.isNotEmpty
            ? (alertsPerMonth.reduce((a, b) => math.max(a, b)) + 5).toDouble()
            : 5.0,
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return alertsPerMonth.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[600]!],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();
  }
}
