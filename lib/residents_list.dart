import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_page.dart';
import 'notification_modal.dart';
import 'profile_modal.dart';
import 'residents_details.dart';
import 'role_navigation.dart';

class ResidentsList extends StatefulWidget {
  const ResidentsList({super.key});

  @override
  State<ResidentsList> createState() => _ResidentsListState();
}

class _ResidentsListState extends State<ResidentsList> {
  bool isLoading = true;
  List<Map<String, dynamic>> residents = [];
  late int _selectedIndex;
  String _searchQuery = '';
  String? _error;
  int _unreadNotifications = 0;
  String? userId;
  String userInitial = 'N';
  String userRole = 'nurse';

  @override
  void initState() {
    super.initState();
    // Initialize _selectedIndex with a default value before loading user role
    _selectedIndex = 0; // Default to first tab
    _initializeSelectedIndex(); // This will update based on user role
    _loadUserId();
    _fetchResidents();
    _fetchUnreadCount();
  }

// Add this method
  Future<void> _initializeSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'nurse';

    setState(() {
      // For nutritionist, Residents List is index 0
      _selectedIndex = role.toLowerCase() == 'nutritionist' ? 0 : 1;
    });
  }

  Future<String?> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    final role = prefs.getString('userRole') ?? 'nurse';
    if (mounted) {
      setState(() {
        userId = id;
        userRole = role; // Make sure to update the userRole
      });
    }
    if (id != null) {
      _loadUserData();
    }
    return id;
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

// Add this method to update the unread count
  void _updateUnreadCount(int count) {
    setState(() {
      _unreadNotifications = count;
    });
  }

  Future<void> _fetchResidents() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final Uri url = Uri.parse(
          'https://lifeec-mobile-1.onrender.com/api/residents/search');

      if (kDebugMode) {
        print('Fetching from URL: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          residents = data
              .map((resident) => {
                    'id': resident['_id'],
                    'name': resident['fullName'] ?? 'Unknown',
                    'dateOfBirth': _formatDate(resident['dateOfBirth']),
                    'location': resident['address'] ?? 'No address',
                    'lastUpdated': DateTime.parse(resident['updatedAt']),
                    'gender': resident['gender'] ?? 'Not specified',
                    'phone': resident['contactNumber'] ?? 'No phone',
                    'emergencyContact': {
                      'name': resident['emergencyContact']['name'] ?? 'No name',
                      'relation': resident['emergencyContact']['relation'] ??
                          'Not specified',
                      'phone':
                          resident['emergencyContact']['phone'] ?? 'No phone',
                      'email':
                          resident['emergencyContact']['email'] ?? 'No email',
                    },
                  })
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching residents: $e');
      }
      setState(() {
        _error = 'Failed to load residents. Please try again. Error: $e';
        isLoading = false;
      });
    }
  }

  // Add this function at class level in _ResidentsListState
  // In residents_list.dart - Update the _createEmergencyAlert function:

  Future<void> _createEmergencyAlert(Map<String, dynamic> resident) async {
    try {
      final response = await http.post(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/emergency-alerts'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'residentId': resident['id'],
          'residentName': resident['name'],
          'emergencyContact': {
            'name': resident['emergencyContact']['name'],
            'phone': resident['emergencyContact']['phone'],
            'email': resident['emergencyContact']['email'],
            'relation': resident['emergencyContact']['relation'],
          }
        }),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 201) {
        // Alert created successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Emergency alert triggered for ${resident['name']}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to create emergency alert');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating emergency alert: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to trigger emergency alert: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Add this method to fetch initial unread count
  Future<void> _fetchUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/emergency-alerts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final unreadCount =
            data.where((alert) => !(alert['read'] ?? false)).length;
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching unread count: $e');
      }
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // Add debounce for search
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchResidents();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredResidents {
    return residents.where((resident) {
      return resident['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchAndFilter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildResidentsList(),
        ],
      ),
      bottomNavigationBar: RoleNavigation(
        userRole: userRole,
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
                // Add the condition here
                if (userRole.toLowerCase() != 'nutritionist')
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: Colors.white,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                NotificationModal(
                              onUnreadCountChanged: _updateUnreadCount,
                            ),
                          );
                        },
                      ),
                      NotificationBadge(count: _unreadNotifications),
                    ],
                  ),
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

  Widget _buildHeader() {
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
                  'Residents List',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage and monitor residents',
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
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return TextField(
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search residents...',
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixIcon: const Icon(Icons.search),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildResidentsList() {
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: GoogleFonts.poppins(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchResidents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (residents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No residents found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildResidentCard(residents[index]),
          childCount: residents.length,
        ),
      ),
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> resident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[50],
                  child: Text(
                    resident['name'].toString()[0],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resident['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.warning),
                  color: Colors.red[700],
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Emergency Alert',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          content: Text(
                            'Do you want to trigger an emergency alert for ${resident['name']}?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _createEmergencyAlert(resident);
                              },
                              child: Text(
                                'Trigger Alert',
                                style: GoogleFonts.poppins(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('DOB:', resident['dateOfBirth']),
                const SizedBox(height: 8),
                _buildInfoRow('Location:', resident['location']),
                const SizedBox(height: 8),
                _buildInfoRow('Gender:', resident['gender']),
                const SizedBox(height: 8),
                _buildInfoRow('Phone:', resident['phone']),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Emergency Contact',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Name:', resident['emergencyContact']['name']),
                const SizedBox(height: 8),
                _buildInfoRow(
                    'Relation:', resident['emergencyContact']['relation']),
                const SizedBox(height: 8),
                _buildInfoRow('Phone:', resident['emergencyContact']['phone']),
                const SizedBox(height: 8),
                _buildInfoRow('Email:', resident['emergencyContact']['email']),
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResidentDetails(
                      residentId: resident['id'],
                      userRole: userRole,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
