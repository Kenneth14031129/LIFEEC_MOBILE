import 'package:flutter/foundation.dart';
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
        if (kDebugMode) {
          print('Failed to mark messages as read: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
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
      if (kDebugMode) {
        print('Error loading user IDs: $e');
      }
    }
  }

  Future<void> _verifyMsgId() async {
    if (_msgId != widget.id) {
      if (kDebugMode) {
        print(
            'Warning: msg_id ($_msgId) does not match receiver ID (${widget.id})');
      }
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
            DateTime utcTime = DateTime.parse(msg['time']);
            DateTime localTime = utcTime.toLocal();

            return Message(
              content: msg['text'],
              isAdmin: msg['senderId'] == _loggedInUserId,
              time: localTime,
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
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
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
        'time': now.toUtc().toIso8601String(),
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
            time: now,
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Container(
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E88E5), // Darker blue
                Color(0xFF64B5F6), // Lighter blue
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Back Button moved to far left
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 22),
                  padding: const EdgeInsets.only(left: 8),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                // User Avatar
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22.5),
                  ),
                  child: Center(
                    child: Text(
                      widget.name[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and User Type
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.userType == 'Family Member'
                                  ? '(Relative)'
                                  : '(${widget.userType})',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh Button on the right
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _fetchMessages,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final showAvatar = !message.isAdmin &&
                      (index == 0 ||
                          _messages[index - 1].isAdmin != message.isAdmin);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 12.0,
                      left: message.isAdmin ? 50 : 0,
                      right: message.isAdmin ? 0 : 50,
                    ),
                    child: Row(
                      mainAxisAlignment: message.isAdmin
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!message.isAdmin && showAvatar) ...[
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(17.5),
                            ),
                            child: Center(
                              child: Text(
                                widget.name[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else if (!message.isAdmin) ...[
                          const SizedBox(width: 43),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: message.isAdmin
                                  ? const Color(0xFF1E88E5)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft:
                                    Radius.circular(message.isAdmin ? 20 : 5),
                                bottomRight:
                                    Radius.circular(message.isAdmin ? 5 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: message.isAdmin
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: GoogleFonts.poppins(
                                    color: message.isAdmin
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(message.time),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: message.isAdmin
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.black45,
                                      ),
                                    ),
                                    if (message.isAdmin) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        message.isRead
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 14,
                                        color: message.isRead
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.white.withOpacity(0.7),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
