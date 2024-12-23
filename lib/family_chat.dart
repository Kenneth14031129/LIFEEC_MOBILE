import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyChatPage extends StatefulWidget {
  final String id; // Receiver's ID
  final String name; // Receiver's name

  const FamilyChatPage({super.key, required this.id, required this.name});

  @override
  FamilyChatPageState createState() => FamilyChatPageState();
}

class FamilyChatPageState extends State<FamilyChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];

  String? _loggedInUserId;
  String? _msgId;

  @override
  void initState() {
    super.initState();
    print('\n=== FamilyChatPage Initialized ===');
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('\n=== Initializing Chat ===');
    await _loadUserIds();
    _verifyMsgId();
    if (_loggedInUserId != null && _msgId != null) {
      print('✅ Both user IDs available, marking messages as read...');
      await _markMessagesAsRead();
      await _fetchMessages();
    } else {
      print('❌ Missing user IDs - cannot initialize chat');
    }
  }

  Future<void> _markMessagesAsRead() async {
    print('\n=== Marking Messages as Read ===');
    print('Sender ID (other user): ${widget.id}');
    print('Receiver ID (current user): $_loggedInUserId');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/messages/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.id,
          'receiverId': _loggedInUserId,
        }),
      );

      print('Mark as read response status: ${response.statusCode}');
      print('Mark as read response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Successfully marked messages as read');
      } else {
        print('❌ Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  Future<void> _loadUserIds() async {
    print('\n=== Loading User IDs ===');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final msgId = prefs.getString('msg_id');

      print('Loaded from SharedPreferences:');
      print('- userId: $userId');
      print('- msg_id: $msgId');
      print('- widget.id: ${widget.id}');

      setState(() {
        _loggedInUserId = userId;
        _msgId = widget.id; // Use widget.id directly instead of stored msg_id
      });

      if (_loggedInUserId == null) {
        print('❌ Error: Logged-in user ID not found');
      } else {
        print('✅ Logged-in user ID loaded: $_loggedInUserId');
      }

      if (_msgId == null) {
        print('❌ Error: msg_id not found');
      } else {
        print('✅ msg_id loaded: $_msgId');
      }
    } catch (e) {
      print('❌ Error loading user IDs: $e');
    }
  }

  Future<void> _verifyMsgId() async {
    print('\n=== Verifying Message ID ===');
    if (_msgId != widget.id) {
      print(
          '⚠️ Warning: msg_id ($_msgId) does not match receiver ID (${widget.id})');
    } else {
      print('✅ msg_id matches receiver ID');
    }
  }

  Future<void> _fetchMessages() async {
    print('\n=== Fetching Messages ===');
    if (_loggedInUserId == null || _msgId == null) {
      print('❌ Error: User IDs are not loaded yet');
      return;
    }

    try {
      final url = Uri.parse(
        'http://localhost:5000/api/messages/between-users?senderId=$_loggedInUserId&receiverId=$_msgId',
      );
      print('Fetching messages from: $url');

      final response = await http.get(url);
      print('Fetch response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        print('Received ${jsonResponse.length} messages');

        setState(() {
          _messages.clear();
          _messages.addAll(jsonResponse.map((msg) {
            return Message(
              content: msg['text'],
              isAdmin: msg['senderId'] == _loggedInUserId,
            );
          }).toList());
        });
        print('✅ Messages updated in state');
      } else {
        print('❌ Failed to load messages: ${response.body}');
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    print('\n=== Sending Message ===');
    if (_messageController.text.isEmpty) {
      print('❌ Error: Message is empty');
      return;
    }
    if (_loggedInUserId == null) {
      print('❌ Error: Sender ID is null');
      return;
    }

    try {
      final messageData = {
        'senderId': _loggedInUserId,
        'receiverId': _msgId,
        'text': _messageController.text,
        'time': DateTime.now().toIso8601String(),
        'read': false,
      };

      print('Sending message data: $messageData');

      final url = Uri.parse('http://localhost:5000/api/messages');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messageData),
      );

      print('Send response status: ${response.statusCode}');
      print('Send response body: ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          _messages.add(Message(
            content: _messageController.text,
            isAdmin: true,
          ));
        });
        _messageController.clear();
        print('✅ Message sent successfully');
      } else {
        print('❌ Failed to send message: ${response.body}');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.name, style: GoogleFonts.playfairDisplay(fontSize: 20)),
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
                        color: message.isAdmin
                            ? Colors.blueAccent
                            : Colors.grey.shade300,
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
