import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/van_model.dart';
import '../models/inspection_model.dart';
import 'data_service.dart';

class FirebaseDataService extends DataService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseDataService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

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

  // Storage uploads enabled (requires Firebase Blaze plan + Storage enabled)
  static const bool _storageEnabled = true;

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
    final photoUrls = <String>[];
    String? signatureUrl;

    // Only attempt uploads when Storage is enabled
    if (_storageEnabled) {
      try {
        for (final bytes in photoBytes) {
          final ref = _storage.ref(
              'inspections/$vanId/${DateTime.now().millisecondsSinceEpoch}_${photoUrls.length}.jpg');
          await ref.putData(
              bytes, SettableMetadata(contentType: 'image/jpeg'));
          photoUrls.add(await ref.getDownloadURL());
        }

        for (final item in checklist) {
          final itemBytes = itemPhotoBytes[item.name];
          if (itemBytes != null && itemBytes.isNotEmpty) {
            final urls = <String>[];
            for (final bytes in itemBytes) {
              final ref = _storage.ref(
                  'inspections/$vanId/items/${item.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg');
              await ref.putData(
                  bytes, SettableMetadata(contentType: 'image/jpeg'));
              urls.add(await ref.getDownloadURL());
            }
            item.photoUrls = urls;
          }
        }

        if (signatureBytes != null) {
          final sigRef = _storage.ref(
              'inspections/$vanId/signature_${DateTime.now().millisecondsSinceEpoch}.png');
          await sigRef.putData(
              signatureBytes, SettableMetadata(contentType: 'image/png'));
          signatureUrl = await sigRef.getDownloadURL();
        }
      } catch (e) {
        // Log storage error but continue saving inspection without photos
        print('Firebase Storage upload error: $e');
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
      'signatureUrl': signatureUrl,
      'status': status.name,
    });

    await _firestore.collection('vans').doc(vanId).update({
      'mileage': mileage,
    });
  }
}
