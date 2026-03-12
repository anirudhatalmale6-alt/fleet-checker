import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/van_model.dart';
import '../models/inspection_model.dart';
import '../models/accident_report_model.dart';
import 'data_service.dart';

class FirebaseDataService extends DataService {
  final FirebaseFirestore _firestore;

  FirebaseDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Van>> watchVansForOwner(String ownerId) {
    return _firestore
        .collection('vans')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final vans =
          snap.docs.map((d) => Van.fromMap(d.data(), d.id)).toList();
      vans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vans;
    });
  }

  @override
  Stream<List<Van>> watchVansForDriver(String driverId) {
    return _firestore
        .collection('vans')
        .where('assignedDriverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Van.fromMap(d.data(), d.id)).toList());
  }

  @override
  Future<Van?> getVanById(String id) async {
    final doc = await _firestore.collection('vans').doc(id).get();
    if (doc.exists) {
      return Van.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<void> addVan({
    required String registration,
    required String make,
    required String model,
    required int mileage,
    required String ownerId,
    String vehicleType = 'Van',
    int inspectionFrequencyDays = 1,
    List<String> customChecklist = const [],
  }) async {
    await _firestore.collection('vans').add({
      'registration': registration.toUpperCase(),
      'make': make,
      'model': model,
      'mileage': mileage,
      'ownerId': ownerId,
      'vehicleType': vehicleType,
      'inspectionFrequencyDays': inspectionFrequencyDays,
      'customChecklist': customChecklist,
      'assignedDriverId': null,
      'assignedDriverName': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateVan(String vanId, Map<String, dynamic> data) async {
    await _firestore.collection('vans').doc(vanId).update(data);
  }

  @override
  Future<void> deleteVan(String id) async {
    await _firestore.collection('vans').doc(id).delete();
  }

  @override
  Future<void> assignDriver(
      String vanId, String? driverId, String? driverName) async {
    await _firestore.collection('vans').doc(vanId).update({
      'assignedDriverId': driverId,
      'assignedDriverName': driverName,
    });
  }

  @override
  Stream<List<Inspection>> watchInspectionsForOwner(String ownerId) {
    return _firestore
        .collection('inspections')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Inspection.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Stream<List<Inspection>> watchInspectionsForDriver(String driverId) {
    return _firestore
        .collection('inspections')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Inspection.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
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
  }) async {
    // Store photos as base64 directly in Firestore (no Firebase Storage needed)
    final photoData = <String>[];
    for (final bytes in photoBytes) {
      photoData.add(base64Encode(bytes));
    }

    for (final item in checklist) {
      final itemBytes = itemPhotoBytes[item.name];
      if (itemBytes != null && itemBytes.isNotEmpty) {
        final encoded = <String>[];
        for (final bytes in itemBytes) {
          encoded.add(base64Encode(bytes));
        }
        item.photoUrls = encoded;
      }
    }

    String? signatureData;
    if (signatureBytes != null) {
      signatureData = base64Encode(signatureBytes);
    }

    await _firestore.collection('inspections').add({
      'vanId': vanId,
      'vanRegistration': vanRegistration,
      'driverId': driverId,
      'driverName': driverName,
      'ownerId': ownerId,
      'date': Timestamp.now(),
      'mileage': mileage,
      'checklist': checklist.map((c) => c.toMap()).toList(),
      'generalNotes': generalNotes,
      'photoUrls': photoData,
      'signatureUrl': signatureData,
      'status': status.name,
    });

    await _firestore.collection('vans').doc(vanId).update({
      'mileage': mileage,
    });
  }

  @override
  Stream<List<AccidentReport>> watchAccidentReportsForOwner(String ownerId) {
    return _firestore
        .collection('accident_reports')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AccidentReport.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Stream<List<AccidentReport>> watchAccidentReportsForDriver(String driverId) {
    return _firestore
        .collection('accident_reports')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AccidentReport.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
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
  }) async {
    final photoData = <String>[];
    for (final bytes in photoBytes) {
      photoData.add(base64Encode(bytes));
    }

    await _firestore.collection('accident_reports').add({
      'vanId': vanId,
      'vanRegistration': vanRegistration,
      'driverId': driverId,
      'driverName': driverName,
      'ownerId': ownerId,
      'date': Timestamp.now(),
      'location': location,
      'description': description,
      'severity': severity.name,
      'status': AccidentStatus.reported.name,
      'photoUrls': photoData,
      'thirdPartyName': thirdPartyName,
      'thirdPartyPhone': thirdPartyPhone,
      'thirdPartyVehicle': thirdPartyVehicle,
      'thirdPartyInsurance': thirdPartyInsurance,
      'witnessDetails': witnessDetails,
      'notes': notes,
    });
  }

  @override
  Future<void> updateAccidentReport(
      String reportId, Map<String, dynamic> data) async {
    await _firestore.collection('accident_reports').doc(reportId).update(data);
  }
}
