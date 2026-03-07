enum CheckStatus { pass, fail, na }

class ChecklistItem {
  final String name;
  CheckStatus status;
  String? notes;

  ChecklistItem({
    required this.name,
    this.status = CheckStatus.pass,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status.name,
        'notes': notes,
      };
}

enum InspectionStatus { passed, failed }

class Inspection {
  final String id;
  final String vanId;
  final String vanRegistration;
  final String driverId;
  final String driverName;
  final DateTime date;
  final int mileage;
  final List<ChecklistItem> checklist;
  final String? generalNotes;
  final List<String> photoUrls;
  final InspectionStatus status;

  Inspection({
    required this.id,
    required this.vanId,
    required this.vanRegistration,
    required this.driverId,
    required this.driverName,
    required this.date,
    required this.mileage,
    required this.checklist,
    this.generalNotes,
    this.photoUrls = const [],
    required this.status,
  });

  int get passCount => checklist.where((c) => c.status == CheckStatus.pass).length;
  int get failCount => checklist.where((c) => c.status == CheckStatus.fail).length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'vanId': vanId,
        'vanRegistration': vanRegistration,
        'driverId': driverId,
        'driverName': driverName,
        'date': date.toIso8601String(),
        'mileage': mileage,
        'checklist': checklist.map((c) => c.toMap()).toList(),
        'generalNotes': generalNotes,
        'photoUrls': photoUrls,
        'status': status.name,
      };

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
}
