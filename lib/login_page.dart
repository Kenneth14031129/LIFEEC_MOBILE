import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contact_list_screen.dart';
import 'dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'otp_verification_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool showPassword = false;
  bool isLoading = false;
  late AnimationController _animationController;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedUserType = 'nurse';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;

      if (isLogin) {
        response =
            await loginUser(_emailController.text, _passwordController.text);

        // Check for error messages in the response
        if (response.containsKey('error') || response.containsKey('message')) {
          final errorMsg = response['error'] ?? response['message'];
          if (errorMsg != null) {
            throw errorMsg.toString();
          }
        }

        // Safely access nested user data
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData == null) {
          throw 'Invalid response format';
        }

        // Check if user is archived
        if (userData['isArchived'] == true) {
          throw 'This account has been archived. Please contact your administrator.';
        }

        // Check verification status
        if (userData['isVerified'] == false) {
          throw 'Account is pending verification. Please wait for admin approval.';
        }

        // Check if user type is valid
        final userType = userData['userType']?.toString().toLowerCase();
        if (userType == null ||
            !['nurse', 'nutritionist', 'relative'].contains(userType)) {
          throw 'Invalid user type. Access denied.';
        }

        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userData['id']?.toString() ?? '');
        await prefs.setString('userRole', userType);
        await prefs.setString('userEmail', userData['email']?.toString() ?? '');
        await prefs.setString(
            'userName', userData['fullName']?.toString() ?? '');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully logged in!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to appropriate screen based on user type
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => userType == 'nurse'
                  ? const DashboardScreen()
                  : const ContactsListScreen(),
            ),
          );
        }
      } else {
        // Registration flow
        response = await registerUser(
          _fullNameController.text,
          _emailController.text,
          _passwordController.text,
          _phoneController.text,
          _selectedUserType,
        );

        // Add debug prints
        if (kDebugMode) {
          print('Registration response: $response');
        }

        // Extract userId from the response
        final userId = response['userId'] ?? response['user']?['id'];
        if (userId == null) {
          throw 'Invalid response format';
        }

        // Add debug prints
        if (kDebugMode) {
          print('Extracted userId: $userId');
          print('Email: ${_emailController.text}');
        }

        if (mounted) {
          // Show success message and navigate after a brief delay
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful! Please verify your email.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Add a slight delay to allow the snackbar to be visible
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPVerificationScreen(
                    userId: userId.toString(),
                    email: _emailController.text,
                  ),
                ),
                (route) => false, // This will clear the navigation stack
              );
            }
          });
        }
      }
    } catch (error) {
      // Handle errors
      setState(() {
        _errorMessage = error.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString(),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

// Helper functions for API calls
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://lifeec-mobile-1.onrender.com/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw errorData['message'] ?? 'Login failed';
    }
  }

  Future<Map<String, dynamic>> registerUser(String fullName, String email,
      String password, String phone, String userType) async {
    try {
      final response = await http.post(
        Uri.parse('https://lifeec-mobile-1.onrender.com/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'userType': userType,
        }),
      );

      if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw errorData['message'] ?? 'Registration failed';
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'Unexpected error occurred';
      }

      return json.decode(response.body);
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      rethrow;
    }
  }

// Also update _validateForm to include email validation:
  bool _validateForm() {
    // Clear any previous error message
    setState(() {
      _errorMessage = null;
    });

    if (isLogin) {
      // Login validation
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter both email and password';
        });
        return false;
      }
    } else {
      // Registration validation
      if (_fullNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all required fields';
        });
        return false;
      }
    }

    // Email format validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return false;
    }

    // Password length check
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long';
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE3F2FD).withOpacity(0.9),
              const Color(0xFFE8EAF6).withOpacity(0.9),
              const Color(0xFFF3E5F5).withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 60,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Title
                      _buildLogoAndTitle(),
                      const SizedBox(height: 40),

                      // Error Message
                      if (_errorMessage != null) _buildErrorMessage(),

                      // Form Fields
                      _buildFormFields(),
                      const SizedBox(height: 32),

                      // Submit Button
                      _buildSubmitButton(),
                      const SizedBox(height: 8),
                      _buildToggleButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoAndTitle() {
    return Column(
      children: [
        // Just the SVG without container
        Image.asset(
          'assets/Health.png',
          width: 150,
          height: 150,
        ),
        const SizedBox(height: 24),
        // Gradient Text for LIFEEC
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.cyan[500]!,
              Colors.blue[600]!,
            ],
          ).createShader(bounds),
          child: Text(
            'LIFEEC',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Professional Elderly Care System',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          if (!isLogin) ...[
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: !showPassword,
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
          ),
          if (!isLogin) ...[
            const SizedBox(height: 16),
            _buildDropdownField(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.cyan[500], size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedUserType,
      style: GoogleFonts.poppins(
        color: Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.work_outline, color: Colors.blue[700], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'nurse',
          child: Text('Nurse'),
        ),
        DropdownMenuItem(
          value: 'nutritionist',
          child: Text('Nutritionist'),
        ),
        DropdownMenuItem(
          value: 'relative',
          child: Text('Family Member/Relative'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedUserType = value);
        }
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan[500]!,
              Colors.blue[600]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLogin ? 'Sign In' : 'Sign Up',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton(
        onPressed: () {
          setState(() {
            isLogin = !isLogin;
            _errorMessage =
                null; // Clear any error messages when switching modes
          });
        },
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            children: [
              TextSpan(
                text: isLogin
                    ? "Don't have an account? "
                    : "Already have an account? ",
              ),
              TextSpan(
                text: isLogin ? "Sign Up" : "Sign In",
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
