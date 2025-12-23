import 'dart:convert';

import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';

import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  // 🔗 Utilise la configuration centralisée
  static String get _baseUrl => ApiConfig.baseUrl;

  // 🔐 clés pour le stockage sécurisé
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ================== REGISTER ==================

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role, // 'LEARNER' ou 'TEACHER'
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    final body = jsonEncode({
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Erreur d’inscription (${response.statusCode}) : ${response.body}');
    }

    // Le backend renvoie AuthResponse { token, fullName, email, role }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Réponse invalide : token manquant');
    }

    // ✅ on stocke token + email + password (pour login biométrique)
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }
  // ================== TOKEN (pour les autres services) ==================

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // ================== LOGIN CLASSIQUE ==================

  Future<void> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur de connexion (${response.statusCode}) : ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Réponse invalide : token manquant');
    }

    // ✅ on met à jour le token + email + password
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  // ================== /auth/me ==================

  Future<User> getCurrentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception('Aucun token trouvé, reconnecte-toi');
    }

    final uri = Uri.parse('$_baseUrl/auth/me');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Impossible de récupérer l’utilisateur (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  /// Optionnel : si tu veux l’utiliser plus tard au démarrage
  Future<User?> tryAutoLogin() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;
      return await getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  // ================== BIOMÉTRIE ==================

  /// Vérifie si l’appareil supporte Face ID / empreinte
  /// 👉 NE vérifie PAS le token pour que le bouton reste visible même après logout
  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('canUseBiometrics error: $e');
      return false;
    }
  }

  /// Login via Face ID / empreinte
  ///
  /// Retourne true si la connexion a réussi.
  Future<bool> loginWithBiometrics() async {
    final canUse = await canUseBiometrics();
    if (!canUse) return false;

    // On vérifie d’abord la biométrie
    bool didAuthenticate = false;
    try {
      didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Connecte-toi avec Face ID / empreinte',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('local_auth error: $e');
      return false;
    }

    if (!didAuthenticate) return false;

    // Puis on utilise les identifiants stockés
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);

    if (email == null || password == null) {
      debugPrint(
          'Pas d’email/mot de passe stockés. Faire un login classique au moins une fois.');
      return false;
    }

    try {
      await login(email, password);
      return true;
    } catch (e) {
      debugPrint('loginWithBiometrics -> login error: $e');
      return false;
    }
  }

  // ================== LOGOUT ==================

  Future<void> logout() async {
    // On supprime seulement le token pour fermer la session.
    // On garde email + password pour permettre le login biométrique après logout.
    await _storage.delete(key: _tokenKey);
  }
  // ================== COMPATIBILITÉ ANCIEN CODE ==================
  /// Ancien nom utilisé dans HomeScreen / TeacherHomeScreen.
  /// On le garde pour éviter les erreurs : il appelle simplement logout().
  Future<void> clearToken() => logout();
}


