import 'package:flutter/material.dart';
import 'crops_screen.dart';  // Import crops screen
import 'farmers_screen.dart';  // Import farmers screen
import 'tasks_screen.dart';  // Import tasks screen
import 'weather_screen.dart';  // Import weather screen
import '../services/api_service.dart';  // Import API service
import '../services/localization_service.dart';

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
      // Handle errors
      setState(() {
        errorMessage = 'Failed to load dashboard data. Please check your connection.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top app bar
      appBar: AppBar(
        title: Text('${LocalizationService.tr('Farm Buddy')} ${LocalizationService.tr('Dashboard')}'),
        centerTitle: true,  // Center the title
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
        ],
      ),
      
      // Main content area
      body: isLoading
          ? const Center(child: CircularProgressIndicator())  // Show loading spinner
          : errorMessage != null
              ? Center(
                  // Show error message with retry button
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
                  // Pull to refresh functionality
                  onRefresh: loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),  // Enable pull-to-refresh
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome message
                        Text(
                          LocalizationService.tr('Welcome to Farm Buddy'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocalizationService.tr('Your Multi-Crop Growth Assistant'),
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Statistics cards in 2x2 grid
                        GridView.count(
                          crossAxisCount: 2,  // 2 columns
                          shrinkWrap: true,  // Don't take infinite height
                          physics: const NeverScrollableScrollPhysics(),  // Don't scroll (parent scrolls)
                          crossAxisSpacing: 16,  // Space between columns
                          mainAxisSpacing: 16,  // Space between rows
                          children: [
                            // Crops stat card
                            _buildStatCard(
                              'Total Crops',
                              totalCrops.toString(),
                              Icons.grass,
                              Colors.green,
                            ),
                            // Farmers stat card
                            _buildStatCard(
                              'Total Farmers',
                              totalFarmers.toString(),
                              Icons.people,
                              Colors.blue,
                            ),
                            // Tasks stat card
                            _buildStatCard(
                              'Pending Tasks',
                              pendingTasks.toString(),
                              Icons.assignment,
                              Colors.orange,
                            ),
                            // Alerts stat card
                            _buildStatCard(
                              'Active Alerts',
                              activeAlerts.toString(),
                              Icons.warning,
                              Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions section
                        Text(
                          LocalizationService.tr('Quick Actions'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        _buildActionButton(
                          LocalizationService.tr('Browse Crops'),
                          'View all available crops and guides',
                          Icons.grass,
                          Colors.green,
                          () {
                            // Navigate to crops screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CropsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        _buildActionButton(
                          LocalizationService.tr('Manage Farmers'),
                          'View and manage farmer profiles',
                          Icons.people,
                          Colors.blue,
                          () {
                            // Navigate to farmers screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FarmersScreen()),
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
                              MaterialPageRoute(builder: (context) => const TasksScreen()),
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
                              MaterialPageRoute(builder: (context) => const WeatherScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build a statistics card widget
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),  // Icon at top
            const SizedBox(height: 8),
            Text(
              value,  // Number value
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,  // Title text
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build an action button widget
  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),  // Light background
          child: Icon(icon, color: color),  // Colored icon
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),  // Arrow icon
        onTap: onTap,  // Execute callback when tapped
      ),
    );
  }
}
