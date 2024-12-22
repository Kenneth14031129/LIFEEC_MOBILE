// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController _signInPasswordController =
      TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;
  final String baseUrl = 'http://localhost:5000/api/auth';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['id']);
        await prefs.setString('token', data['token'] ?? '');
        await prefs.setString('userType', data['userType'] ?? '');
        await prefs.setString('email', email);
        await prefs.setString('name', data['name'] ?? '');

        if (data['userType'] == 'Family Member' && data['residentId'] != null) {
          await prefs.setString('residentId', data['residentId']);
          final storedResidentId = prefs.getString('residentId');
          print('[DEBUG] Resident ID stored: $storedResidentId');
        } else {
          print('[DEBUG] Resident ID not applicable for this user type.');
        }

        // Updated navigation logic based on user type
        if (data['userType'] == 'Nurse') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NurseDashboardApp(userType: "Nurse"),
            ),
          );
        } else if (data['userType'] == 'Family Member' ||
            data['userType'] == 'Nutritionist') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagesPage(userType: data['userType']),
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
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during login: $error');
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred during login'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/healthcare_mobile.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay with medical theme color
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.4),
            ),
          ),
          SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo section with medical icon
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _buttonAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'LIFEEC',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Healthcare Solutions',
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Glass Login form card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 4,
                          sigmaY: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.lato(
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              buildSignInForm(),
                              const SizedBox(height: 30),
                              FadeTransition(
                                opacity: _buttonAnimation,
                                child: ElevatedButton(
                                  onPressed: handleAuthentication,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text(
                                          'Sign In',
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPassword(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
          const SizedBox(height: 20),
          buildPasswordField(_signInPasswordController),
        ],
      ),
    );
  }

  TextFormField buildEmailField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(Icons.email, color: Colors.white.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.8)),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
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
