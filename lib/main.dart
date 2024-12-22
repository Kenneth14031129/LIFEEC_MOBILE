import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'resident_provider.dart';
import 'login_register.dart'; // Import the LoginRegister screen

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ResidentProvider(),
      child: const NurseDashboardApp(),
    ),
  );
}

class NurseDashboardApp extends StatelessWidget {
  const NurseDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nurse Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.lightBlueAccent,
          primary: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        textTheme: GoogleFonts.playfairDisplayTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
        ),
      ),
      home: const Login(), // Navigate to LoginRegister screen
    );
  }
}