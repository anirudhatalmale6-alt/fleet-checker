import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckStatus { pass, fail, na }

class ChecklistItem {
  final String name;
  CheckStatus status;
  String? notes;
  List<String> photoUrls;

  ChecklistItem({
    required this.name,
    this.status = CheckStatus.pass,
    this.notes,
    this.photoUrls = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status.name,
        'notes': notes,
        'photoUrls': photoUrls,
      };

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      name: map['name'] ?? '',
      status: CheckStatus.values.byName(map['status'] ?? 'pass'),
      notes: map['notes'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
    );
  }
}

enum InspectionStatus { passed, failed }

class Inspection {
  final String id;
  final String vanId;
  final String vanRegistration;
  final String driverId;
  final String driverName;
  final String? ownerId;
  final DateTime date;
  final int mileage;
  final List<ChecklistItem> checklist;
  final String? generalNotes;
  final List<String> photoUrls;
  final String? signatureUrl;
  final InspectionStatus status;

  Inspection({
    required this.id,
    required this.vanId,
    required this.vanRegistration,
    required this.driverId,
    required this.driverName,
    this.ownerId,
    required this.date,
    required this.mileage,
    required this.checklist,
    this.generalNotes,
    this.photoUrls = const [],
    this.signatureUrl,
    required this.status,
  });

  int get passCount =>
      checklist.where((c) => c.status == CheckStatus.pass).length;
  int get failCount =>
      checklist.where((c) => c.status == CheckStatus.fail).length;

  Map<String, dynamic> toMap() => {
        'vanId': vanId,
        'vanRegistration': vanRegistration,
        'driverId': driverId,
        'driverName': driverName,
        'ownerId': ownerId,
        'date': Timestamp.fromDate(date),
        'mileage': mileage,
        'checklist': checklist.map((c) => c.toMap()).toList(),
        'generalNotes': generalNotes,
        'photoUrls': photoUrls,
        'signatureUrl': signatureUrl,
        'status': status.name,
      };

  factory Inspection.fromMap(Map<String, dynamic> map, String id) {
    return Inspection(
      id: id,
      vanId: map['vanId'] ?? '',
      vanRegistration: map['vanRegistration'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      ownerId: map['ownerId'],
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      mileage: map['mileage'] ?? 0,
      checklist: (map['checklist'] as List<dynamic>?)
              ?.map((c) => ChecklistItem.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      generalNotes: map['generalNotes'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      signatureUrl: map['signatureUrl'],
      status: InspectionStatus.values.byName(map['status'] ?? 'passed'),
    );
  }

  static List<ChecklistItem> defaultChecklist() => [
        ChecklistItem(name: 'Lights'),
        ChecklistItem(name: 'Tyres'),
        ChecklistItem(name: 'Mirrors'),
        ChecklistItem(name: 'Body Condition'),
        ChecklistItem(name: 'Windscreen'),
        ChecklistItem(name: 'Brakes'),
        ChecklistItem(name: 'Fluids'),
        ChecklistItem(name: 'Indicators'),
        ChecklistItem(name: 'Horn'),
        ChecklistItem(name: 'Seatbelt'),
      ];

  static List<ChecklistItem> checklistFromNames(List<String> names) {
    if (names.isEmpty) return defaultChecklist();
    return names.map((n) => ChecklistItem(name: n)).toList();
  }
}
