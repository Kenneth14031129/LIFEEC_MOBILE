import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'messages_page.dart';
import 'notification_modal.dart';
import 'profile_modal.dart';
import 'role_navigation.dart';

class Contact {
  final String name;
  final String role;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isOnline;
  final String userId;
  final String? email;
  final String? phone;
  final int unreadCount;

  Contact({
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isOnline = false,
    required this.userId,
    this.email,
    this.phone,
    this.unreadCount = 0,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      role: json['role'],
      avatarUrl: json['avatarUrl'],
      lastMessage: json['lastMessage'] ?? 'No messages yet',
      lastMessageTime: DateTime.parse(
          json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      isOnline: json['isOnline'] ?? false,
      userId: json['userId'],
      email: json['email'],
      phone: json['phone'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  Map<String, List<Contact>> _groupedContacts = {};
  bool _isLoading = true;
  String? _error;
  String userRole = 'nurse';
  String? userId;
  String userInitial = 'N';
  int _unreadNotifications = 0;
  String _searchQuery = '';
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Initialize _selectedIndex with a default value before loading user role
    _selectedIndex = 2; // Default to Messages tab
    _initializeSelectedIndex(); // This will update based on user role
    _loadInitialData();
  }

  Future<void> _initializeSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'nurse';

    setState(() {
      // For nutritionist, Messages should be index 1
      _selectedIndex = role.toLowerCase() == 'nutritionist' ? 1 : 2;
    });
  }

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<Contact>>> get filteredContacts {
    if (_searchQuery.isEmpty) {
      return _groupedContacts.entries.toList();
    }

    Map<String, List<Contact>> filtered = {};
    _groupedContacts.forEach((role, contacts) {
      final filteredList = contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (contact.email
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();

      if (filteredList.isNotEmpty) {
        filtered[role] = filteredList;
      }
    });

    return filtered.entries.toList();
  }

  Future<void> _loadInitialData() async {
    await _loadUserRole();
    await _loadUserId(); // Wait for userId to be loaded
    if (mounted) {
      _fetchContacts(); // Now fetch contacts after userId is loaded
      _fetchUnreadCount();
    }
  }

  Future<String?> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'nurse';
    if (mounted) {
      setState(() {
        userRole = role;
      });
    }
    return role;
  }

  Future<String?> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    if (mounted) {
      setState(() {
        userId = id;
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

  void _updateUnreadCount(int count) {
    setState(() {
      _unreadNotifications = count;
    });
  }

  Future<void> _fetchContacts() async {
    if (userId == null) {
      setState(() {
        _error = 'User ID not found';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://lifeec-mobile-1.onrender.com/api/users/contacts?currentUserId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          Map<String, dynamic> contactsData = data['contacts'];

          setState(() {
            if (userRole.toLowerCase() == 'nurse') {
              // For nurses, show Admin, Nurse, Nutritionist, and Relative contacts
              _groupedContacts = Map.fromEntries(
                contactsData.entries
                    .where((entry) =>
                        entry.key == 'Admin' ||
                        entry.key == 'Nurse' ||
                        entry.key == 'Nutritionist' ||
                        entry.key == 'Relative')
                    .map((entry) {
                  List<Contact> contacts = (entry.value as List)
                      // Filter out archived users and current user
                      .where((contact) =>
                          contact['userId'] != userId &&
                          !(contact['isArchived'] ?? false))
                      .map((contact) => Contact(
                            name: contact['name'],
                            role: contact['role'],
                            avatarUrl: contact['avatarUrl'],
                            lastMessage:
                                contact['lastMessage'] ?? 'No messages yet',
                            lastMessageTime: DateTime.parse(
                                contact['lastMessageTime'] ??
                                    DateTime.now().toIso8601String()),
                            isOnline: contact['isOnline'] ?? false,
                            userId: contact['userId'],
                            email: contact['email'],
                            phone: contact['phone'],
                            unreadCount: contact['unreadCount'] ?? 0,
                          ))
                      .toList();
                  // Only include the role if there are contacts after filtering
                  return contacts.isNotEmpty
                      ? MapEntry(entry.key, contacts)
                      : null;
                }).whereType<MapEntry<String, List<Contact>>>(),
              );
            } else if (userRole.toLowerCase() == 'relative' ||
                userRole.toLowerCase() == 'nutritionist') {
              // Only show non-archived Nurse and Admin contacts for relatives and nutritionists
              _groupedContacts = Map.fromEntries(
                contactsData.entries
                    .where(
                        (entry) => entry.key == 'Nurse' || entry.key == 'Admin')
                    .map((entry) {
                  List<Contact> contacts = (entry.value as List)
                      .where((contact) => !(contact['isArchived'] ?? false))
                      .map((contact) => Contact(
                            name: contact['name'],
                            role: contact['role'],
                            avatarUrl: contact['avatarUrl'],
                            lastMessage:
                                contact['lastMessage'] ?? 'No messages yet',
                            lastMessageTime: DateTime.parse(
                                contact['lastMessageTime'] ??
                                    DateTime.now().toIso8601String()),
                            isOnline: contact['isOnline'] ?? false,
                            userId: contact['userId'],
                            email: contact['email'],
                            phone: contact['phone'],
                            unreadCount: contact['unreadCount'] ?? 0,
                          ))
                      .toList();
                  return MapEntry(entry.key, contacts);
                }),
              );
            } else {
              // Show all non-archived contacts for other users
              _groupedContacts = contactsData.map((key, value) {
                List<Contact> contacts = (value as List)
                    .where((contact) => !(contact['isArchived'] ?? false))
                    .map((contact) => Contact(
                          name: contact['name'],
                          role: contact['role'],
                          avatarUrl: contact['avatarUrl'],
                          lastMessage:
                              contact['lastMessage'] ?? 'No messages yet',
                          lastMessageTime: DateTime.parse(
                              contact['lastMessageTime'] ??
                                  DateTime.now().toIso8601String()),
                          isOnline: contact['isOnline'] ?? false,
                          userId: contact['userId'],
                          email: contact['email'],
                          phone: contact['phone'],
                          unreadCount: contact['unreadCount'] ?? 0,
                        ))
                    .toList();
                return MapEntry(key, contacts);
              });
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load contacts';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching contacts: $e');
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[400],
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[400],
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
              expandedHeight: 70,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: false,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.cyan[500] ?? Colors.cyan,
                        Colors.blue[600] ?? Colors.blue,
                      ],
                    ),
                  ),
                ),
              ),
              actions: userRole.toLowerCase() == 'relative'
                  ? [
                      // For relatives - show both notification and profile
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 12),
                        child: Stack(
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, top: 12),
                        child: CircleAvatar(
                          radius: 16,
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
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginPage()),
                                          (Route<dynamic> route) => false,
                                        );
                                      }
                                    },
                                  ),
                                ).then((_) {
                                  _loadUserData();
                                });
                              }
                            },
                            child: Text(
                              userInitial,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : userRole.toLowerCase() == 'nutritionist'
                      ? [
                          // For nutritionists - show only profile
                          Padding(
                            padding: const EdgeInsets.only(right: 16, top: 12),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: InkWell(
                                onTap: () {
                                  if (userId != null) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => ProfileModal(
                                        userId: userId!,
                                        onLogout: () async {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          await prefs.clear();
                                          if (mounted) {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LoginPage()),
                                              (Route<dynamic> route) => false,
                                            );
                                          }
                                        },
                                      ),
                                    ).then((_) {
                                      _loadUserData();
                                    });
                                  }
                                },
                                child: Text(
                                  userInitial,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]
                      : [] // For other roles
              ),
          if (userRole.toLowerCase() == 'relative' ||
              userRole.toLowerCase() == 'nutritionist' ||
              userRole.toLowerCase() == 'nurse')
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    ElevatedButton(
                      onPressed: _fetchContacts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = filteredContacts[index];
                  return _buildRoleSection(context, entry.key, entry.value);
                },
                childCount: filteredContacts.length,
              ),
            ),
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

  Widget _buildRoleSection(
      BuildContext context, String role, List<Contact> contacts) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  _getRoleIcon(role),
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '${contacts.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ...contacts.map((contact) => _buildContactTile(context, contact)),
        ],
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, Contact contact) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              contactName: contact.name,
              contactRole: contact.role,
              isOnline: contact.isOnline,
              contactId: contact.userId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: contact.avatarUrl != null
                        ? NetworkImage(contact.avatarUrl!)
                        : null,
                    child: contact.avatarUrl == null
                        ? Text(
                            contact.name[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          )
                        : null,
                  ),
                ),
                if (contact.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.lastMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (contact.unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${contact.unreadCount}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatLastMessageTime(contact.lastMessageTime),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Nurse':
        return Icons.medical_services;
      case 'Nutritionist':
        return Icons.restaurant_menu;
      case 'Relative':
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }
}
