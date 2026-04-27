import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final String baseUrl = _normalizeApiBaseUrl(
    () {
      const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
      if (configuredBaseUrl.trim().isNotEmpty) {
        return configuredBaseUrl;
      }
      // Default to deployed backend for web and mobile.
      // Use --dart-define=API_BASE_URL=... when you want a local backend.
      if (kIsWeb) {
        return 'https://backend-one-kohl-70.vercel.app/api';
      }
      return 'https://backend-one-kohl-70.vercel.app/api';
    }(),
  );

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String _normalizeApiBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'https://agroassist-backend-api.vercel.app/api';
    }
    final noSlash = trimmed.replaceAll(RegExp(r'/+$'), '');
    if (noSlash.endsWith('/api')) {
      return noSlash;
    }
    return '$noSlash/api';
  }

  static void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _headers.remove('Authorization');
      return;
    }
    _headers['Authorization'] = 'Token $token';
  }

  static Future<void> _ensureConnected() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      throw const ApiException('No internet connection. Please check your network.');
    }
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl/$path').replace(queryParameters: query);
  }

  static Never _throwParsedError(http.Response response, String fallback) {
    String message = fallback;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['error'] != null) {
          message = decoded['error'].toString();
        } else if (decoded['detail'] != null) {
          message = decoded['detail'].toString();
        } else {
          final parts = <String>[];
          decoded.forEach((key, value) {
            if (value is List) {
              for (final item in value) {
                parts.add(item.toString());
              }
            } else {
              parts.add(value.toString());
            }
          });
          if (parts.isNotEmpty) {
            message = parts.join(' ');
          }
        }
      }
    } catch (_) {}

    throw ApiException('${response.statusCode}: $message');
  }

  static Future<http.Response> _get(String path, [Map<String, String>? query]) async {
    await _ensureConnected();
    try {
      return await http.get(_uri(path, query), headers: _headers);
    } on SocketException {
      throw const ApiException('Unable to reach server. Check your connection.');
    }
  }

  static Future<http.Response> _post(String path, Object body) async {
    await _ensureConnected();
    try {
      return await http.post(_uri(path), headers: _headers, body: json.encode(body));
    } on SocketException {
      throw const ApiException('Unable to reach server. Check your connection.');
    }
  }

  static Future<http.Response> _patch(String path, Object body) async {
    await _ensureConnected();
    try {
      return await http.patch(_uri(path), headers: _headers, body: json.encode(body));
    } on SocketException {
      throw const ApiException('Unable to reach server. Check your connection.');
    }
  }

  static Future<http.Response> _delete(String path) async {
    await _ensureConnected();
    try {
      return await http.delete(_uri(path), headers: _headers);
    } on SocketException {
      throw const ApiException('Unable to reach server. Check your connection.');
    }
  }

  static Map<String, dynamic> _asMap(http.Response response) {
    return Map<String, dynamic>.from(json.decode(response.body) as Map);
  }

  static List<dynamic> _asList(http.Response response) {
    return List<dynamic>.from(json.decode(response.body) as List);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _post('auth/login/', {
      'username': username,
      'password': password,
    });

    if (response.statusCode == 200) {
      return _asMap(response);
    }

    if (response.statusCode == 401) {
      _throwParsedError(response, 'Incorrect username or password.');
    }
    if (response.statusCode == 403) {
      _throwParsedError(response, 'Your account is inactive. Contact admin.');
    }
    _throwParsedError(response, 'Login failed.');
  }

  static Future<Map<String, dynamic>> registerFarmer(Map<String, dynamic> payload) async {
    final response = await _post('auth/register/', payload);
    if (response.statusCode == 201) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Signup failed.');
  }

  static Future<void> logout() async {
    try {
      await _post('auth/logout/', const {});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('auth/me/');
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to fetch current user.');
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _get('dashboard/stats/');
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to load dashboard stats.');
  }

  static Future<Map<String, dynamic>> getCrops({
    String? search,
    String? season,
    String? state,
    int page = 1,
    int pageSize = 100,
    bool forceRefresh = false,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (season != null && season.trim().isNotEmpty) {
      query['season'] = season.trim();
    }
    if (state != null && state.trim().isNotEmpty) {
      query['state'] = state.trim();
    }
    if (forceRefresh) {
      query['_'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final response = await _get('crops/', query);
    if (response.statusCode == 200) {
      final map = _asMap(response);
      map['results'] = List<dynamic>.from((map['results'] as List<dynamic>?) ?? const []);
      return map;
    }
    _throwParsedError(response, 'Failed to fetch crops.');
  }

  static Future<Map<String, dynamic>> getCropDetails(int id) async {
    final response = await _get('crops/$id/details/');
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to load crop details.');
  }

  static Future<Map<String, dynamic>> getCropSchedule(
    int cropId,
    String plantingDate,
  ) async {
    final response = await _get(
      'crops/$cropId/schedule/',
      {'planting_date': plantingDate},
    );
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to load crop schedule.');
  }

  static Future<Map<String, dynamic>> getCropAlerts(int cropId) async {
    final response = await _get('crops/$cropId/alerts/');
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to load crop alerts.');
  }

  static Future<List<String>> getCropSeasons() async {
    final response = await _get('crops/seasons/');
    if (response.statusCode == 200) {
      return _asList(response).map((e) => e.toString()).toList();
    }
    _throwParsedError(response, 'Failed to load crop seasons.');
  }

  static Future<List<String>> getCropStates() async {
    final response = await _get('crops/states/');
    if (response.statusCode == 200) {
      return _asList(response).map((e) => e.toString()).toList();
    }
    _throwParsedError(response, 'Failed to load crop states.');
  }

  static Future<Map<String, dynamic>> createCrop(Map<String, dynamic> payload) async {
    final response = await _post('crops/', payload);
    if (response.statusCode == 201) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to add crop.');
  }

  static Future<Map<String, dynamic>> updateCrop(int id, Map<String, dynamic> payload) async {
    final response = await _patch('crops/$id/', payload);
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to update crop.');
  }

  static Future<void> deleteCrop(int id) async {
    final response = await _delete('crops/$id/');
    if (response.statusCode == 204) {
      return;
    }
    _throwParsedError(response, 'Failed to delete crop.');
  }

  static Future<Map<String, dynamic>> getFarmers({
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _get('farmers/', query);
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to fetch farmers.');
  }

  static Future<void> deleteFarmer(int id) async {
    final response = await _delete('farmers/$id/');
    if (response.statusCode == 204) {
      return;
    }
    _throwParsedError(response, 'Failed to delete farmer.');
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _get('farmers/me/');
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to load profile.');
  }

  static Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data) async {
    final response = await _patch('farmers/me/', data);
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to update profile.');
  }

  static Future<Map<String, dynamic>> getTasks({
    String? status,
    int? farmerId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (farmerId != null) {
      query['farmer_id'] = '$farmerId';
    }

    final response = await _get('tasks/', query);
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to fetch tasks.');
  }

  static Future<Map<String, dynamic>> updateTaskStatus(int id, String status) async {
    final response = await _patch('tasks/$id/update-status/', {'status': status});
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to update task status.');
  }

  static Future<Map<String, dynamic>> sendReminder(Map<String, dynamic> payload) async {
    final response = await _post('tasks/send-reminder/', payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to send reminders.');
  }

  static Future<List<dynamic>> getMyReminders() async {
    final response = await _get('tasks/reminders/');
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return List<dynamic>.from(decoded);
      }
      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return List<dynamic>.from(decoded['results'] as List);
      }
      return <dynamic>[];
    }
    _throwParsedError(response, 'Failed to load reminders.');
  }

  static Future<List<dynamic>> getReminderHistory() async {
    final response = await _get('tasks/reminders-history/');
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return List<dynamic>.from(decoded);
      }
      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return List<dynamic>.from(decoded['results'] as List);
      }
      return <dynamic>[];
    }
    _throwParsedError(response, 'Failed to load reminder history.');
  }

  static Future<Map<String, dynamic>> getFarmerCrops({int pageSize = 100}) async {
    final response = await _get('farmer-crops/', {'page_size': '$pageSize'});
    if (response.statusCode == 200) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to fetch farmer crops.');
  }

  static Future<Map<String, dynamic>> addMyFarmerCrop({
    required int cropId,
    required String plantingDate,
    required double areaAllocatedHectares,
    String status = 'Growing',
    String? expectedHarvestDate,
  }) async {
    final payload = <String, dynamic>{
      'crop': cropId,
      'planting_date': plantingDate,
      'status': status,
      'area_allocated_hectares': areaAllocatedHectares,
    };
    if (expectedHarvestDate != null && expectedHarvestDate.isNotEmpty) {
      payload['expected_harvest_date'] = expectedHarvestDate;
    }

    final response = await _post('farmer-crops/', payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(response);
    }
    _throwParsedError(response, 'Failed to add crop for growing.');
  }

  static Future<List<dynamic>> getAllWeatherAlerts({int pageSize = 100}) async {
    final response = await _get('weather-alerts/', {'page_size': '$pageSize'});
    if (response.statusCode == 200) {
      final decoded = _asMap(response);
      return List<dynamic>.from((decoded['results'] as List<dynamic>?) ?? const []);
    }
    _throwParsedError(response, 'Failed to fetch weather alerts.');
  }

  static Future<List<dynamic>> getWeatherDataList({int pageSize = 20}) async {
    final response = await _get('weather-data/', {'page_size': '$pageSize'});
    if (response.statusCode == 200) {
      final decoded = _asMap(response);
      return List<dynamic>.from((decoded['results'] as List<dynamic>?) ?? const []);
    }
    _throwParsedError(response, 'Failed to fetch weather data.');
  }
}
