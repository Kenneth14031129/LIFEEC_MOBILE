import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyChatPage extends StatefulWidget {
  final String id; // Receiver's ID
  final String name; // Receiver's name

  const FamilyChatPage({Key? key, required this.id, required this.name}) : super(key: key);

  @override
  FamilyChatPageState createState() => FamilyChatPageState();
}

class FamilyChatPageState extends State<FamilyChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();

  String? _loggedInUserId; // To store the logged-in user's ID
  String? _msgId; // Receiver's ID

  @override
  void initState() {
    super.initState();
    _initializeChat(); // Load user IDs and fetch messages
  }

  Future<void> _initializeChat() async {
    await _loadUserIds(); // Load both logged-in user ID and msg_id
    _verifyMsgId(); // Verify if msg_id matches the selected user ID
    if (_loggedInUserId != null && _msgId != null) {
      await _fetchMessages(); // Fetch messages only if both IDs are available
    }
  }

  Future<void> _loadUserIds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = prefs.getString('userId'); // Use the correct key
      _msgId = prefs.getString('msg_id'); // Receiver's ID
    });

    if (_loggedInUserId == null) {
      print('Error: Logged-in user ID not found in SharedPreferences.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not retrieve logged-in user ID')),
      );
    } else {
      print('Logged-in user ID loaded: $_loggedInUserId');
    }

    if (_msgId == null) {
      print('Error: msg_id not found in SharedPreferences.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not retrieve msg_id')),
      );
    } else {
      print('msg_id loaded: $_msgId');
    }
  }

  Future<void> _verifyMsgId() async {
    if (_msgId != widget.id) {
      print('Warning: msg_id ($_msgId) does not match receiver ID (${widget.id}).');
    }
  }

  Future<void> _fetchMessages() async {
    if (_loggedInUserId == null || _msgId == null) {
      print('Error: User IDs are not loaded yet.');
      return;
    }

    try {
      final url = Uri.parse(
        'http://localhost:5000/api/messages/between-users?senderId=$_loggedInUserId&receiverId=$_msgId',
      );

      print('Fetching messages between sender ($_loggedInUserId) and receiver ($_msgId)');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(jsonResponse.map((msg) {
            return Message(
              content: msg['text'],
              isAdmin: msg['senderId'] == _loggedInUserId,
            );
          }).toList());
        });
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && _loggedInUserId != null) {
      try {
        final messageData = {
          'senderId': _loggedInUserId, // Logged-in user's ID
          'receiverId': _msgId, // Receiver's ID
          'text': _messageController.text,
          'time': DateTime.now().toIso8601String(),
          'isRead': false, // Initial read status as false
        };

        print('Sending message: $messageData');

        final url = Uri.parse('http://localhost:5000/api/messages');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(messageData),
        );

        if (response.statusCode == 201) {
          setState(() {
            _messages.add(Message(
              content: _messageController.text,
              isAdmin: true,
            ));
          });
          _messageController.clear();
          print('Message sent successfully!');
        } else {
          throw Exception('Failed to send message: ${response.body}');
        }
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      print('Error: Sender ID is null or message is empty.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sender ID is null or message is empty')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, style: GoogleFonts.playfairDisplay(fontSize: 20)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Row(
                  mainAxisAlignment: message.isAdmin
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!message.isAdmin)
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 20,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    if (!message.isAdmin) const SizedBox(width: 10),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: message.isAdmin ? Colors.blueAccent : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: message.isAdmin ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String content;
  final bool isAdmin;

  Message({required this.content, required this.isAdmin});
}
