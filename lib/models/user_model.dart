enum UserRole { deaf, caregiver }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? linkedUserEmail;
  final String? linkedUserId;
  final String linkStatus;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.linkedUserEmail,
    this.linkedUserId,
    this.linkStatus = 'none',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'caregiver' ? UserRole.caregiver : UserRole.deaf,
      linkedUserEmail: map['linkedUserEmail'],
      linkedUserId: map['linkedUserId'],
      linkStatus: map['linkStatus'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email.toLowerCase().trim(),
      'role': role.name,
      'linkedUserEmail': linkedUserEmail?.toLowerCase().trim(),
      'linkedUserId': linkedUserId,
      'linkStatus': linkStatus,
    };
  }
}
