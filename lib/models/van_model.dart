class Van {
  final String id;
  String registration;
  String make;
  String model;
  int mileage;
  String? assignedDriverId;
  String? assignedDriverName;
  final String ownerId;
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => '$make $model ($registration)';

  Map<String, dynamic> toMap() => {
        'id': id,
        'registration': registration,
        'make': make,
        'model': model,
        'mileage': mileage,
        'assignedDriverId': assignedDriverId,
        'assignedDriverName': assignedDriverName,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
      };
}
