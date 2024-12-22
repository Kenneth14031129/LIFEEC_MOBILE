import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'residents_list.dart';
import 'login_register.dart';
import 'messages_page.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_content.dart';

class EmergencyAlert {
  final String residentId;
  final String residentName;
  final String message;
  final DateTime timestamp;

  EmergencyAlert({
    required this.residentId,
    required this.residentName,
    required this.message,
    required this.timestamp,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      residentId: json['residentId'],
      residentName: json['residentName'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class NurseDashboardApp extends StatelessWidget {
  final String userType;

  const NurseDashboardApp({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nurse Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.lightBlueAccent,
          primary: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        textTheme: GoogleFonts.playfairDisplayTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
        ),
      ),
      home: NurseDashboard(userType: userType),
    );
  }
}

class NurseDashboard extends StatefulWidget {
  final String userType;

  const NurseDashboard({super.key, required this.userType});

  @override
  NurseDashboardState createState() => NurseDashboardState();
}

class NurseDashboardState extends State<NurseDashboard> {
  String userEmail = '';
  List<EmergencyAlert> alerts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _fetchEmergencyAlerts();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email') ?? 'No email found';
    });
  }

  Future<void> _fetchEmergencyAlerts() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:5000/api/emergency-alerts/all'), // New endpoint
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            alerts = data
                .map((alert) => EmergencyAlert.fromJson(alert))
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching alerts: $e');
    }
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

// Add this helper function to calculate time ago
  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years years ago';
    }
  }

// Replace the existing _showNotificationDialog method with this updated version
  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Alerts',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchEmergencyAlerts,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : alerts.isEmpty
                    ? const Center(
                        child: Text('No emergency alerts'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Emergency alert triggered for ${alert.residentName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32.0),
                                  child: Text(
                                    getTimeAgo(alert.timestamp),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (index < alerts.length - 1)
                                  const Divider(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // Reduced from 80.0
        child: AppBar(
          title: Center(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0), // Reduced from 10.0
                child: Text(
                  'LIFEEC',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications,
                      color: Colors.white, size: 24),
                  onPressed: () => _showNotificationDialog(context),
                ),
                if (alerts.isNotEmpty)
                  Positioned(
                    right: 6, // Adjusted from 8
                    top: 6, // Adjusted from 8
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${alerts.length}',
                        style: const TextStyle(
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
            Tooltip(
              message: 'Search',
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ],
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 30, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.userType} Dashboard',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userEmail,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.userType == 'Nurse') ...[
              _buildDrawerItem(FontAwesomeIcons.userGroup, 'Residents List',
                  onTap: () {
                _navigateToPage(
                    context,
                    const ResidentsListPage(
                      residents: [],
                    ));
              }),
              _buildDrawerItem(Icons.message, 'Messages', onTap: () {
                _navigateToPage(context, const MessagesPage(userType: 'Nurse'));
              }),
              _buildDrawerItem(Icons.settings, 'Settings', onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }),
              _buildDrawerItem(Icons.logout, 'Logout', onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              }),
            ] else if (widget.userType == 'Family Member' ||
                widget.userType == 'Nutritionist') ...[
              _buildDrawerItem(Icons.message, 'Messages', onTap: () {
                _navigateToPage(
                    context, MessagesPage(userType: widget.userType));
              }),
              _buildDrawerItem(Icons.settings, 'Settings', onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }),
              _buildDrawerItem(Icons.logout, 'Logout', onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              }),
            ] else ...[
              _buildDrawerItem(Icons.error, 'Unknown Role', onTap: () {
                // Optionally log out or show an alert
              }),
            ],
          ],
        ),
      ),
      body: DashboardContent(
        navigateToPage: _navigateToPage,
        userType: widget.userType,
      ),
    );
  }

  static Widget _buildDrawerItem(IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800)),
      onTap: onTap,
    );
  }
}

class _IconWidget extends ImplicitlyAnimatedWidget {
  const _IconWidget({
    required this.color,
    required this.isSelected,
  }) : super(duration: const Duration(milliseconds: 300));

  final Color color;
  final bool isSelected;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _IconWidgetState();
}

class _IconWidgetState extends AnimatedWidgetBaseState<_IconWidget> {
  Tween<double>? _rotationTween;

  @override
  Widget build(BuildContext context) {
    final rotation = math.pi * 4 * _rotationTween!.evaluate(animation);
    final scale = 1 + _rotationTween!.evaluate(animation) * 0.5;
    return Transform(
      transform: Matrix4.rotationZ(rotation).scaled(scale, scale),
      origin: const Offset(14, 14),
      child: Icon(
        widget.isSelected ? Icons.face_retouching_natural : Icons.face,
        color: widget.color,
        size: 28,
      ),
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _rotationTween = visitor(
      _rotationTween,
      widget.isSelected ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(
        begin: value as double,
        end: widget.isSelected ? 1.0 : 0.0,
      ),
    ) as Tween<double>?;
  }
}
