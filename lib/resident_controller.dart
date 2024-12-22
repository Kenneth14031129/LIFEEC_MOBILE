// resident_controller.dart

import 'resident.dart';

class ResidentController {
  final List<Resident> _residents = [];

  List<Resident> get residents => _residents;

  void addResident(Resident resident) {
    _residents.add(resident);
  }

  void updateResident(String id, Resident updatedResident) {
    final index = _residents.indexWhere((r) => r.id == id);
    if (index != -1) {
      _residents[index] = updatedResident;
    }
  }

  void deleteResident(String id) {
    _residents.removeWhere((resident) => resident.id == id);
  }

  Resident getResidentById(String id) {
    return _residents.firstWhere(
      (resident) => resident.id == id,
      orElse: () => throw Exception('Resident not found'),
    );
  }
}
