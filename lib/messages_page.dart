import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'family_chat.dart';
import 'nutritionist.dart';

class MessagesPage extends StatefulWidget {
  final String userType;

  const MessagesPage({Key? key, required this.userType}) : super(key: key);

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? userType; // Make userType nullable

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  void _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType') ?? widget.userType;
    });
    _fetchUsers(); // Only call _fetchUsers after userType is initialized
  }

  Future<void> _fetchUsers() async {
    if (userType == null) return; // If userType is null, exit early

    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/users?userType=$userType'));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
    setState(() {
      _searchQuery = query;
    });
    await prefs.setString('lastSearchQuery', query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
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

  List<Widget> _buildUserList() {
    return _users.asMap().entries.map((entry) {
      int index = entry.key;
      var user = entry.value;
      return _buildUserItem(
        context,
        user['name'],
        Icons.person,
        user['_id'], // Pass the user ID here
        index,
      );
    }).toList();
  }


  Widget _buildUserItem(BuildContext context, String name, IconData icon, String id, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(name, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800)),
      onTap: () async {
        // Save the selected user's ID as 'msg_id' in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('msg_id', id);

        // Print confirmation
        print('Selected user ID saved as msg_id: $id');

        // Navigate to FamilyChatPage with the selected user's ID and name
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FamilyChatPage(
              id: id, // Pass the selected user's ID as receiverId
              name: name, // Pass the selected user's name
            ),
          ),
        );
      },
    );
  }

}
