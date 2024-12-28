// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nurse_dashboard.dart';
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final String baseUrl = 'http://localhost:5000/api/auth';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
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

        if (data['userType'] == 'Nurse') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NurseDashboardApp(userType: "Nurse"),
            ),
          );
        } else if (data['userType'] == 'Family Member' ||
            data['userType'] == 'Nutritionist') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MessagesPage(userType: data['userType']),
            ),
          );
        } else {
          print('Unknown userType: ${data['userType']}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid email or password',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection error. Please try again.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A237E),
                  const Color(0xFF0288D1).withOpacity(0.8),
                  const Color(0xFF26C6DA).withOpacity(0.6),
                ],
              ),
            ),
          ),

          // Decorative Elements
          Positioned(
            right: -100,
            top: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          Positioned(
            left: -50,
            bottom: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Animated Logo Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: buildLogoSection(),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Glassmorphic Login Card
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: Curves.easeOutBack
                            .transform(_buttonAnimation.value),
                        child: buildLoginCard(),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'LIFEEC',
          style: GoogleFonts.montserrat(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        Text(
          'Healthcare Solutions',
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              buildSignInForm(),
              const SizedBox(height: 30),
              buildSignInButton(),
              buildForgotPasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Form buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        children: [
          buildEmailField(),
          const SizedBox(height: 20),
          buildPasswordField(),
        ],
      ),
    );
  }

  Widget buildEmailField() {
    return TextFormField(
      controller: _signInEmailController,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
        prefixIcon:
            Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget buildPasswordField() {
    return TextFormField(
      controller: _signInPasswordController,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
        prefixIcon:
            Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.9)),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.9),
          ),
          onPressed: () =>
              setState(() => isPasswordVisible = !isPasswordVisible),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
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

  Widget buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: !isLoading ? handleAuthentication : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPassword()),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        'Forgot Password?',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}
