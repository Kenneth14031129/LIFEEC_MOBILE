import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'family_chat.dart';
import 'login_register.dart';
import 'settings_page.dart';

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

class MessagesPage extends StatefulWidget {
  final String userType;

  const MessagesPage({super.key, required this.userType});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<EmergencyAlert> alerts = [];
  bool _isLoading = true;
  String? userType;
  String userEmail = '';
  Map<String, int> unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _loadUserEmail();
    _fetchEmergencyAlerts();
    _fetchUnreadCounts();
  }

  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> _fetchUnreadCounts() async {
    String? currentUserId = await getCurrentUserId();
    print('\n=== Fetching Unread Counts ===');
    print('Current User ID: $currentUserId');

    if (currentUserId == null) {
      print('❌ No current user ID found');
      return;
    }

    try {
      print('Making API request to fetch unread counts...');
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/messages/unread/$currentUserId'),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Decoded unread counts: ${data['unreadCounts']}');

        if (mounted) {
          setState(() {
            unreadCounts = Map<String, int>.from(data['unreadCounts']);
          });
          print('Updated state with new unread counts: $unreadCounts');
        } else {
          print('⚠️ Widget not mounted, skipped setState');
        }
      } else {
        print('❌ Failed to fetch unread counts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching unread counts: $e');
    }
  }

  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    print('\n=== Marking Messages as Read ===');
    print('Sender ID: $senderId');
    print('Receiver ID: $receiverId');

    try {
      print('Making API request to mark messages as read...');
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/messages/mark-read'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Successfully marked messages as read');
        _fetchUnreadCounts(); // Refresh unread counts
      } else {
        print('❌ Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
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
        _isLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/emergency-alerts/all'),
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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error fetching alerts: $e');
    }
  }

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
            child: _isLoading
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

  void _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType') ?? widget.userType;
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (userType == null) return;

    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/api/users?userType=$userType'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        List<Map<String, dynamic>> users = jsonResponse.map((user) {
          return {
            '_id': user['_id'],
            'name': user['name'],
          };
        }).toList();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('cachedUsers', json.encode(users));

        setState(() {
          _users = users;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      print('Error fetching users: $error');
      _loadCachedUsers();
    }
  }

  void _loadCachedUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedUsers = prefs.getString('cachedUsers');
    if (cachedUsers != null) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(json.decode(cachedUsers));
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {});
    await prefs.setString('lastSearchQuery', query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: userType != 'Nurse' ? _buildDrawer() : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: userType == 'Nurse'
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
            title: Text(
              'Messages',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: userType == 'Family Member'
                ? [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _showNotificationDialog(context),
                        ),
                        if (alerts.isNotEmpty)
                          Positioned(
                            right: 6,
                            top: 6,
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
                  ]
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40.0),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.blueAccent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: _buildUserList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer() {
    String dashboardTitle = '';
    if (userType == 'Nutritionist') {
      dashboardTitle = 'Nutritionist Dashboard';
    } else if (userType == 'Family Member') {
      dashboardTitle = 'Relative Dashboard';
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
                  child: Icon(Icons.person, color: Colors.blueAccent, size: 35),
                ),
                const SizedBox(height: 10),
                Text(
                  dashboardTitle,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          _buildDrawerItem(Icons.settings, 'Settings', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }),
          _buildDrawerItem(Icons.logout, 'Logout', onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Login()),
              (Route<dynamic> route) => false,
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildDrawerItem(IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800),
      ),
      onTap: onTap,
    );
  }

  List<Widget> _buildUserList() {
    return _users.asMap().entries.map((entry) {
      int index = entry.key;
      var user = entry.value;
      return _buildUserItem(
        context,
        user['name'],
        Icons.person,
        user['_id'],
        index,
      );
    }).toList();
  }

  Widget _buildUserItem(
      BuildContext context, String name, IconData icon, String id, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        name,
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800),
      ),
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('msg_id', id);
        print('Selected user ID saved as msg_id: $id');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FamilyChatPage(
              id: id,
              name: name,
            ),
          ),
        );
      },
    );
  }
}
