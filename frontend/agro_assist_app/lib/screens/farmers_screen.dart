import 'package:flutter/material.dart';
import '../models/farmer_model.dart';  // Import Farmer model
import '../services/api_service.dart';  // Import API service
import '../services/auth_service.dart';
import '../services/auth_ui_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_surface_card.dart';
import '../widgets/section_title.dart';

/// Farmers screen - shows list of all farmers
class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  List<Farmer> farmers = [];  // List of farmers
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isLoading = true;
  String? errorMessage;
  bool get _isAdmin => AuthService.session?.isAdmin == true;

  List<Farmer> get _visibleFarmers {
    if (_searchQuery.isEmpty) return farmers;
    final query = _searchQuery.toLowerCase();
    return farmers.where((farmer) {
      return farmer.fullName.toLowerCase().contains(query) ||
          farmer.city.toLowerCase().contains(query) ||
          farmer.state.toLowerCase().contains(query) ||
          farmer.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadFarmers();  // Load farmers when screen opens
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        errorMessage = 'Failed to load farmers: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleFarmers = _visibleFarmers;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Farmers')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthUiService.confirmAndLogout(context),
          ),
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
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SectionTitle(
                            title: 'Farmer Directory',
                            subtitle: 'Search and review farmer profiles with key field insights.',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search by name, city, state, or phone',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Chip(
                                avatar: const Icon(Icons.group, size: 16),
                                label: Text('Total: ${farmers.length}'),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                avatar: const Icon(Icons.filter_alt, size: 16),
                                label: Text('Visible: ${visibleFarmers.length}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (visibleFarmers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 18),
                              child: Center(child: Text('No farmers match your search.')),
                            )
                          else
                            ...visibleFarmers.map(_buildFarmerCard),
                        ],
                      ),
                    ),
    );
  }

  /// Build a card widget for a farmer
  Widget _buildFarmerCard(Farmer farmer) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showFarmerDetails(farmer);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    farmer.firstName.isNotEmpty ? farmer.firstName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    farmer.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_isAdmin)
                  IconButton(
                    tooltip: 'Delete farmer',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteFarmer(farmer),
                  ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.outline),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _metaChip(Icons.location_on_outlined, '${farmer.city}, ${farmer.state}'),
                _metaChip(Icons.phone_outlined, farmer.phoneNumber),
                _metaChip(Icons.landscape_outlined, 'Land: ${farmer.landAreaHectares} ha'),
              ],
            ),
            const SizedBox(height: 10),
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
    );
  }

  Widget _metaChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(value),
        ],
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
    showDialog<void>(
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

  Future<void> _confirmDeleteFarmer(Farmer farmer) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete farmer profile'),
        content: Text(
          'Delete ${farmer.fullName}? This also removes the linked user login account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ApiService.deleteFarmer(farmer.id);
      if (!mounted) return;
      await loadFarmers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmer deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      final handled = await AuthUiService.handleAuthError(
        context,
        e,
        message: 'Session expired. Please sign in again.',
      );
      if (handled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}
