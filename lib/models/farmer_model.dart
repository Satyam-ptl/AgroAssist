/// Farmer model class - represents farmer data from Django API
class Farmer {
  final int id;  // Unique identifier
  final String firstName;  // Farmer's first name
  final String lastName;  // Farmer's last name
  final String email;  // Email address (unique)
  final String phoneNumber;  // Phone number (unique, for WhatsApp/SMS)
  final String address;  // Full address
  final String city;  // City name
  final String state;  // State name
  final String postalCode;  // PIN code
  final String preferredLanguage;  // Hindi, Marathi, or English
  final double landAreaHectares;  // Total land area in hectares
  final String soilType;  // Type of soil on farm
  final String experienceLevel;  // Beginner, Intermediate, or Expert
  final String contactMethod;  // WhatsApp or SMS
  final DateTime createdAt;  // When farmer registered
  final DateTime updatedAt;  // Last updated time

  /// Constructor
  Farmer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.preferredLanguage,
    required this.landAreaHectares,
    required this.soilType,
    required this.experienceLevel,
    required this.contactMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get farmer's full name
  String get fullName => '$firstName $lastName';

  /// Create Farmer from JSON (from Django API)
  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: _toInt(json['id']),
      firstName: _toStringValue(json['first_name']),
      lastName: _toStringValue(json['last_name']),
      email: _toStringValue(json['email']),
      phoneNumber: _toStringValue(json['phone_number']),
      address: _toStringValue(json['address']),
      city: _toStringValue(json['city']),
      state: _toStringValue(json['state']),
      postalCode: _toStringValue(json['postal_code']),
      preferredLanguage: _toStringValue(json['preferred_language']),
      landAreaHectares: _toDouble(json['land_area_hectares']),
      soilType: _toStringValue(json['soil_type']),
      experienceLevel: _toStringValue(json['experience_level']),
      contactMethod: _toStringValue(json['contact_method']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
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

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Convert Farmer to JSON (for creating/updating via API)
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'preferred_language': preferredLanguage,
      'land_area_hectares': landAreaHectares,
      'soil_type': soilType,
      'experience_level': experienceLevel,
      'contact_method': contactMethod,
    };
  }
}

/// FarmerCrop model - tracks which crops a farmer is growing
class FarmerCrop {
  final int id;
  final int farmerId;  // Foreign key to Farmer
  final String farmerName;  // Farmer's name for display
  final int cropId;  // Foreign key to Crop
  final String cropName;  // Crop name for display
  final String status;  // Planned, Growing, Harvested, Completed
  final DateTime plantingDate;  // When crop was planted
  final DateTime? expectedHarvestDate;  // Expected harvest date (can be null)
  final double areaAllocatedHectares;  // Area used for this crop
  final double? expectedYieldKg;  // Expected yield in kg (can be null)
  final int? daysSincePlanting;  // Calculated: days since planting
  final int? daysUntilHarvest;  // Calculated: days until harvest

  FarmerCrop({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropId,
    required this.cropName,
    required this.status,
    required this.plantingDate,
    this.expectedHarvestDate,
    required this.areaAllocatedHectares,
    this.expectedYieldKg,
    this.daysSincePlanting,
    this.daysUntilHarvest,
  });

  /// Create FarmerCrop from JSON
  factory FarmerCrop.fromJson(Map<String, dynamic> json) {
    return FarmerCrop(
      id: _toInt(json['id']),
      farmerId: _toInt(json['farmer']),
      farmerName: _toStringValue(json['farmer_name']),
      cropId: _toInt(json['crop']),
      cropName: _toStringValue(json['crop_name']),
      status: _toStringValue(json['status']),
      plantingDate: _toDateTime(json['planting_date']),
      expectedHarvestDate: json['expected_harvest_date'] != null
          ? _toDateTime(json['expected_harvest_date'])
          : null,
      areaAllocatedHectares: _toDouble(json['area_allocated_hectares']),
      expectedYieldKg: json['expected_yield_kg'] != null
          ? _toDouble(json['expected_yield_kg'])
          : null,
      daysSincePlanting: json['days_since_planting'] != null
          ? _toInt(json['days_since_planting'])
          : null,
      daysUntilHarvest: json['days_until_harvest'] != null
          ? _toInt(json['days_until_harvest'])
          : null,
    );
  }
}

/// FarmerInventory model - tracks farmer's inventory (seeds, fertilizers, tools)
class FarmerInventory {
  final int id;
  final int farmerId;
  final String farmerName;
  final String itemType;  // Seeds, Fertilizer, or Tools
  final String itemName;  // Name of the item
  final double quantity;  // Amount available
  final String unit;  // Unit of measurement (kg, liters, pieces)
  final DateTime purchaseDate;  // When item was purchased
  final DateTime? expiryDate;  // Expiry date (can be null for tools)
  final bool? isExpired;  // Calculated: whether item has expired

  FarmerInventory({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.itemType,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    this.expiryDate,
    this.isExpired,
  });

  /// Create FarmerInventory from JSON
  factory FarmerInventory.fromJson(Map<String, dynamic> json) {
    return FarmerInventory(
      id: _toInt(json['id']),
      farmerId: _toInt(json['farmer']),
      farmerName: _toStringValue(json['farmer_name']),
      itemType: _toStringValue(json['item_type']),
      itemName: _toStringValue(json['item_name']),
      quantity: _toDouble(json['quantity']),
      unit: _toStringValue(json['unit']),
      purchaseDate: _toDateTime(json['purchase_date']),
      expiryDate: json['expiry_date'] != null
          ? _toDateTime(json['expiry_date'])
          : null,
      isExpired: json['is_expired'] is bool ? json['is_expired'] as bool : null,
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

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
