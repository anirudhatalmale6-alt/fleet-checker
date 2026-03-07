import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/van_model.dart';
import '../models/inspection_model.dart';

class DataService extends ChangeNotifier {
  final List<Van> _vans = [];
  final List<Inspection> _inspections = [];

  // --- Vans ---

  List<Van> getVansForOwner(String ownerId) =>
      _vans.where((v) => v.ownerId == ownerId).toList();

  List<Van> getVansForDriver(String driverId) =>
      _vans.where((v) => v.assignedDriverId == driverId).toList();

  Van? getVanById(String id) {
    try {
      return _vans.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  void addVan({
    required String registration,
    required String make,
    required String model,
    required int mileage,
    required String ownerId,
  }) {
    _vans.add(Van(
      id: const Uuid().v4(),
      registration: registration.toUpperCase(),
      make: make,
      model: model,
      mileage: mileage,
      ownerId: ownerId,
    ));
    notifyListeners();
  }

  void updateVan(Van van) {
    final idx = _vans.indexWhere((v) => v.id == van.id);
    if (idx != -1) {
      _vans[idx] = van;
      notifyListeners();
    }
  }

  void deleteVan(String id) {
    _vans.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  void assignDriver(String vanId, String? driverId, String? driverName) {
    final van = getVanById(vanId);
    if (van != null) {
      van.assignedDriverId = driverId;
      van.assignedDriverName = driverName;
      notifyListeners();
    }
  }

  // --- Inspections ---

  List<Inspection> getInspectionsForOwner(String ownerId) {
    final ownerVanIds = getVansForOwner(ownerId).map((v) => v.id).toSet();
    return _inspections.where((i) => ownerVanIds.contains(i.vanId)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Inspection> getInspectionsForDriver(String driverId) {
    return _inspections.where((i) => i.driverId == driverId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Inspection> getInspectionsForVan(String vanId) {
    return _inspections.where((i) => i.vanId == vanId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Inspection> getTodayInspections(String ownerId) {
    final today = DateTime.now();
    return getInspectionsForOwner(ownerId)
        .where((i) =>
            i.date.year == today.year &&
            i.date.month == today.month &&
            i.date.day == today.day)
        .toList();
  }

  List<Inspection> getFailedInspections(String ownerId) {
    return getInspectionsForOwner(ownerId)
        .where((i) => i.status == InspectionStatus.failed)
        .toList();
  }

  void addInspection(Inspection inspection) {
    _inspections.add(inspection);
    // Update van mileage
    final van = getVanById(inspection.vanId);
    if (van != null) {
      van.mileage = inspection.mileage;
    }
    notifyListeners();
  }
}
