import 'package:flutter/material.dart';
import '../models/weather_model.dart';  // Import Weather models
import '../services/api_service.dart';  // Import API service
import '../services/localization_service.dart';
import 'package:intl/intl.dart';  // For date formatting

/// Weather screen - shows weather alerts and forecasts
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  List<FarmersWeatherAlert> alerts = [];  // List of weather alerts
  WeatherData? latestWeather;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadWeatherAlerts();  // Load weather alerts when screen opens
  }

  /// Load weather alerts from Django API
  Future<void> loadWeatherAlerts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final alertsJson = await ApiService.getAllWeatherAlerts(pageSize: 100);
      final weatherJson = await ApiService.getWeatherDataList(pageSize: 1);
      final List<FarmersWeatherAlert> loadedAlerts = alertsJson
          .map((json) => FarmersWeatherAlert.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      final WeatherData? weather = weatherJson.isNotEmpty
          ? WeatherData.fromJson(Map<String, dynamic>.from(weatherJson.first as Map))
          : null;

      setState(() {
        alerts = loadedAlerts;
        latestWeather = weather;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load weather alerts: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Weather & Alerts')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadWeatherAlerts,
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
                      Text(errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadWeatherAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (latestWeather != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationService.tr('Basic Rain Info'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text('${LocalizationService.tr('Rainfall')}: ${latestWeather!.rainfall} mm'),
                                Text('${LocalizationService.tr('Temperature')}: ${latestWeather!.temperature}°C'),
                                Text('${LocalizationService.tr('Humidity')}: ${latestWeather!.humidity}%'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: alerts.isEmpty
                          ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            LocalizationService.tr('No weather alerts at the moment'),
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            LocalizationService.tr('Check back later for updates'),
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                          : RefreshIndicator(
                              onRefresh: loadWeatherAlerts,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: alerts.length,
                                itemBuilder: (context, index) {
                                  final alert = alerts[index];
                                  return _buildAlertCard(alert);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  /// Build a card widget for a weather alert
  Widget _buildAlertCard(FarmersWeatherAlert alert) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: alert.severity == 'Critical' ? 4 : 2,
      child: InkWell(
        onTap: () {
          _showAlertDetails(alert);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert type and severity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAlertIcon(alert.alertType),
                        color: _getSeverityColor(alert.severity),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert.alertType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(alert.severity),
                    backgroundColor: _getSeverityColor(alert.severity),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Alert message
              Text(
                alert.message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Issued date
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Issued: ${dateFormat.format(alert.issuedAt)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              // Expires date if available
              if (alert.expiresAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_off, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Expires: ${dateFormat.format(alert.expiresAt!)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],

              // Active status
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alert.isActive == true
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.isActive == true ? 'Active' : 'Expired',
                  style: TextStyle(
                    color: alert.isActive == true ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get icon for alert type
  IconData _getAlertIcon(String alertType) {
    switch (alertType) {
      case 'Rain':
        return Icons.water_drop;
      case 'Frost':
        return Icons.ac_unit;
      case 'Heat':
        return Icons.wb_sunny;
      case 'Wind':
        return Icons.air;
      case 'Disease':
        return Icons.warning;
      case 'Pest':
        return Icons.bug_report;
      default:
        return Icons.info;
    }
  }

  /// Get color for severity
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red.shade300;
      case 'High':
        return Colors.orange.shade300;
      case 'Medium':
        return Colors.yellow.shade300;
      case 'Low':
        return Colors.blue.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  /// Show alert details dialog
  void _showAlertDetails(FarmersWeatherAlert alert) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.alertType),
              color: _getSeverityColor(alert.severity),
            ),
            const SizedBox(width: 8),
            Text(alert.alertType),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Farmer', alert.farmerName),
              _buildDetailRow('Severity', alert.severity),
              _buildDetailRow('Issued At', dateFormat.format(alert.issuedAt)),
              if (alert.expiresAt != null)
                _buildDetailRow('Expires At', dateFormat.format(alert.expiresAt!)),
              _buildDetailRow('Status', alert.isActive == true ? 'Active' : 'Expired'),
              _buildDetailRow('Read', alert.isRead ? 'Yes' : 'No'),
              if (alert.actionTaken != null && alert.actionTaken!.isNotEmpty)
                _buildDetailRow('Action Taken', alert.actionTaken!),
              const SizedBox(height: 8),
              const Text('Message:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(alert.message),
            ],
          ),
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

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
