import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'contact_list_screen.dart';
import 'dashboard.dart';
import 'residents_list.dart';

class RoleNavigation extends StatelessWidget {
  final String userRole;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const RoleNavigation({
    super.key,
    required this.userRole,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  List<BottomNavigationBarItem> _getNavigationItems() {
    switch (userRole.toLowerCase()) {
      case 'nurse':
        return [
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Icon(Icons.dashboard_rounded),
            ),
            label: 'Dashboard',
            tooltip: 'View Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Icon(Icons.people_alt_rounded),
            ),
            label: 'Residents List',
            tooltip: 'View Residents',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Icon(Icons.message_rounded),
            ),
            label: 'Messages',
            tooltip: 'View Messages',
          ),
        ];

      case 'nutritionist':
        return [
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Icon(Icons.people_alt_rounded),
            ),
            label: 'Residents List',
            tooltip: 'View Residents',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Icon(Icons.message_rounded),
            ),
            label: 'Messages',
            tooltip: 'View Messages',
          ),
        ];

      default:
        return [];
    }
  }

  Future<Widget> _handleNavigation(BuildContext context, int index) async {
    switch (userRole.toLowerCase()) {
      case 'nurse':
        // For nurses, use the original navigation with dashboard
        switch (index) {
          case 0:
            return const DashboardScreen();
          case 1:
            return const ResidentsList();
          case 2:
            return const ContactsListScreen();
          default:
            return const DashboardScreen();
        }

      case 'nutritionist':
        // For nutritionists, only toggle between residents list and messages
        switch (index) {
          case 0:
            return const ResidentsList();
          case 1:
            return const ContactsListScreen();
          default:
            return const ContactsListScreen();
        }

      default:
        return const ResidentsList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only hide navigation bar for relatives
    if (userRole.toLowerCase() == 'relative') {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan[500] ?? Colors.cyan,
            Colors.blue[600] ?? Colors.blue,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[700]!.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) async {
          onItemSelected(index);
          if (selectedIndex != index) {
            final nextScreen = await _handleNavigation(context, index);
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => nextScreen),
              );
            }
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: _getNavigationItems(),
      ),
    );
  }
}
