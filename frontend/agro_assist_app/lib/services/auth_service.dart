import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthSession {
  final String token;
  final int userId;
  final String username;
  final String role;
  final int? farmerId;
  final String fullName;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
    required this.role,
    required this.farmerId,
    required this.fullName,
  });

  bool get isAdmin => role == 'admin';
  bool get isFarmer => role == 'farmer';
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _usernameKey = 'auth_username';
  static const _roleKey = 'auth_role';
  static const _farmerIdKey = 'auth_farmer_id';
  static const _fullNameKey = 'auth_full_name';

  static AuthSession? _session;
  static AuthSession? get session => _session;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      _session = null;
      ApiService.setAuthToken(null);
      return;
    }

    _session = AuthSession(
      token: token,
      userId: prefs.getInt(_userIdKey) ?? 0,
      username: prefs.getString(_usernameKey) ?? '',
      role: prefs.getString(_roleKey) ?? 'farmer',
      farmerId: prefs.getInt(_farmerIdKey),
      fullName: prefs.getString(_fullNameKey) ?? '',
    );
    ApiService.setAuthToken(token);

    try {
      final currentUser = await ApiService.getCurrentUser();
      await _saveSessionFromPayload(currentUser, tokenOverride: token);
    } catch (error) {
      if (_isUnauthorizedError(error)) {
        await logout();
      }
    }
  }

  static bool _isUnauthorizedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('forbidden') ||
        message.contains('invalid token') ||
        message.contains('token not valid');
  }

  static Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final payload = await ApiService.login(username: username, password: password);
    return _saveSessionFromPayload(payload);
  }

  static Future<AuthSession> registerFarmer(Map<String, dynamic> payload) async {
    final response = await ApiService.registerFarmer(payload);
    return _saveSessionFromPayload(response);
  }

  static Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_farmerIdKey);
    await prefs.remove(_fullNameKey);

    _session = null;
    ApiService.setAuthToken(null);
  }

  static Future<AuthSession> _saveSessionFromPayload(
    Map<String, dynamic> payload, {
    String? tokenOverride,
  }) async {
    final token = tokenOverride ?? payload['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Missing auth token in response.');
    }

    final userId = (payload['user_id'] as num?)?.toInt() ?? 0;
    final username = payload['username']?.toString() ?? '';
    final role = payload['role']?.toString() ?? 'farmer';
    final farmerId = (payload['farmer_id'] as num?)?.toInt();
    final fullName = payload['full_name']?.toString() ?? username;

    final authSession = AuthSession(
      token: token,
      userId: userId,
      username: username,
      role: role,
      farmerId: farmerId,
      fullName: fullName,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_roleKey, role);
    if (farmerId != null) {
      await prefs.setInt(_farmerIdKey, farmerId);
    } else {
      await prefs.remove(_farmerIdKey);
    }
    await prefs.setString(_fullNameKey, fullName);

    _session = authSession;
    ApiService.setAuthToken(token);
    return authSession;
  }
}
