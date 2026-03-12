import 'package:cloud_firestore/cloud_firestore.dart';

enum AccidentSeverity { minor, moderate, major }

enum AccidentStatus { reported, inProgress, resolved }

class AccidentReport {
  final String id;
  final String vanId;
  final String vanRegistration;
  final String driverId;
  final String driverName;
  final String? ownerId;
  final DateTime date;
  final String location;
  final String description;
  final AccidentSeverity severity;
  final AccidentStatus status;
  final List<String> photoUrls;
  final String? thirdPartyName;
  final String? thirdPartyPhone;
  final String? thirdPartyVehicle;
  final String? thirdPartyInsurance;
  final String? witnessDetails;
  final String? insuranceRef;
  final String? notes;

  AccidentReport({
    required this.id,
    required this.vanId,
    required this.vanRegistration,
    required this.driverId,
    required this.driverName,
    this.ownerId,
    required this.date,
    required this.location,
    required this.description,
    required this.severity,
    this.status = AccidentStatus.reported,
    this.photoUrls = const [],
    this.thirdPartyName,
    this.thirdPartyPhone,
    this.thirdPartyVehicle,
    this.thirdPartyInsurance,
    this.witnessDetails,
    this.insuranceRef,
    this.notes,
  });

  String get severityLabel {
    switch (severity) {
      case AccidentSeverity.minor:
        return 'Minor';
      case AccidentSeverity.moderate:
        return 'Moderate';
      case AccidentSeverity.major:
        return 'Major';
    }
  }

  String get statusLabel {
    switch (status) {
      case AccidentStatus.reported:
        return 'Reported';
      case AccidentStatus.inProgress:
        return 'In Progress';
      case AccidentStatus.resolved:
        return 'Resolved';
    }
  }

  Map<String, dynamic> toMap() => {
        'vanId': vanId,
        'vanRegistration': vanRegistration,
        'driverId': driverId,
        'driverName': driverName,
        'ownerId': ownerId,
        'date': Timestamp.fromDate(date),
        'location': location,
        'description': description,
        'severity': severity.name,
        'status': status.name,
        'photoUrls': photoUrls,
        'thirdPartyName': thirdPartyName,
        'thirdPartyPhone': thirdPartyPhone,
        'thirdPartyVehicle': thirdPartyVehicle,
        'thirdPartyInsurance': thirdPartyInsurance,
        'witnessDetails': witnessDetails,
        'insuranceRef': insuranceRef,
        'notes': notes,
      };

  factory AccidentReport.fromMap(Map<String, dynamic> map, String id) {
    return AccidentReport(
      id: id,
      vanId: map['vanId'] ?? '',
      vanRegistration: map['vanRegistration'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      ownerId: map['ownerId'],
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      severity:
          AccidentSeverity.values.byName(map['severity'] ?? 'minor'),
      status:
          AccidentStatus.values.byName(map['status'] ?? 'reported'),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      thirdPartyName: map['thirdPartyName'],
      thirdPartyPhone: map['thirdPartyPhone'],
      thirdPartyVehicle: map['thirdPartyVehicle'],
      thirdPartyInsurance: map['thirdPartyInsurance'],
      witnessDetails: map['witnessDetails'],
      insuranceRef: map['insuranceRef'],
      notes: map['notes'],
    );
  }
}
