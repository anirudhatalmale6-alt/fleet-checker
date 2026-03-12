import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/van_model.dart';
import '../models/inspection_model.dart';
import '../models/accident_report_model.dart';

/// Abstract data service – screens depend on this type.
/// Concrete implementations: FirebaseDataService, MockDataService.
abstract class DataService extends ChangeNotifier {
  Stream<List<Van>> watchVansForOwner(String ownerId);
  Stream<List<Van>> watchVansForDriver(String driverId);
  Future<Van?> getVanById(String id);

  Future<void> addVan({
    required String registration,
    required String make,
    required String model,
    required int mileage,
    required String ownerId,
    String vehicleType = 'Van',
    int inspectionFrequencyDays = 1,
    List<String> customChecklist = const [],
  });

  Future<void> updateVan(String vanId, Map<String, dynamic> data);
  Future<void> deleteVan(String id);

  Future<void> assignDriver(
      String vanId, String? driverId, String? driverName);

  Stream<List<Inspection>> watchInspectionsForOwner(String ownerId);
  Stream<List<Inspection>> watchInspectionsForDriver(String driverId);

  Future<void> addInspection({
    required String vanId,
    required String vanRegistration,
    required String driverId,
    required String driverName,
    required String ownerId,
    required int mileage,
    required List<ChecklistItem> checklist,
    required InspectionStatus status,
    String? generalNotes,
    List<Uint8List> photoBytes = const [],
    Map<String, List<Uint8List>> itemPhotoBytes = const {},
    Uint8List? signatureBytes,
  });

  // Accident Reports
  Stream<List<AccidentReport>> watchAccidentReportsForOwner(String ownerId);
  Stream<List<AccidentReport>> watchAccidentReportsForDriver(String driverId);

  Future<void> addAccidentReport({
    required String vanId,
    required String vanRegistration,
    required String driverId,
    required String driverName,
    required String ownerId,
    required String location,
    required String description,
    required AccidentSeverity severity,
    List<Uint8List> photoBytes = const [],
    String? thirdPartyName,
    String? thirdPartyPhone,
    String? thirdPartyVehicle,
    String? thirdPartyInsurance,
    String? witnessDetails,
    String? notes,
  });

  Future<void> updateAccidentReport(String reportId, Map<String, dynamic> data);
}
