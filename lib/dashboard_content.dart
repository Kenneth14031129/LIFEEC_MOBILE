import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'emergency_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _DashboardContentState extends State<DashboardContent> {
  bool isLoading = false;
  String errorMessage = '';
  List<int> alertsPerMonth = List.generate(12, (_) => 0);
  Map<String, dynamic> dashboardSummary = {};

  List<Map<String, dynamic>> notifications = [];
  bool isLoadingNotifications = false;
  String notificationsErrorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.userType == 'Family Member') {
      _fetchNotifications();
    } else {
      _loadDashboardData();
    }
  }

  Future<void> _fetchNotifications() async {
    debugPrint('Fetching notifications from emergency alert table...');
    setState(() {
      isLoadingNotifications = true;
      notificationsErrorMessage = '';
    });

    try {
      // Fetch the residentId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? residentId = prefs.getString('residentId');

      if (residentId == null) {
        debugPrint('Resident ID not found.');
        throw Exception('Resident ID is required to fetch notifications.');
      }

      // Add residentId as a query parameter
      final url = Uri.parse('http://localhost:5000/api/emergency-alerts?residentId=$residentId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Notifications fetched: $data');
        setState(() {
          notifications = data.cast<Map<String, dynamic>>();
        });
      } else {
        debugPrint(
            'Failed to fetch notifications. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        notificationsErrorMessage = 'Failed to load notifications: $e';
      });
    } finally {
      setState(() {
        isLoadingNotifications = false;
      });
    }
  }


  Future<void> _loadDashboardData() async {
    debugPrint('Starting to load dashboard data...');
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchAlertsPerMonth(DateTime.now().year),
        _fetchDashboardSummary(),
      ]);
      debugPrint('Dashboard data loaded successfully.');
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        errorMessage = 'Failed to load data: $e';
      });
    } finally {
      debugPrint('Dashboard data load complete.');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAlertsPerMonth(int year) async {
    final url = Uri.parse(
        'http://localhost:5000/api/emergency-alerts/alerts/countByMonth?year=$year');
    debugPrint('Fetching alerts per month from $url...');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Alerts per month data: $data');
        setState(() {
          alertsPerMonth = data.cast<int>();
        });
      } else {
        debugPrint(
            'Failed to fetch alerts count. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch alerts count');
      }
    } catch (e) {
      debugPrint('Error fetching alerts per month: $e');
      rethrow;
    }
  }

  Future<void> _fetchDashboardSummary() async {
    final url = Uri.parse(
        'http://localhost:5000/api/emergency-alerts/dashboard/summary');
    debugPrint('Fetching dashboard summary from $url...');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Dashboard summary data: $data');
        setState(() {
          dashboardSummary = data;
        });
      } else {
        debugPrint(
            'Failed to fetch dashboard summary. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch dashboard summary');
      }
    } catch (e) {
      debugPrint('Error fetching dashboard summary: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userType == 'Family Member') {
      return _buildNotificationList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout(context);
        } else {
          return _buildTabletLayout(context);
        }
      },
    );
  }

  Widget _buildNotificationList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoadingNotifications
          ? const Center(child: CircularProgressIndicator())
          : notificationsErrorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    notificationsErrorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No notifications available.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['residentName'] ?? 'Unknown',
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notification['message'] ?? 'No message provided',
                                  style: GoogleFonts.lato(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    notification['timestamp'] != null
                                        ? DateTime.parse(notification['timestamp'])
                                            .toLocal()
                                            .toString()
                                        : 'No timestamp',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSummarySection(),
            const SizedBox(height: 20),
            isLoading || alertsPerMonth.every((count) => count == 0)
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : _buildStatsSection(),
            const SizedBox(height: 20),
            Center(
              child: _buildEmergencyButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSummarySection(),
                const SizedBox(height: 20),
                isLoading || alertsPerMonth.every((count) => count == 0)
                    ? const Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : _buildStatsSection(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: _buildEmergencyButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                'Dashboard Summary',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryTile(
                title: 'Total Residents',
                value: '${dashboardSummary['totalResidents'] ?? 0}',
                color: Colors.teal,
              ),
              _buildSummaryTile(
                title: 'Total Alerts',
                value: '${dashboardSummary['totalAlerts'] ?? 0}',
                color: Colors.redAccent,
              ),
              _buildSummaryTile(
                title: 'Active Residents',
                value: '${dashboardSummary['activeResidents'] ?? 0}',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: BarChartSample7(alertsPerMonth: alertsPerMonth),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.navigateToPage(context, const EmergencyAlertPage());
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 70,
          width: 250,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(2, 2),
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Emergency Alert',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AspectRatio(
        aspectRatio: 1.4,
        child: BarChart(
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
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
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
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
              drawHorizontalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            barGroups: _buildBarGroups(alertsPerMonth),
            maxY: alertsPerMonth.isNotEmpty
                ? (alertsPerMonth.reduce((a, b) => math.max(a, b)) + 5).toDouble()
                : 5.0, // Default maxY to 5 if the list is empty
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<int> alertsPerMonth) {
    return alertsPerMonth.asMap().entries.map((e) {
      final index = e.key;
      final data = e.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.toDouble(),
            color: Colors.blue,
            width: 6,
          ),
        ],
      );
    }).toList();
  }
}