import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  List<Crop> crops = [];
  List<Map<String, dynamic>> recommendations = [];

  bool isLoading = true;
  String? errorMessage;

  String selectedSeason = 'All';
  String selectedSoil = 'All';
  String selectedState = '';
  final TextEditingController stateController = TextEditingController();

  final List<String> seasons = ['All', 'Kharif', 'Rabi', 'Summer'];
  final List<String> soils = ['All', 'Clay', 'Sandy', 'Loamy', 'Mixed'];

  @override
  void initState() {
    super.initState();
    loadCrops();
  }

  Future<void> loadCrops() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getCrops(
        season: selectedSeason == 'All' ? null : selectedSeason,
        soilType: selectedSoil == 'All' ? null : selectedSoil,
        state: selectedState.isEmpty ? null : selectedState,
        pageSize: 100,
      );

      final List<dynamic> cropsJson = (response['results'] as List<dynamic>? ?? []);
      final loadedCrops = cropsJson
          .map((json) => Crop.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      setState(() {
        crops = loadedCrops;
        isLoading = false;
      });

      await loadRecommendations();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load crops: $e';
        isLoading = false;
      });
    }
  }

  Future<void> loadRecommendations() async {
    if (selectedSeason == 'All') {
      setState(() {
        recommendations = [];
      });
      return;
    }

    try {
      final recs = await ApiService.getCropRecommendations(
        selectedSeason,
        soilType: selectedSoil == 'All' ? null : selectedSoil,
        state: selectedState.isEmpty ? null : selectedState,
      );

      setState(() {
        recommendations = recs
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (_) {
      setState(() {
        recommendations = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Crops')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadCrops,
            tooltip: LocalizationService.tr('Refresh'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  '${LocalizationService.tr('Season')}: ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedSeason,
                    isExpanded: true,
                    items: seasons
                        .map((season) => DropdownMenuItem(value: season, child: Text(season)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSeason = value!;
                      });
                      loadCrops();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '${LocalizationService.tr('Soil')}: ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedSoil,
                    isExpanded: true,
                    items: soils
                        .map((soil) => DropdownMenuItem(value: soil, child: Text(soil)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSoil = value!;
                      });
                      loadCrops();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: stateController,
                    decoration: const InputDecoration(
                      hintText: 'State filter (e.g. Maharashtra)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        selectedState = value.trim();
                      });
                      loadCrops();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedState = stateController.text.trim();
                      });
                      loadCrops();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
          if (recommendations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.tr('Recommendations'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendations.length > 8 ? 8 : recommendations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final rec = recommendations[index];
                        return Chip(label: Text(rec['crop_name']?.toString() ?? ''));
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadCrops,
                              child: Text(LocalizationService.tr('Retry')),
                            ),
                          ],
                        ),
                      )
                    : crops.isEmpty
                        ? Center(child: Text(LocalizationService.tr('No crops found')))
                        : RefreshIndicator(
                            onRefresh: loadCrops,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: crops.length,
                              itemBuilder: (context, index) {
                                final crop = crops[index];
                                return _buildCropCard(crop);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(Crop crop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showCropDetails(crop),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      crop.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(crop.season),
                    backgroundColor: _getSeasonColor(crop.season),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.terrain, size: 16, color: Colors.brown),
                  const SizedBox(width: 4),
                  Text('${LocalizationService.tr('Soil')}: ${crop.soilType}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('Duration: ${crop.growthDurationDays} days'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.agriculture, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Yield: ${crop.expectedYieldPerHectare} kg/hectare'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeasonColor(String season) {
    switch (season) {
      case 'Kharif':
        return Colors.green.shade100;
      case 'Rabi':
        return Colors.orange.shade100;
      case 'Summer':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  void _showCropDetails(Crop crop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${crop.name} - ${LocalizationService.tr('Crop Guide')}'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getCropDetail(crop.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            final guides = (data['guides'] as List<dynamic>? ?? []);
            final guide = guides.isNotEmpty
                ? Map<String, dynamic>.from(guides.first as Map)
                : <String, dynamic>{};

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(LocalizationService.tr('Season'), crop.season),
                  _buildDetailRow(LocalizationService.tr('Soil'), crop.soilType),
                  _buildDetailRow(LocalizationService.tr('Temperature'), '${crop.optimalTemperatureMax}°C'),
                  _buildDetailRow(
                    LocalizationService.tr('Watering'),
                    guide['watering_schedule']?.toString() ?? '-',
                  ),
                  _buildDetailRow(
                    LocalizationService.tr('Fertilizer'),
                    guide['fertilizer_schedule']?.toString() ?? crop.fertilizerRequired,
                  ),
                  _buildDetailRow(
                    LocalizationService.tr('Disease'),
                    guide['disease_management']?.toString() ?? '-',
                  ),
                  _buildDetailRow(
                    LocalizationService.tr('Harvest'),
                    guide['harvesting_instructions']?.toString() ?? '-',
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.tr('Close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stateController.dispose();
    super.dispose();
  }
}
