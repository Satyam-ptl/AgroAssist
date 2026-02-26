/// WeatherData model - represents weather information
class WeatherData {
  final int id;
  final String location;  // City/area name
  final double temperature;  // Temperature in Celsius
  final double humidity;  // Humidity percentage
  final double rainfall;  // Rainfall in mm
  final String condition;  // Sunny, Cloudy, Rainy, Stormy
  final double windSpeed;  // Wind speed in km/h
  final DateTime recordedAt;  // When weather was recorded

  WeatherData({
    required this.id,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.condition,
    required this.windSpeed,
    required this.recordedAt,
  });

  /// Create WeatherData from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      id: _toInt(json['id']),
      location: _toStringValue(json['location']),
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      rainfall: _toDouble(json['rainfall']),
      condition: _toStringValue(json['condition']),
      windSpeed: _toDouble(json['wind_speed']),
      recordedAt: _toDateTime(json['recorded_at']),
    );
  }
}

/// FarmersWeatherAlert model - represents weather alerts for farmers
class FarmersWeatherAlert {
  final int id;
  final int farmerId;  // Foreign key to Farmer
  final String farmerName;  // Farmer's name
  final String severity;  // Low, Medium, High, Critical
  final String alertType;  // Rain, Frost, Heat, Wind, Disease, Pest
  final String message;  // Alert message
  final DateTime issuedAt;  // When alert was issued
  final DateTime? expiresAt;  // When alert expires
  final bool isRead;  // Whether farmer has read the alert
  final String? actionTaken;  // What action farmer took
  final bool? isActive;  // Calculated: whether alert is still active

  FarmersWeatherAlert({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.severity,
    required this.alertType,
    required this.message,
    required this.issuedAt,
    this.expiresAt,
    required this.isRead,
    this.actionTaken,
    this.isActive,
  });

  /// Create FarmersWeatherAlert from JSON
  factory FarmersWeatherAlert.fromJson(Map<String, dynamic> json) {
    return FarmersWeatherAlert(
      id: _toInt(json['id']),
      farmerId: _toInt(json['farmer']),
      farmerName: _toStringValue(json['farmer_name']),
      severity: _toStringValue(json['severity']),
      alertType: _toStringValue(json['alert_type']),
      message: _toStringValue(json['alert_message'] ?? json['message']),
      issuedAt: _toDateTime(json['issued_at']),
      expiresAt: json['expires_at'] != null
          ? _toDateTime(json['expires_at'])
          : null,
      isRead: _toBool(json['is_read']),
      actionTaken: (json['farmer_notes'] ?? json['action_taken'])?.toString(),
      isActive: json['is_active'] != null ? _toBool(json['is_active']) : null,
    );
  }
}

/// WeatherForecast model - represents weather forecast data
class WeatherForecast {
  final int id;
  final String location;  // City/area name
  final DateTime forecastDate;  // Date of forecast
  final double minTemperature;  // Minimum temperature in Celsius
  final double maxTemperature;  // Maximum temperature in Celsius
  final double rainfallProbability;  // Probability of rain (0-100%)
  final double expectedRainfallMm;  // Expected rainfall in mm
  final double humidity;  // Expected humidity percentage
  final String condition;  // Sunny, Cloudy, Rainy, Stormy
  final String? temperatureRange;  // Calculated: "20°C - 30°C"
  final String? rainfallDescription;  // Calculated: "Light rain expected"

  WeatherForecast({
    required this.id,
    required this.location,
    required this.forecastDate,
    required this.minTemperature,
    required this.maxTemperature,
    required this.rainfallProbability,
    required this.expectedRainfallMm,
    required this.humidity,
    required this.condition,
    this.temperatureRange,
    this.rainfallDescription,
  });

  /// Create WeatherForecast from JSON
  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      id: _toInt(json['id']),
      location: _toStringValue(json['location']),
      forecastDate: _toDateTime(json['forecast_date']),
      minTemperature: _toDouble(json['min_temperature']),
      maxTemperature: _toDouble(json['max_temperature']),
      rainfallProbability: _toDouble(json['rainfall_probability']),
      expectedRainfallMm: _toDouble(json['expected_rainfall_mm']),
      humidity: _toDouble(json['humidity']),
      condition: _toStringValue(json['condition']),
      temperatureRange: json['temperature_range']?.toString(),
      rainfallDescription: json['rainfall_description']?.toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

String _toStringValue(dynamic value) {
  return value?.toString() ?? '';
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
