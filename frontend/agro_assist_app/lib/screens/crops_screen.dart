import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _crops = <Map<String, dynamic>>[];
  List<String> _seasons = <String>['All'];
  List<String> _states = <String>['All'];

  String _selectedSeason = 'All';
  String _selectedState = 'All';
  String _query = '';

  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadCrops(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final seasons = await ApiService.getCropSeasons();
      final states = await ApiService.getCropStates();
      if (!mounted) {
        return;
      }
      setState(() {
        _seasons = ['All', ...seasons];
        _states = ['All', ...states];
      });
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 180 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _loadCrops();
    }
  }

  Future<void> _loadCrops({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      setState(() {
        _loading = true;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      final response = await ApiService.getCrops(
        search: _query.isEmpty ? null : _query,
        season: _selectedSeason == 'All' ? null : _selectedSeason,
        state: _selectedState == 'All' ? null : _selectedState,
        page: _page,
        pageSize: 50,
      );

      final results = List<Map<String, dynamic>>.from(
        ((response['results'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (reset) {
          _crops = results;
        } else {
          _crops.addAll(results);
        }
        _hasMore = response['next'] != null;
        _page += 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Crops')),
      floatingActionButton: AuthService.isAdmin
          ? FloatingActionButton(
              onPressed: () => _openCropSheet(),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadCrops(reset: true),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 400), () {
                            _query = value.trim();
                            _loadCrops(reset: true);
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search crops',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: screenWidth - 24,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSeason,
                        items: _seasons
                            .map((s) => DropdownMenuItem<String>(value: s, child: Text(s, overflow: TextOverflow.ellipsis, maxLines: 1)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedSeason = value);
                          _loadCrops(reset: true);
                        },
                        decoration: const InputDecoration(labelText: 'Season'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: screenWidth - 24,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        items: _states
                            .map((s) => DropdownMenuItem<String>(value: s, child: Text(s, overflow: TextOverflow.ellipsis, maxLines: 1)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedState = value);
                          _loadCrops(reset: true);
                        },
                        decoration: const InputDecoration(labelText: 'State'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_crops.length} crops found',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _crops.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              const Icon(Icons.grass, size: 52, color: Colors.grey),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  "No crops found for '$_query'",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _crops.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _crops.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final crop = _crops[index];
                              final name = (crop['name'] ?? '').toString();
                              final description = (crop['description'] ?? '').toString();
                              final season = (crop['season'] ?? '').toString();
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (AuthService.isAdmin) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _openCropSheet(existing: crop),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _deleteCrop(crop),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Chip(
                                        label: Text(
                                          season,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          description,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCrop(Map<String, dynamic> crop) async {
    final id = (crop['id'] as num?)?.toInt();
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Crop'),
        content: Text(
          'Delete ${(crop['name'] ?? '').toString()}?',
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.deleteCrop(id);
      await _loadCrops(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Crop deleted', overflow: TextOverflow.ellipsis, maxLines: 1),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), overflow: TextOverflow.ellipsis, maxLines: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _openCropSheet({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: (existing?['name'] ?? '').toString());
    final descriptionController = TextEditingController(text: (existing?['description'] ?? '').toString());
    String season = (existing?['season'] ?? (_seasons.length > 1 ? _seasons[1] : 'Kharif')).toString();
    String? error;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Add Crop' : 'Edit Crop', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Crop Name*'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: season,
                      items: _seasons
                          .where((s) => s != 'All')
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis, maxLines: 1)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => season = value);
                      },
                      decoration: const InputDecoration(labelText: 'Season'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 10),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (nameController.text.trim().isEmpty) {
                                  setSheetState(() => error = 'Crop name is required');
                                  return;
                                }
                                setSheetState(() {
                                  saving = true;
                                  error = null;
                                });

                                final payload = {
                                  'name': nameController.text.trim(),
                                  'season': season,
                                  'description': descriptionController.text.trim(),
                                  'category': (existing?['category'] ?? 'Other').toString(),
                                  'crop_type': (existing?['crop_type'] ?? 'Field').toString(),
                                  'soil_type': (existing?['soil_type'] ?? 'Loamy').toString(),
                                  'states': (existing?['states'] ?? '').toString(),
                                  'growth_duration_days': (existing?['growth_duration_days'] ?? 100),
                                  'optimal_temperature': (existing?['optimal_temperature'] ?? 26.0),
                                  'optimal_humidity': (existing?['optimal_humidity'] ?? 60.0),
                                  'optimal_soil_moisture': (existing?['optimal_soil_moisture'] ?? 45.0),
                                  'water_required_mm_per_week': (existing?['water_required_mm_per_week'] ?? 30.0),
                                  'fertilizer_required': (existing?['fertilizer_required'] ?? 'NPK'),
                                  'expected_yield_per_hectare': (existing?['expected_yield_per_hectare'] ?? 2000),
                                };

                                try {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  final id = (existing?['id'] as num?)?.toInt();
                                  if (id == null) {
                                    await ApiService.createCrop(payload);
                                  } else {
                                    await ApiService.updateCrop(id, payload);
                                  }
                                  if (!mounted) return;
                                  navigator.pop();
                                  await _loadCrops(reset: true);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        id == null ? 'Crop added' : 'Crop updated',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      backgroundColor: const Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                } catch (e) {
                                  setSheetState(() {
                                    error = e.toString();
                                    saving = false;
                                  });
                                }
                              },
                        child: saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
  }
}
