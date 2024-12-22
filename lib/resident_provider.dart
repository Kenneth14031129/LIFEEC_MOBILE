import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'resident.dart';

class ResidentProvider extends ChangeNotifier {
  final List<Resident> _residents = [];
  List<int> _alertsPerMonth = List.generate(12, (_) => 0);
  List<DateTime> _emergencyAlerts = []; // Reintroduced this list
  bool _isLoading = false;
  String _error = '';

  List<Resident> get residents => _residents;
  List<int> get alertsPerMonth => _alertsPerMonth;
  List<DateTime> get emergencyAlerts => _emergencyAlerts; // Added getter
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Helper to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Helper to set error state
  void _setError(String value) {
    _error = value;
    notifyListeners();
  }

  /// Fetch residents from the API and update the provider's list
  Future<void> fetchResidents() async {
    final url = Uri.parse('http://localhost:5000/api/patient/list'); // Replace with your API endpoint
    _setLoading(true);
    _setError('');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Resident> loadedResidents = data.map((item) {
          return Resident(
            id: item['_id']['\$oid'] ?? '',
            name: item['name'] ?? '',
            age: item['age'] ?? 0,
            gender: item['gender'] ?? '',
            contact: item['contact'] ?? '',
            emergencyContactName: item['emergencyContactName'] ?? '',
            emergencyContactPhone: item['emergencyContactPhone'] ?? '',
          );
        }).toList();
        setResidents(loadedResidents);
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (error) {
      _setError('Error fetching residents: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch emergency alerts grouped by month for the dashboard
  Future<void> fetchAlertsPerMonth(int year) async {
    final url = Uri.parse('http://localhost:5000/api/alerts/countByMonth?year=$year');
    _setLoading(true);
    _setError('');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _alertsPerMonth = data.cast<int>();
        notifyListeners();
      } else {
        throw Exception('Failed to fetch alert counts by month');
      }
    } catch (error) {
      _setError('Error fetching alerts: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch summary metrics for the dashboard (if needed)
  Future<Map<String, dynamic>> fetchDashboardSummary() async {
    final url = Uri.parse('http://localhost:5000/api/dashboard/summary'); // Replace with your API endpoint
    _setLoading(true);
    _setError('');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _setLoading(false);
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch dashboard summary');
      }
    } catch (error) {
      _setError('Error fetching dashboard summary: $error');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the list of residents and notifies listeners
  void setResidents(List<Resident> initialResidents) {
    _residents.clear();
    _residents.addAll(initialResidents);
    notifyListeners();
  }

  /// Updates a resident's health data in the list
  void updateResidentHealthData(Resident updatedResident) {
    final index = _residents.indexWhere((resident) => resident.name == updatedResident.name);
    if (index != -1) {
      _residents[index] = updatedResident;
      notifyListeners();
    }
  }

  /// Sends an emergency alert and logs the alert timestamp
  void sendEmergencyAlert(String residentName) {
    final alertTime = DateTime.now();
    _emergencyAlerts.add(alertTime); // Ensure this list exists
    notifyListeners();
  }
}
