import 'dart:convert';  // For JSON encoding/decoding
import 'package:http/http.dart' as http;  // HTTP client for API calls

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// API Service class to handle all Django backend communication
/// This class provides methods to interact with your Django REST API
class ApiService {
  // Base URL of your Django backend API.
  // Override using --dart-define=API_BASE_URL=<url> for local or staging builds.
  static final String baseUrl = _normalizeApiBaseUrl(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://agroassist-backend-api.vercel.app/api',
    ),
  );

  static String _normalizeApiBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'https://agroassist-backend-api.vercel.app/api';
    }

    final noTrailingSlash = trimmed.replaceAll(RegExp(r'/+$'), '');
    if (noTrailingSlash.endsWith('/api')) {
      return noTrailingSlash;
    }

    return '$noTrailingSlash/api';
  }

  // HTTP headers for JSON communication
  static final Map<String, String> headers = {
    'Content-Type': 'application/json',  // Tell server we send JSON
    'Accept': 'application/json',  // Tell server we expect JSON response
  };

  static void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      headers.remove('Authorization');
      return;
    }
    headers['Authorization'] = 'Token $token';
  }

  static Never _throwApiError(String fallbackMessage, http.Response response) {
    String parsedMessage = fallbackMessage;

    try {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          parsedMessage = detail.toString().trim();
        } else {
          final parts = <String>[];
          decoded.forEach((_, value) {
            if (value is List) {
              for (final item in value) {
                final text = item.toString().trim();
                if (text.isNotEmpty) parts.add(text);
              }
            } else {
              final text = value.toString().trim();
              if (text.isNotEmpty) parts.add(text);
            }
          });
          if (parts.isNotEmpty) {
            parsedMessage = parts.join(' ');
          }
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        parsedMessage = decoded.map((e) => e.toString()).join(' ');
      }
    } catch (_) {
      final body = response.body.trim();
      if (body.isNotEmpty && body.length < 220) {
        parsedMessage = body;
      }
    }

    throw ApiException(parsedMessage);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: headers,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }
      _throwApiError('Login failed. Please check username/password.', response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException('Unable to login. Please check your internet connection.');
    }
  }

  static Future<Map<String, dynamic>> registerFarmer(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }
      _throwApiError('Signup failed. Please verify details and try again.', response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException('Unable to create account. Please check your internet connection.');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }
      throw Exception('Failed to fetch current user: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching current user: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout/'),
        headers: headers,
      );
    } catch (_) {}
  }

  // ==================== CROPS API METHODS ====================

  /// Get list of all crops with optional filtering
  /// [season] - Filter by season (Kharif, Rabi, Summer)
  /// [pageSize] - Number of results per page (default: 20)
  static Future<Map<String, dynamic>> getCrops({
    String? category,
    String? cropType,
    String? season,
    String? soilType,
    String? state,
    String? search,
    int pageSize = 20,
  }) async {
    try {
      // Build query parameters
      String url = '$baseUrl/crops/?page_size=$pageSize';
      if (season != null && season.isNotEmpty) {
        url += '&season=${Uri.encodeQueryComponent(season)}';  // Add season filter if provided
      }
      if (category != null && category.isNotEmpty) {
        url += '&category=${Uri.encodeQueryComponent(category)}';
      }
      if (cropType != null && cropType.isNotEmpty) {
        url += '&crop_type=${Uri.encodeQueryComponent(cropType)}';
      }
      if (soilType != null && soilType.isNotEmpty) {
        url += '&soil_type=${Uri.encodeQueryComponent(soilType)}';
      }
      if (state != null && state.isNotEmpty) {
        url += '&state=${Uri.encodeQueryComponent(state.trim())}';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeQueryComponent(search.trim())}';
      }

      // Make GET request to Django API
      final response = await http.get(Uri.parse(url), headers: headers);

      // Check if request was successful (status code 200)
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);  // Parse JSON and return
      } else {
        throw Exception('Failed to load crops: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching crops: $e');
    }
  }

  /// Get detailed information about a specific crop
  /// [cropId] - ID of the crop to retrieve
  static Future<Map<String, dynamic>> getCropDetail(int cropId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/crops/$cropId/details/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to load crop details');
      }
    } catch (e) {
      throw Exception('Error fetching crop details: $e');
    }
  }

  static Future<Map<String, dynamic>> createCrop(Map<String, dynamic> cropData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/crops/'),
        headers: headers,
        body: json.encode(cropData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }

      _throwApiError('Failed to create crop.', response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to create crop. Please check your connection.');
    }
  }

  static Future<Map<String, dynamic>> updateCrop(int cropId, Map<String, dynamic> cropData) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/crops/$cropId/'),
        headers: headers,
        body: json.encode(cropData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }

      _throwApiError('Failed to update crop.', response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to update crop. Please check your connection.');
    }
  }

  static Future<void> deleteCrop(int cropId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/crops/$cropId/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return;
      }

      _throwApiError('Failed to delete crop.', response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to delete crop. Please check your connection.');
    }
  }

  /// Get crop recommendations based on season
  /// [season] - Season to get recommendations for (Kharif, Rabi, Summer)
  static Future<List<dynamic>> getCropRecommendations(String season, {String? soilType, String? state}) async {
    try {
      String url = '$baseUrl/crops/recommendations/?season=${Uri.encodeQueryComponent(season)}';
      if (soilType != null && soilType.isNotEmpty && soilType != 'All') {
        url += '&soil_type=${Uri.encodeQueryComponent(soilType)}';
      }
      if (state != null && state.isNotEmpty) {
        url += '&state=${Uri.encodeQueryComponent(state.trim())}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body) as Map);
        return List<dynamic>.from((data['results'] as List<dynamic>?) ?? const []);  // Return list of recommended crops
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      throw Exception('Error fetching recommendations: $e');
    }
  }

  /// Get crop guide for a specific crop
  /// [cropId] - ID of the crop
  static Future<Map<String, dynamic>> getCropGuide(int cropId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/crop-guides/for_crop/?crop_id=$cropId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to load crop guide');
      }
    } catch (e) {
      throw Exception('Error fetching crop guide: $e');
    }
  }

  // ==================== FARMERS API METHODS ====================

  /// Get list of all farmers with optional filtering
  /// [city] - Filter by city
  /// [experience] - Filter by experience level (Beginner, Intermediate, Expert)
  static Future<Map<String, dynamic>> getFarmers({
    String? city,
    String? experience,
    int pageSize = 20,
  }) async {
    try {
      String url = '$baseUrl/farmers/?page_size=$pageSize';
      
      if (city != null && city.isNotEmpty) {
        url += '&city=$city';
      }
      if (experience != null && experience.isNotEmpty) {
        url += '&experience_level=$experience';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to load farmers');
      }
    } catch (e) {
      throw Exception('Error fetching farmers: $e');
    }
  }

  /// Get detailed information about a specific farmer
  /// [farmerId] - ID of the farmer
  static Future<Map<String, dynamic>> getFarmerDetail(int farmerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/farmers/$farmerId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to load farmer details');
      }
    } catch (e) {
      throw Exception('Error fetching farmer details: $e');
    }
  }

  static Future<Map<String, dynamic>> getFarmerCrops({
    int? farmerId,
    int pageSize = 20,
  }) async {
    try {
      String url = '$baseUrl/farmer-crops/?page_size=$pageSize';
      if (farmerId != null) {
        url += '&farmer=$farmerId';
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }
      throw Exception('Failed to load farmer crops: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching farmer crops: $e');
    }
  }

  static Future<Map<String, dynamic>> createFarmerCrop(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farmer-crops/'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      }
      throw Exception('Failed to create farmer crop: ${response.body}');
    } catch (e) {
      throw Exception('Error creating farmer crop: $e');
    }
  }

  /// Create a new farmer
  /// [farmerData] - Map containing farmer information
  static Future<Map<String, dynamic>> createFarmer(
      Map<String, dynamic> farmerData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farmers/'),
        headers: headers,
        body: json.encode(farmerData),  // Convert Map to JSON string
      );

      if (response.statusCode == 201) {  // 201 = Created
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to create farmer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating farmer: $e');
    }
  }

  /// Update farmer information
  /// [farmerId] - ID of the farmer to update
  /// [farmerData] - Map containing updated farmer information
  static Future<Map<String, dynamic>> updateFarmer(
      int farmerId, Map<String, dynamic> farmerData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/farmers/$farmerId/'),
        headers: headers,
        body: json.encode(farmerData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to update farmer');
      }
    } catch (e) {
      throw Exception('Error updating farmer: $e');
    }
  }

  static Future<void> deleteFarmer(int farmerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/farmers/$farmerId/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return;
      }

      _throwApiError('Failed to delete farmer.', response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to delete farmer. Please check your connection.');
    }
  }

  // ==================== TASKS API METHODS ====================

  /// Get list of tasks for a farmer
  /// [farmerId] - ID of the farmer
  /// [status] - Filter by status (Pending, In Progress, Completed, Overdue, Cancelled)
  static Future<Map<String, dynamic>> getTasks({
    int? farmerId,
    String? status,
    int pageSize = 20,
  }) async {
    try {
      String url = '$baseUrl/tasks/?page_size=$pageSize';
      
      if (farmerId != null) {
        url += '&farmer=$farmerId';
      }
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  /// Create a new task
  /// [taskData] - Map containing task information
  static Future<Map<String, dynamic>> createTask(
      Map<String, dynamic> taskData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: headers,
        body: json.encode(taskData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to create task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  /// Update task status
  /// [taskId] - ID of the task
  /// [status] - New status
  static Future<Map<String, dynamic>> updateTaskStatus(
      int taskId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/'),
        headers: headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to update task status');
      }
    } catch (e) {
      throw Exception('Error updating task status: $e');
    }
  }

  // ==================== WEATHER API METHODS ====================

  /// Get weather data for a location
  /// [location] - Location name (e.g., "Pune", "Mumbai")
  static Future<Map<String, dynamic>> getWeatherData(String location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather-data/?location=$location'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body) as Map);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  /// Get list of weather data records (optionally filtered by location)
  static Future<List<dynamic>> getWeatherDataList({String? location, int pageSize = 20}) async {
    try {
      String url = '$baseUrl/weather-data/?page_size=$pageSize';
      if (location != null && location.isNotEmpty) {
        url += '&location=$location';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body) as Map);
        return List<dynamic>.from((data['results'] as List<dynamic>?) ?? const []);
      } else {
        throw Exception('Failed to load weather data list');
      }
    } catch (e) {
      throw Exception('Error fetching weather data list: $e');
    }
  }

  /// Get weather alerts for a farmer
  /// [farmerId] - ID of the farmer
  static Future<List<dynamic>> getWeatherAlerts(int farmerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather-alerts/?farmer=$farmerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body) as Map);
        return List<dynamic>.from((data['results'] as List<dynamic>?) ?? const []);
      } else {
        throw Exception('Failed to load weather alerts');
      }
    } catch (e) {
      throw Exception('Error fetching weather alerts: $e');
    }
  }

  /// Get all weather alerts
  /// [pageSize] - Number of alerts to fetch
  static Future<List<dynamic>> getAllWeatherAlerts({int pageSize = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather-alerts/?page_size=$pageSize'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body) as Map);
        return List<dynamic>.from((data['results'] as List<dynamic>?) ?? const []);
      } else {
        throw Exception('Failed to load weather alerts');
      }
    } catch (e) {
      throw Exception('Error fetching weather alerts: $e');
    }
  }

  /// Get weather forecast for a location
  /// [location] - Location name
  /// [days] - Number of days to forecast (default: 7)
  static Future<List<dynamic>> getWeatherForecast(
      String location, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather-forecast/?location=$location&days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body) as Map);
        return List<dynamic>.from((data['results'] as List<dynamic>?) ?? const []);
      } else {
        throw Exception('Failed to load weather forecast');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }
}
