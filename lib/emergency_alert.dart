import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmergencyAlertPage extends StatefulWidget {
  const EmergencyAlertPage({super.key});

  @override
  EmergencyAlertPageState createState() => EmergencyAlertPageState();
}

class EmergencyAlertPageState extends State<EmergencyAlertPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectedResident;
  List<Map<String, String>> _residents = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _controller.forward();

    _fetchResidents();
  }

  Future<void> _fetchResidents() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/patient/list'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _residents = data.map<Map<String, String>>((resident) {
            return {
              "id": resident["_id"].toString(),
              "name": resident["name"].toString(),
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (e) {
      print('Error fetching residents: $e');
    }
  }

  void _sendEmergencyAlert() async {
    if (_selectedResident == null) {
      _showAlertDialog('Error', 'Please select a resident before sending an alert.');
      return;
    }

    final selectedResident = _residents
        .firstWhere((resident) => resident['name'] == _selectedResident);

    final alertData = {
      "residentId": selectedResident['id'],
      "residentName": selectedResident['name'],
      "message": "Emergency alert triggered for ${selectedResident['name']}",
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/emergency-alerts'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(alertData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showAlertDialog('Success', 'Emergency alert has been sent!');
      } else {
        throw Exception('Failed to send emergency alert');
      }
    } catch (e) {
      _showAlertDialog('Error', 'Failed to send alert: $e');
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.redAccent,
        title: Text(
          'Emergency Alert',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Resident Selector
                  DropdownButtonFormField<String>(
                    value: _selectedResident,
                    hint: const Text('Select Resident'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    items: _residents.map((resident) {
                      return DropdownMenuItem<String>(
                        value: resident['name'],
                        child: Text(
                          resident['name']!,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedResident = newValue;
                      });
                    },
                  ),
                  const Spacer(),
                  // Emergency Button
                  GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTap: _sendEmergencyAlert,
                    child: ScaleTransition(
                      scale: _controller,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'ALERT',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Instruction Text
                  Text(
                    'Tap the button to send an alert.',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
