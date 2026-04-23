import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_model.dart';
import '../services/api_service.dart';
import '../services/auth_ui_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_surface_card.dart';
import '../widgets/section_title.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  List<FarmersWeatherAlert> alerts = [];
  WeatherData? latestWeather;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadWeatherAlerts();
  }

  Future<void> loadWeatherAlerts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final alertsJson = await ApiService.getAllWeatherAlerts();
      final weatherJson = await ApiService.getWeatherDataList();

      final loadedAlerts = alertsJson
          .map((json) => FarmersWeatherAlert.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      final weather = weatherJson.isNotEmpty
          ? WeatherData.fromJson(Map<String, dynamic>.from(weatherJson.first as Map))
          : null;

      setState(() {
        alerts = loadedAlerts;
        latestWeather = weather;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final handled = await AuthUiService.handleAuthError(
        context,
        e,
        message: 'Session expired. Please sign in again.',
      );
      if (handled) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      setState(() {
        errorMessage = 'Failed to load weather alerts: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Weather & Alerts')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthUiService.confirmAndLogout(context),
          ),
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
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Weather Intelligence',
                            subtitle: 'Live climate indicators and risk alerts for farmers.',
                          ),
                          const SizedBox(height: 12),
                          if (latestWeather != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primaryContainer,
                                    colorScheme.tertiaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Snapshot',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _metricChip(Icons.water_drop_outlined, '${LocalizationService.tr('Rainfall')}: ${latestWeather!.rainfall} mm'),
                                      _metricChip(Icons.thermostat_outlined, '${LocalizationService.tr('Temperature')}: ${latestWeather!.temperature}°C'),
                                      _metricChip(Icons.opacity_outlined, '${LocalizationService.tr('Humidity')}: ${latestWeather!.humidity}%'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: alerts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_outlined, size: 78, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    LocalizationService.tr('No weather alerts at the moment'),
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    LocalizationService.tr('Check back later for updates'),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: loadWeatherAlerts,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: alerts.length,
                                itemBuilder: (context, index) => _buildAlertCard(alerts[index]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _metricChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildAlertCard(FarmersWeatherAlert alert) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAlertDetails(alert),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getAlertIcon(alert.alertType), color: _getSeverityColor(alert.severity), size: 24),
                    const SizedBox(width: 8),
                    Text(alert.alertType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Chip(
                  label: Text(alert.severity),
                  backgroundColor: _getSeverityColor(alert.severity),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _metaTag(Icons.access_time, 'Issued: ${dateFormat.format(alert.issuedAt)}'),
                if (alert.expiresAt != null) _metaTag(Icons.timer_off, 'Expires: ${dateFormat.format(alert.expiresAt!)}'),
                _metaTag(Icons.flag_outlined, alert.isActive == true ? 'Active' : 'Expired'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }

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

  void _showAlertDetails(FarmersWeatherAlert alert) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getAlertIcon(alert.alertType), color: _getSeverityColor(alert.severity)),
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
              if (alert.expiresAt != null) _buildDetailRow('Expires At', dateFormat.format(alert.expiresAt!)),
              _buildDetailRow('Status', alert.isActive == true ? 'Active' : 'Expired'),
              _buildDetailRow('Read', alert.isRead ? 'Yes' : 'No'),
              if (alert.actionTaken != null && alert.actionTaken!.isNotEmpty)
                _buildDetailRow('Action Taken', alert.actionTaken!),
              const SizedBox(height: 8),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
