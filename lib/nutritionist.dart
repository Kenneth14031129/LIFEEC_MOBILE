// nutritionist.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class DieticianChatPage extends StatefulWidget {
  const DieticianChatPage({super.key});

  @override
  DieticianChatPageState createState() => DieticianChatPageState();
}

class DieticianChatPageState extends State<DieticianChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add(Message(content: _messageController.text, isAdmin: true));
        // Simulating a reply from the dietician after a delay
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _messages.add(Message(content: 'Hello, How may I help you? ${_messageController.text}', isAdmin: false));
          });
        });
      });
      _messageController.clear();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _messages.add(Message(content: 'Image: ${pickedFile.path}', isAdmin: true));
        // Simulating a reply from the dietician after a delay
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _messages.add(Message(content: 'Nutritionist received the image.', isAdmin: false));
          });
        });
      });
    }
  }

  Future<void> _attachFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.single;
      setState(() {
        _messages.add(Message(content: 'File: ${file.name}', isAdmin: true));
        // Simulating a reply from the dietician after a delay
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _messages.add(Message(content: 'Nutritionist received the file.', isAdmin: false));
          });
        });
      });
    }
  }

  void _makeCall() {
    // Add your call functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling...')),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Info'),
              onTap: () {
                Navigator.pop(context);
                // Add your info functionality here
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add your settings functionality here
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
        preferredSize: const Size.fromHeight(80.0),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 100, // Adjust the width to fit both icons
            leading: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 8), // Add some spacing between the back icon and avatar
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.blueAccent),
                ),
              ],
            ),
            title: Text(
              'Nutritionist',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.call, color: Colors.white),
                onPressed: _makeCall,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: _showMoreOptions,
              ),
            ],
          ),
        ),
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
                  mainAxisAlignment: message.isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    if (message.isAdmin) const SizedBox(width: 10),
                    if (message.isAdmin)
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 20,
                        child: Icon(Icons.person, color: Colors.white),
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
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.blueAccent),
                  onPressed: _attachFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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