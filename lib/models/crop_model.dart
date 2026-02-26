/// Crop model class - represents crop data from Django API
/// This matches the Crop model in your Django backend
class Crop {
  final int id;  // Unique identifier for the crop
  final String name;  // Crop name (e.g., "Rice", "Wheat")
  final String season;  // Growing season (Kharif, Rabi, Summer)
  final String soilType;  // Soil type required (Loamy, Clay, Sandy, etc.)
  final int growthDurationDays;  // Total days from planting to harvest
  final double optimalTemperatureMin;  // Minimum optimal temperature in Celsius
  final double optimalTemperatureMax;  // Maximum optimal temperature in Celsius
  final double optimalHumidity;  // Optimal humidity percentage
  final double optimalMoisture;  // Optimal soil moisture percentage
  final double waterRequiredMmPerWeek;  // Water needed per week in millimeters
  final String fertilizerRequired;  // Type of fertilizer needed
  final double expectedYieldPerHectare;  // Expected yield in kg per hectare
  final String? description;  // Optional crop description

  /// Constructor with all required fields
  Crop({
    required this.id,
    required this.name,
    required this.season,
    required this.soilType,
    required this.growthDurationDays,
    required this.optimalTemperatureMin,
    required this.optimalTemperatureMax,
    required this.optimalHumidity,
    required this.optimalMoisture,
    required this.waterRequiredMmPerWeek,
    required this.fertilizerRequired,
    required this.expectedYieldPerHectare,
    this.description,
  });

  /// Factory constructor to create Crop from JSON (from Django API response)
  /// This converts JSON data to Dart object
  factory Crop.fromJson(Map<String, dynamic> json) {
    final double temperature = _toDouble(
      json['optimal_temperature'] ?? json['optimal_temperature_min'],
    );

    return Crop(
      id: _toInt(json['id']),
      name: _toStringValue(json['name']),
      season: _toStringValue(json['season']),
      soilType: _toStringValue(json['soil_type']),
      growthDurationDays: _toInt(json['growth_duration_days']),
      optimalTemperatureMin: _toDouble(json['optimal_temperature_min'] ?? temperature),
      optimalTemperatureMax: _toDouble(json['optimal_temperature_max'] ?? temperature),
      optimalHumidity: _toDouble(json['optimal_humidity']),
      optimalMoisture: _toDouble(
        json['optimal_moisture'] ?? json['optimal_soil_moisture'],
      ),
      waterRequiredMmPerWeek: _toDouble(json['water_required_mm_per_week']),
      fertilizerRequired: _toStringValue(json['fertilizer_required']),
      expectedYieldPerHectare: _toDouble(json['expected_yield_per_hectare']),
      description: json['description']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static String _toStringValue(dynamic value) {
    return value?.toString() ?? '';
  }

  /// Convert Crop object back to JSON (for sending to Django API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'season': season,
      'soil_type': soilType,  // Convert back to snake_case for Django
      'growth_duration_days': growthDurationDays,
      'optimal_temperature': optimalTemperatureMax,
      'optimal_humidity': optimalHumidity,
      'optimal_soil_moisture': optimalMoisture,
      'water_required_mm_per_week': waterRequiredMmPerWeek,
      'fertilizer_required': fertilizerRequired,
      'expected_yield_per_hectare': expectedYieldPerHectare,
      'description': description,
    };
  }
}

/// CropGuide model - represents step-by-step crop growing guide
class CropGuide {
  final int id;
  final int cropId;  // Foreign key to Crop
  final String cropName;  // Crop name for display
  final String sowingInstructions;  // How to plant the crop
  final String wateringSchedule;  // When and how much to water
  final String fertilizerSchedule;  // When and what fertilizer to apply
  final String diseaseManagement;  // How to prevent/treat diseases
  final String pestManagement;  // How to manage pests
  final String harvestingGuidelines;  // When and how to harvest

  CropGuide({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.sowingInstructions,
    required this.wateringSchedule,
    required this.fertilizerSchedule,
    required this.diseaseManagement,
    required this.pestManagement,
    required this.harvestingGuidelines,
  });

  /// Create CropGuide from JSON response
  factory CropGuide.fromJson(Map<String, dynamic> json) {
    return CropGuide(
      id: Crop._toInt(json['id']),
      cropId: Crop._toInt(json['crop']),
      cropName: Crop._toStringValue(json['crop_name']),
      sowingInstructions: Crop._toStringValue(json['sowing_instructions']),
      wateringSchedule: Crop._toStringValue(json['watering_schedule']),
      fertilizerSchedule: Crop._toStringValue(json['fertilizer_schedule']),
      diseaseManagement: Crop._toStringValue(json['disease_management']),
      pestManagement: Crop._toStringValue(json['pest_management']),
      harvestingGuidelines: Crop._toStringValue(
        json['harvesting_guidelines'] ?? json['harvesting_instructions'],
      ),
    );
  }
}
