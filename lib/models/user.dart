class User {
  final String id;
  final String? name;
  final String phone;
  final String? email;
  final String? role;
  final String? avatarUrl;

  const User({
    required this.id,
    this.name,
    required this.phone,
    this.email,
    this.role,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'],
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
