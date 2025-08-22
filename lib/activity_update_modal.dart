import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityUpdateModal extends StatefulWidget {
  final Map<String, dynamic> currentActivityData;

  const ActivityUpdateModal({
    super.key,
    required this.currentActivityData,
  });

  @override
  State<ActivityUpdateModal> createState() => _ActivityUpdateModalState();
}

class _ActivityUpdateModalState extends State<ActivityUpdateModal> {
  late TextEditingController _activityNameController;
  late TextEditingController _locationController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  String _selectedStatus = 'Scheduled';

  @override
  void initState() {
    super.initState();
    _activityNameController = TextEditingController(
      text: widget.currentActivityData['activity name'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.currentActivityData['location'] ?? '',
    );
    _durationController = TextEditingController(
      text: widget.currentActivityData['duration'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.currentActivityData['description'] ?? '',
    );
    _notesController = TextEditingController(
      text: widget.currentActivityData['notes'] ?? '',
    );
    _selectedStatus = widget.currentActivityData['status'] ?? 'Scheduled';
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Activity Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildActivityDetails(),
              const SizedBox(height: 24),
              _buildActivityDescription(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Details',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  'Activity Name',
                  'Enter activity name',
                  _activityNameController,
                ),
                const SizedBox(height: 16),
                _buildStatusDropdown(), // Add this line
                const SizedBox(height: 16),
                _buildTextField(
                  'Location',
                  'Enter location',
                  _locationController,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Duration',
                  'Enter duration (e.g., 30 mins)',
                  _durationController,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              items: ['Scheduled', 'In Progress', 'Completed', 'Cancelled']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: _getStatusColor(value),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue[700]!;
      case 'In Progress':
        return Colors.orange[700]!;
      case 'Completed':
        return Colors.green[700]!;
      case 'Cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildActivityDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Description',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  'Description',
                  'Enter activity description',
                  _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Notes',
                  'Enter additional notes',
                  _notesController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan[500] ?? Colors.cyan,
                  Colors.blue[600] ?? Colors.blue,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[700]!.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                final updatedActivityData = {
                  'date': DateTime.now().toString().split(' ')[0],
                  'activity name': _activityNameController.text,
                  'location': _locationController.text,
                  'duration': _durationController.text,
                  'description': _descriptionController.text,
                  'notes': _notesController.text,
                  'status': _selectedStatus, // Add this line
                  'completed': _selectedStatus == 'Completed',
                };
                Navigator.pop(context, updatedActivityData);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
