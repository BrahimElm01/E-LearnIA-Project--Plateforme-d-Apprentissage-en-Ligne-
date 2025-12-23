class User {
  final int? id;
  final String fullName;
  final String email;
  final String role;
  final String? biography;
  final String? level;
  final String? goals;

  const User({
    this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.biography,
    this.level,
    this.goals,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      biography: json['biography'],
      level: json['level'],
      goals: json['goals'],
    );
  }
}
