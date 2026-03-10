import 'package:cloud_firestore/cloud_firestore.dart';

class Van {
  final String id;
  String registration;
  String make;
  String model;
  int mileage;
  String? assignedDriverId;
  String? assignedDriverName;
  final String ownerId;
  String vehicleType;
  int inspectionFrequencyDays;
  final DateTime createdAt;

  Van({
    required this.id,
    required this.registration,
    required this.make,
    required this.model,
    required this.mileage,
    this.assignedDriverId,
    this.assignedDriverName,
    required this.ownerId,
    this.vehicleType = 'Van',
    this.inspectionFrequencyDays = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => '$make $model ($registration)';

  Map<String, dynamic> toMap() => {
        'registration': registration,
        'make': make,
        'model': model,
        'mileage': mileage,
        'assignedDriverId': assignedDriverId,
        'assignedDriverName': assignedDriverName,
        'ownerId': ownerId,
        'vehicleType': vehicleType,
        'inspectionFrequencyDays': inspectionFrequencyDays,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Van.fromMap(Map<String, dynamic> map, String id) {
    return Van(
      id: id,
      registration: map['registration'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      mileage: map['mileage'] ?? 0,
      assignedDriverId: map['assignedDriverId'],
      assignedDriverName: map['assignedDriverName'],
      ownerId: map['ownerId'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Van',
      inspectionFrequencyDays: map['inspectionFrequencyDays'] ?? 1,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
