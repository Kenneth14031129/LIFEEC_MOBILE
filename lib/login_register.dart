// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'nurse_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'messages_page.dart';
import 'forgot_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  bool isPasswordVisible = false;

  final _signInFormKey = GlobalKey<FormState>();

  final TextEditingController _signInEmailController = TextEditingController();
  final TextEditingController _signInPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;

  final String baseUrl = 'http://localhost:5000/api/auth';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleAuthentication() async {
    if (_signInFormKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      await signIn(_signInEmailController.text, _signInPasswordController.text);
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> signIn(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/signin'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (kDebugMode) {
        print('Login successful: $data');
        print('User Type: ${data['userType']}');
        print('Login response data: $data');
        print('User Name: ${data['name']}');
      }

      // Save user data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', data['id']);
      await prefs.setString('token', data['token'] ?? '');
      await prefs.setString('userType', data['userType'] ?? '');
      await prefs.setString('email', email);
      await prefs.setString('name', data['name'] ?? '');

      // Store residentId if the userType is 'Family Member'
      if (data['userType'] == 'Family Member' && data['residentId'] != null) {
        await prefs.setString('residentId', data['residentId']);
        // Add debug log to confirm residentId is stored
        final storedResidentId = prefs.getString('residentId');
        print('[DEBUG] Resident ID stored: $storedResidentId');
      } else {
        print('[DEBUG] Resident ID not applicable for this user type.');
      }

      // Navigate to appropriate dashboard based on userType
      if (data['userType'] == 'Family Member' || data['userType'] == 'Nutritionist') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NurseDashboardApp(userType: data['userType']),
          ),
        );
      } else if (data['userType'] == 'Nurse') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NurseDashboardApp(userType: "Nurse"),
          ),
        );
      } else {
        print('Unknown userType: ${data['userType']}');
      }
    } else {
      if (kDebugMode) {
        print('Login failed: ${response.body}');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login failed: ${response.body}'),
      ));
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error during login: $error');
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('An error occurred during login'),
    ));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 100),
              FadeTransition(
                opacity: _buttonAnimation,
                child: Text(
                  'LIFEEC',
                  style: GoogleFonts.playfairDisplay(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ListView(
                      children: [
                        const SizedBox(height: 20),
                        buildSignInForm(),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _buttonAnimation,
                          child: GestureDetector(
                            onTap: () => handleAuthentication(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.blueAccent,
                                    Colors.lightBlueAccent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPassword(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Form buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        children: [
          buildEmailField(_signInEmailController),
          const SizedBox(height: 15),
          buildPasswordField(_signInPasswordController),
        ],
      ),
    );
  }

  TextFormField buildEmailField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        return null;
      },
    );
  }

  TextFormField buildPasswordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon:
              Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
      ),
      obscureText: !isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }
}
