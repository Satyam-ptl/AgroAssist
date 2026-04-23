import 'package:flutter/material.dart';
import 'crops_screen.dart';  // Import crops screen
import 'farmers_screen.dart';  // Import farmers screen
import 'tasks_screen.dart';  // Import tasks screen
import 'weather_screen.dart';  // Import weather screen
import '../services/api_service.dart';  // Import API service
import '../services/auth_service.dart';
import '../services/auth_ui_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_surface_card.dart';
import '../widgets/section_title.dart';

/// Home screen - dashboard showing overview of all data
/// This is a StatefulWidget because it loads data and updates UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables to store data counts
  int totalCrops = 0;  // Total number of crops
  int totalFarmers = 0;  // Total number of farmers
  int pendingTasks = 0;  // Number of pending tasks
  int activeAlerts = 0;  // Number of active weather alerts
  
  bool isLoading = true;  // Whether data is being loaded
  String? errorMessage;  // Error message if API call fails

  @override
  void initState() {
    super.initState();
    loadDashboardData();  // Load data when screen opens
  }

  /// Load all dashboard data from Django API
  Future<void> loadDashboardData() async {
    setState(() {
      isLoading = true;  // Show loading indicator
      errorMessage = null;  // Clear any previous errors
    });

    try {
      // Make parallel API calls to get all data
      // These run at the same time for faster loading
      final cropsResponse = await ApiService.getCrops(pageSize: 1);  // Get crops count
      final farmersResponse = await ApiService.getFarmers(pageSize: 1);  // Get farmers count
      final tasksResponse = await ApiService.getTasks(status: 'Pending', pageSize: 1);  // Get pending tasks
      
      // Update state with received data
      setState(() {
        totalCrops = (cropsResponse['count'] as num?)?.toInt() ?? 0;  // Total crops from API
        totalFarmers = (farmersResponse['count'] as num?)?.toInt() ?? 0;  // Total farmers from API
        pendingTasks = (tasksResponse['count'] as num?)?.toInt() ?? 0;  // Pending tasks from API
        isLoading = false;  // Hide loading indicator
      });
    } catch (e) {
      if (!mounted) return;
      final handled = await AuthUiService.handleAuthError(
        context,
        e,
        message: 'Session expired. Please sign in again.',
      );
      if (handled) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      if (!mounted) return;
      // Handle errors
      setState(() {
        errorMessage = 'Failed to load dashboard data. Please check your connection.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFarmer = AuthService.session?.isFarmer == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('${LocalizationService.tr('AgroAssist')} ${LocalizationService.tr('Dashboard')}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: LocalizationService.languageNotifier.value,
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
                items: LocalizationService.supportedLanguages
                    .map((language) => DropdownMenuItem(
                          value: language,
                          child: Text(language),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    LocalizationService.setLanguage(value);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadDashboardData,
            tooltip: LocalizationService.tr('Refresh'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthUiService.confirmAndLogout(context),
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
                        onPressed: loadDashboardData,  // Retry button
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.secondaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.surface,
                                child: Icon(Icons.agriculture, color: colorScheme.primary, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationService.tr('Welcome to AgroAssist'),
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      LocalizationService.tr('Your Multi-Crop Growth Assistant'),
                                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.75)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const SectionTitle(
                          title: 'Overview',
                          subtitle: 'Realtime indicators from crops, farmers, tasks, and weather.',
                        ),
                        const SizedBox(height: 12),

                        GridView.count(
                          crossAxisCount: MediaQuery.of(context).size.width > 860 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatCard('Total Crops', totalCrops.toString(), Icons.grass, const Color(0xFF2E7D32)),
                            _buildStatCard('Total Farmers', totalFarmers.toString(), Icons.group, const Color(0xFF1565C0)),
                            _buildStatCard('Pending Tasks', pendingTasks.toString(), Icons.assignment, const Color(0xFFEF6C00)),
                            _buildStatCard('Active Alerts', activeAlerts.toString(), Icons.warning_amber, const Color(0xFFC62828)),
                          ],
                        ),

                        const SizedBox(height: 32),

                        const SectionTitle(
                          title: 'Quick Actions',
                          subtitle: 'Jump directly into your most used workflows.',
                        ),
                        const SizedBox(height: 12),

                        _buildActionButton(
                          LocalizationService.tr('Browse Crops'),
                          'View all available crops and guides',
                          Icons.grass,
                          Colors.green,
                          () {
                            // Navigate to crops screen
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (context) => const CropsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        _buildActionButton(
                          isFarmer ? 'My Profile' : LocalizationService.tr('Manage Farmers'),
                          isFarmer
                              ? 'View your farmer profile and details'
                              : 'View and manage farmer profiles',
                          Icons.people,
                          Colors.blue,
                          () {
                            // Navigate to farmers screen
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (context) => const FarmersScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        _buildActionButton(
                          LocalizationService.tr('View Tasks'),
                          'Check and manage farming tasks',
                          Icons.assignment,
                          Colors.orange,
                          () {
                            // Navigate to tasks screen
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (context) => const TasksScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        _buildActionButton(
                          LocalizationService.tr('Weather Alerts'),
                          'View weather forecasts and alerts',
                          Icons.cloud,
                          Colors.purple,
                          () {
                            // Navigate to weather screen
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (context) => const WeatherScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppSurfaceCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
