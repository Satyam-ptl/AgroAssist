import 'package:flutter/material.dart';
import '../models/farmer_model.dart';  // Import Farmer model
import '../services/api_service.dart';  // Import API service
import '../services/localization_service.dart';

/// Farmers screen - shows list of all farmers
class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  List<Farmer> farmers = [];  // List of farmers
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadFarmers();  // Load farmers when screen opens
  }

  /// Load farmers from Django API
  Future<void> loadFarmers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getFarmers(pageSize: 100);
      final List<dynamic> farmersJson = (response['results'] as List<dynamic>? ?? []);
      final List<Farmer> loadedFarmers = farmersJson
          .map((json) => Farmer.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      setState(() {
        farmers = loadedFarmers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load farmers: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Farmers')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadFarmers,
            tooltip: LocalizationService.tr('Refresh'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadFarmers,
                            child: Text(LocalizationService.tr('Retry')),
                      ),
                    ],
                  ),
                )
              : farmers.isEmpty
                  ? Center(child: Text(LocalizationService.tr('No farmers found')))
                  : RefreshIndicator(
                      onRefresh: loadFarmers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: farmers.length,
                        itemBuilder: (context, index) {
                          final farmer = farmers[index];
                          return _buildFarmerCard(farmer);
                        },
                      ),
                    ),
    );
  }

  /// Build a card widget for a farmer
  Widget _buildFarmerCard(Farmer farmer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showFarmerDetails(farmer);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farmer name
              Text(
                farmer.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('${farmer.city}, ${farmer.state}'),
                ],
              ),
              const SizedBox(height: 4),

              // Phone
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(farmer.phoneNumber),
                ],
              ),
              const SizedBox(height: 4),

              // Land area
              Row(
                children: [
                  const Icon(Icons.landscape, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Land: ${farmer.landAreaHectares} hectares'),
                ],
              ),
              const SizedBox(height: 8),

              // Experience level chip
              Row(
                children: [
                  Chip(
                    label: Text(farmer.experienceLevel),
                    backgroundColor: _getExperienceColor(farmer.experienceLevel),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(farmer.preferredLanguage),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color for experience level
  Color _getExperienceColor(String level) {
    switch (level) {
      case 'Expert':
        return Colors.green.shade200;
      case 'Intermediate':
        return Colors.orange.shade200;
      case 'Beginner':
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  /// Show farmer details dialog
  void _showFarmerDetails(Farmer farmer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(farmer.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', farmer.email),
              _buildDetailRow('Phone', farmer.phoneNumber),
              _buildDetailRow('Address', farmer.address),
              _buildDetailRow('City', farmer.city),
              _buildDetailRow('State', farmer.state),
              _buildDetailRow('Postal Code', farmer.postalCode),
              _buildDetailRow('Language', farmer.preferredLanguage),
              _buildDetailRow('Land Area', '${farmer.landAreaHectares} hectares'),
              _buildDetailRow('Soil Type', farmer.soilType),
              _buildDetailRow('Experience', farmer.experienceLevel),
              _buildDetailRow('Contact Method', farmer.contactMethod),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
