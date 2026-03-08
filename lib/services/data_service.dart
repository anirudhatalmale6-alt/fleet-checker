import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/van_model.dart';
import '../models/inspection_model.dart';

class DataService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DataService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ─── Vans ───

  Stream<List<Van>> watchVansForOwner(String ownerId) {
    return _firestore
        .collection('vans')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Van.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Van>> watchVansForDriver(String driverId) {
    return _firestore
        .collection('vans')
        .where('assignedDriverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Van.fromMap(d.data(), d.id)).toList());
  }

  Future<Van?> getVanById(String id) async {
    final doc = await _firestore.collection('vans').doc(id).get();
    if (doc.exists) {
      return Van.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> addVan({
    required String registration,
    required String make,
    required String model,
    required int mileage,
    required String ownerId,
    String vehicleType = 'Van',
  }) async {
    await _firestore.collection('vans').add({
      'registration': registration.toUpperCase(),
      'make': make,
      'model': model,
      'mileage': mileage,
      'ownerId': ownerId,
      'vehicleType': vehicleType,
      'assignedDriverId': null,
      'assignedDriverName': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateVan(String vanId, Map<String, dynamic> data) async {
    await _firestore.collection('vans').doc(vanId).update(data);
  }

  Future<void> deleteVan(String id) async {
    await _firestore.collection('vans').doc(id).delete();
  }

  Future<void> assignDriver(
      String vanId, String? driverId, String? driverName) async {
    await _firestore.collection('vans').doc(vanId).update({
      'assignedDriverId': driverId,
      'assignedDriverName': driverName,
    });
  }

  // ─── Inspections ───

  Stream<List<Inspection>> watchInspectionsForOwner(String ownerId) {
    return _firestore
        .collection('inspections')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Inspection.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Inspection>> watchInspectionsForDriver(String driverId) {
    return _firestore
        .collection('inspections')
        .where('driverId', isEqualTo: driverId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Inspection.fromMap(d.data(), d.id)).toList());
  }

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
    List<String> localPhotoPaths = const [],
  }) async {
    // Upload photos if any
    final photoUrls = <String>[];
    for (final path in localPhotoPaths) {
      if (!kIsWeb) {
        final file = File(path);
        final ref = _storage.ref('inspections/$vanId/${DateTime.now().millisecondsSinceEpoch}_${photoUrls.length}.jpg');
        await ref.putFile(file);
        photoUrls.add(await ref.getDownloadURL());
      }
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
      'photoUrls': photoUrls,
      'status': status.name,
    });

    // Update van mileage
    await _firestore.collection('vans').doc(vanId).update({
      'mileage': mileage,
    });
  }
}
