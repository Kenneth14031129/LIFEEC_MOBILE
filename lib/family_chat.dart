import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyChatPage extends StatefulWidget {
  final String id;
  final String name;
  final String userType;

  const FamilyChatPage({
    super.key,
    required this.id,
    required this.name,
    required this.userType,
  });

  @override
  FamilyChatPageState createState() => FamilyChatPageState();
}

class Message {
  final String content;
  final bool isAdmin;
  final DateTime time;
  final bool isRead;

  Message({
    required this.content,
    required this.isAdmin,
    required this.time,
    required this.isRead,
  });
}

class FamilyChatPageState extends State<FamilyChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  String? _loggedInUserId;
  String? _msgId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initializeChat() async {
    await _loadUserIds();
    _verifyMsgId();
    if (_loggedInUserId != null && _msgId != null) {
      await _markMessagesAsRead();
      await _fetchMessages();
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/messages/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.id,
          'receiverId': _loggedInUserId,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _loadUserIds() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      setState(() {
        _loggedInUserId = userId;
        _msgId = widget.id;
      });
    } catch (e) {
      print('Error loading user IDs: $e');
    }
  }

  Future<void> _verifyMsgId() async {
    if (_msgId != widget.id) {
      print(
          'Warning: msg_id ($_msgId) does not match receiver ID (${widget.id})');
    }
  }

  Future<void> _fetchMessages() async {
    if (_loggedInUserId == null || _msgId == null) return;

    try {
      final url = Uri.parse(
        'http://localhost:5000/api/messages/between-users?senderId=$_loggedInUserId&receiverId=$_msgId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(jsonResponse.map((msg) {
            // Parse the UTC time and convert to local
            DateTime utcTime = DateTime.parse(msg['time']);
            DateTime localTime = utcTime.toLocal();

            return Message(
              content: msg['text'],
              isAdmin: msg['senderId'] == _loggedInUserId,
              time: localTime, // Use local time
              isRead: msg['read'] ?? false,
            );
          }).toList());
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching messages: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';

    // Convert 24-hour to 12-hour format
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    // Format with padded minutes and AM/PM
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _loggedInUserId == null) return;

    try {
      final now = DateTime.now();
      final messageData = {
        'senderId': _loggedInUserId,
        'receiverId': _msgId,
        'text': _messageController.text,
        'time': now.toUtc().toIso8601String(), // Convert to UTC for storage
        'read': false,
      };

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messageData),
      );

      if (response.statusCode == 201) {
        setState(() {
          _messages.add(Message(
            content: _messageController.text,
            isAdmin: true,
            time: now, // Use local time for display
            isRead: false,
          ));
        });
        _messageController.clear();
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
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
        title: Row(
          children: [
            Flexible(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' (${widget.userType == 'Family Member' ? 'Relative' : widget.userType})',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: message.isAdmin
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!message.isAdmin) ...[
                        const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          radius: 20,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.isAdmin
                                ? Colors.blueAccent
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: message.isAdmin
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: message.isAdmin
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(message.time),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: message.isAdmin
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.black54,
                                    ),
                                  ),
                                  if (message.isAdmin) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.isRead
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
