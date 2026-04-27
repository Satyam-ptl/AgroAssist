import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthSession {
  final String token;
  final int userId;
  final String username;
  final bool isAdmin;
  final String email;
  final int? farmerId;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
    required this.isAdmin,
    required this.email,
    required this.farmerId,
  });
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _usernameKey = 'auth_username';
  static const _isAdminKey = 'auth_is_admin';
  static const _emailKey = 'auth_email';
  static const _farmerIdKey = 'auth_farmer_id';

  static AuthSession? _session;
  static AuthSession? get session => _session;

  static bool get isLoggedIn => _session != null;
  static bool get isAdmin => _session?.isAdmin ?? false;
  static bool get isFarmer => _session != null && !(_session!.isAdmin);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // FIX: If no token stored, just set null and return
    // Do NOT call getCurrentUser() here — that was causing
    // session to drop whenever /api/auth/me/ returned 403
    if (token == null || token.isEmpty) {
      _session = null;
      ApiService.setAuthToken(null);
      return;
    }

    // FIX: Restore session from stored prefs WITHOUT
    // making any API call. Token is valid until logout.
    final restored = AuthSession(
      token: token,
      userId: prefs.getInt(_userIdKey) ?? 0,
      username: prefs.getString(_usernameKey) ?? '',
      isAdmin: prefs.getBool(_isAdminKey) ?? false,
      email: prefs.getString(_emailKey) ?? '',
      farmerId: prefs.getInt(_farmerIdKey),
    );

    _session = restored;
    ApiService.setAuthToken(token);

    // FIX: Removed getCurrentUser() call that was causing
    // automatic logout when /api/auth/me/ returned 403
  }

  static Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final payload = await ApiService.login(
      username: username,
      password: password,
    );
    return _saveFromPayload(payload);
  }

  static Future<AuthSession> registerFarmer(
      Map<String, dynamic> payload) async {
    final response = await ApiService.registerFarmer(payload);
    return _saveFromPayload(response);
  }

  static Future<void> logout() async {
    // FIX: Try logout but never throw — always clear local session
    try {
      await ApiService.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_farmerIdKey);

    _session = null;
    ApiService.setAuthToken(null);
  }

  static Future<AuthSession> _saveFromPayload(
    Map<String, dynamic> payload, {
    String? tokenOverride,
  }) async {
    final token =
        tokenOverride ?? payload['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Missing auth token in response');
    }

    final userId = (payload['user_id'] as num?)?.toInt() ??
        (payload['id'] as num?)?.toInt() ??
        0;
    final username = payload['username']?.toString() ?? '';
    final isAdmin = (payload['is_admin'] as bool?) ??
        (payload['is_staff'] as bool?) ??
        false;
    final email = payload['email']?.toString() ?? '';
    final farmerId = (payload['farmer_id'] as num?)?.toInt();

    final nextSession = AuthSession(
      token: token,
      userId: userId,
      username: username,
      isAdmin: isAdmin,
      email: email,
      farmerId: farmerId,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setBool(_isAdminKey, isAdmin);
    await prefs.setString(_emailKey, email);
    if (farmerId != null) {
      await prefs.setInt(_farmerIdKey, farmerId);
    } else {
      await prefs.remove(_farmerIdKey);
    }

    _session = nextSession;
    ApiService.setAuthToken(token);
    return nextSession;
  }
}