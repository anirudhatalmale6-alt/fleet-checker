enum UserRole { owner, driver }

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? ownerId; // For drivers, links to their owner
  final String? companyName; // For owners

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.ownerId,
    this.companyName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'ownerId': ownerId,
        'companyName': companyName,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'],
        email: map['email'],
        name: map['name'],
        role: UserRole.values.byName(map['role']),
        ownerId: map['ownerId'],
        companyName: map['companyName'],
      );
}
