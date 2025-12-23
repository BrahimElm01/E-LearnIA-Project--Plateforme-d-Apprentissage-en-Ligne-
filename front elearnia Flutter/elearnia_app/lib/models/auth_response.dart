class AuthResponse {
  final String token;
  final String fullName;
  final String email;
  final String role;

  const AuthResponse({
    required this.token,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
