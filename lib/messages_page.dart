import 'package:flutter/foundation.dart';
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

  bool isExpired() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours >= 24;
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
    if (kDebugMode) {
      print('\n=== Fetching Unread Counts ===');
    }
    if (kDebugMode) {
      print('Current User ID: $currentUserId');
    }

    if (currentUserId == null) {
      if (kDebugMode) {
        print('❌ No current user ID found');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Making API request to fetch unread counts...');
      }
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-hzo4.onrender.com/api/messages/unread/$currentUserId'),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Decoded unread counts: ${data['unreadCounts']}');
        }

        if (mounted) {
          setState(() {
            unreadCounts = Map<String, int>.from(data['unreadCounts']);
          });
          if (kDebugMode) {
            print('Updated state with new unread counts: $unreadCounts');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Widget not mounted, skipped setState');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch unread counts: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching unread counts: $e');
      }
    }
  }

  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    if (kDebugMode) {
      print('\n=== Marking Messages as Read ===');
    }
    if (kDebugMode) {
      print('Sender ID: $senderId');
    }
    if (kDebugMode) {
      print('Receiver ID: $receiverId');
    }

    try {
      if (kDebugMode) {
        print('Making API request to mark messages as read...');
      }
      final response = await http.post(
        Uri.parse(
            'https://lifeec-mobile-hzo4.onrender.com/api/messages/mark-read'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Successfully marked messages as read');
        }
        _fetchUnreadCounts();
      } else {
        if (kDebugMode) {
          print('❌ Failed to mark messages as read: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking messages as read: $e');
      }
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
        Uri.parse(
            'https://lifeec-mobile-hzo4.onrender.com/api/emergency-alerts/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            alerts = data
                .map((alert) => EmergencyAlert.fromJson(alert))
                .where((alert) => !alert.isExpired())
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
      if (kDebugMode) {
        print('Error fetching alerts: $e');
      }
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
      final response = await http.get(Uri.parse(
          'https://lifeec-mobile-hzo4.onrender.com/api/users?userType=$userType'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        List<Map<String, dynamic>> users = jsonResponse.map((user) {
          return {
            '_id': user['_id'],
            'name': user['name'],
            'userType': user['userType'],
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
      if (kDebugMode) {
        print('Error fetching users: $error');
      }
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: userType == 'Nurse'
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
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
                  ]
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40.0),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF1E88E5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _buildEnhancedUserList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    String dashboardTitle = '';
    if (userType == 'Nutritionist') {
      dashboardTitle = 'Nutritionist';
    } else if (userType == 'Family Member') {
      dashboardTitle = 'Relative';
    }

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Enhanced Drawer Header
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 40, color: Color(0xFF1E88E5)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dashboardTitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userEmail,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildEnhancedDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  _buildDivider(),
                ],
              ),
            ),

            // Bottom Section with Logout
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _buildEnhancedDrawerItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                showTrailing: false,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: Text(
                          'Confirm Logout',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const Login()),
                                (Route<dynamic> route) => false,
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showTrailing = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: showTrailing
          ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.grey.shade200),
    );
  }

  List<Widget> _buildEnhancedUserList() {
    return _users.asMap().entries.map((entry) {
      int index = entry.key;
      var user = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('msg_id', user['_id']);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FamilyChatPage(
                    id: user['_id'],
                    name: user['name'],
                    userType: user['userType'] == 'Family Member'
                        ? 'Relative'
                        : user['userType'],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['userType'] == 'Family Member'
                              ? 'Relative'
                              : user['userType'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCounts[user['_id']] != null &&
                      unreadCounts[user['_id']]! > 0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${unreadCounts[user['_id']]}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Emergency Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchEmergencyAlerts,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : alerts.isEmpty
                          ? Center(
                              child: Text(
                                'No emergency alerts',
                                style: GoogleFonts.poppins(),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: alerts.length,
                              itemBuilder: (context, index) {
                                final alert = alerts[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.warning,
                                                color: Colors.red),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Emergency alert for ${alert.residentName}',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 32.0),
                                          child: Text(
                                            getTimeAgo(alert.timestamp),
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E88E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
