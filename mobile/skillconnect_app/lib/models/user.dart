class User {
  final int id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String location;
  final String? avatarUrl;
  final bool phoneVerified;
  final bool governmentIdVerified;
  final bool selfieVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.location,
    this.avatarUrl,
    this.phoneVerified = false,
    this.governmentIdVerified = false,
    this.selfieVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      location: json['location'] ?? '',
      avatarUrl: json['avatar_url'],
      phoneVerified: json['phone_verified'] == true || json['phone_verified'] == 1,
      governmentIdVerified: json['government_id_verified'] == true || json['government_id_verified'] == 1,
      selfieVerified: json['selfie_verified'] == true || json['selfie_verified'] == 1,
    );
  }

  bool get isProfessional => role == 'professional';
  bool get isVerified => phoneVerified || governmentIdVerified || selfieVerified;
}
