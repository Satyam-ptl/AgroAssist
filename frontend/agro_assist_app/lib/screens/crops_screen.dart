import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'crop_compare_screen.dart';
import 'crop_detail_screen.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _crops = [];
  List<String> _seasons = ['All'];
  List<String> _states = ['All'];

  // FIX: Use nullable strings so dropdown shows nothing until loaded
  String? _selectedSeason;
  String? _selectedState;
  String _query = '';

  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _filtersLoaded = false;
  final Set<int> _selectedCompareIds = <int>{};

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
      final uniqueSeasons = <String>[];
      for (final season in seasons) {
        final value = season.trim();
        if (value.isEmpty || uniqueSeasons.contains(value)) {
          continue;
        }
        uniqueSeasons.add(value);
      }

      final uniqueStates = <String>[];
      for (final state in states) {
        final value = state.trim();
        if (value.isEmpty || uniqueStates.contains(value)) {
          continue;
        }
        uniqueStates.add(value);
      }

      if (!mounted) return;
      setState(() {
        // FIX: Build list and set default selected value
        _seasons = ['All', ...uniqueSeasons];
        _states = ['All', ...uniqueStates];
        _selectedSeason = 'All';
        _selectedState = 'All';
        _filtersLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _seasons = ['All', 'Kharif', 'Rabi', 'Summer'];
        _states = ['All'];
        _selectedSeason = 'All';
        _selectedState = 'All';
        _filtersLoaded = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 180 &&
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
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
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
        ((response['results'] as List<dynamic>?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),
              overflow: TextOverflow.ellipsis, maxLines: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasCompareSelection = _selectedCompareIds.length >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Crops')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'compare_fab',
            onPressed: hasCompareSelection
                ? () => _openCompareScreen(withSelected: true)
                : () => _openCompareScreen(withSelected: false),
            icon: const Icon(Icons.compare_arrows),
            label: Text(
              hasCompareSelection
                  ? 'Compare (${_selectedCompareIds.length})'
                  : 'Compare',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (AuthService.isAdmin) ...[
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'add_crop_fab',
              onPressed: () => _openCropSheet(),
              child: const Icon(Icons.add),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadCrops(reset: true),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Search bar
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 400),
                            () {
                              _query = value.trim();
                              _loadCrops(reset: true);
                            },
                          );
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search crops',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // FIX: Season dropdown — use value not initialValue
                    // Show loading indicator until filters are loaded
                    if (!_filtersLoaded)
                      const SizedBox(
                        height: 48,
                        child: Center(
                          child: LinearProgressIndicator(),
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: screenWidth - 24,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSeason,
                          decoration: const InputDecoration(
                            labelText: 'Season',
                          ),
                          items: _seasons
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedSeason = value);
                            _loadCrops(reset: true);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // State dropdown
                      SizedBox(
                        width: screenWidth - 24,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          decoration: const InputDecoration(
                            labelText: 'State',
                          ),
                          items: _states
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedState = value);
                            _loadCrops(reset: true);
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Results count + clear filters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${_crops.length} crops found',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        // FIX: Show clear button when filters active
                        if (_selectedSeason != 'All' ||
                            _selectedState != 'All' ||
                            _query.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _selectedSeason = 'All';
                                _selectedState = 'All';
                              });
                              _loadCrops(reset: true);
                            },
                            icon: const Icon(Icons.clear,
                                size: 16, color: Colors.red),
                            label: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Crops list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _crops.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height *
                                        0.2,
                              ),
                              const Icon(Icons.grass,
                                  size: 52, color: Colors.grey),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No crops found'
                                      : "No crops found for '$_query'",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _crops.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _crops.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final crop = _crops[index];
                              final name =
                                  (crop['name'] ?? '').toString();
                              final description =
                                  (crop['description'] ?? '').toString();
                              final season =
                                  (crop['season'] ?? '').toString();
                              final states =
                                  (crop['states'] ?? '').toString();
                              final cropId = (crop['id'] as num?)?.toInt() ?? -1;
                              final selectedForCompare = _selectedCompareIds.contains(cropId);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                elevation: 2,
                                child: ListTile(
                                  onTap: () {
                                    if (cropId < 0) {
                                      return;
                                    }
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => CropDetailScreen(
                                          cropId: cropId,
                                          cropName: name,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    if (cropId < 0) {
                                      return;
                                    }
                                    _toggleCompareSelection(cropId);
                                  },
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                  title: Row(
                                    children: [
                                      if (selectedForCompare) ...[
                                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (AuthService.isAdmin) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 20),
                                          onPressed: () =>
                                              _openCropSheet(
                                                  existing: crop),
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red,
                                              size: 20),
                                          onPressed: () =>
                                              _deleteCrop(crop),
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // Season chip
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32)
                                                .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              season,
                                              style: const TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontSize: 11,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Description
                                          Expanded(
                                            child: Text(
                                              description,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // States
                                      if (states.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                states.replaceAll(
                                                    ',', ', '),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
    if (id == null) return;

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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteCrop(id);
      await _loadCrops(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Crop deleted',
              overflow: TextOverflow.ellipsis, maxLines: 1),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),
              overflow: TextOverflow.ellipsis, maxLines: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _openCropSheet({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(
        text: (existing?['name'] ?? '').toString());
    final descriptionController = TextEditingController(
        text: (existing?['description'] ?? '').toString());

    // FIX: Use valid season from list
    final availableSeasons = <String>[];
    for (final seasonValue in _seasons) {
      if (seasonValue == 'All' || availableSeasons.contains(seasonValue)) {
        continue;
      }
      availableSeasons.add(seasonValue);
    }
    if (availableSeasons.isEmpty) {
      availableSeasons.addAll(['Kharif', 'Rabi', 'Summer']);
    }

    String season = (existing?['season'] ?? '').toString();
    if (!availableSeasons.contains(season)) {
      season = availableSeasons.first;
    }

    String? error;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Add Crop' : 'Edit Crop',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Crop Name*'),
                    ),
                    const SizedBox(height: 10),
                    // FIX: Use value not initialValue in sheet too
                    DropdownButtonFormField<String>(
                      initialValue: season,
                      decoration:
                          const InputDecoration(labelText: 'Season'),
                      items: availableSeasons
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => season = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Description'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            saving ? null : () => Navigator.pop(context),
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
                                  setSheetState(
                                      () => error = 'Crop name is required');
                                  return;
                                }
                                setSheetState(() {
                                  saving = true;
                                  error = null;
                                });

                                final payload = {
                                  'name': nameController.text.trim(),
                                  'season': season,
                                  'description':
                                      descriptionController.text.trim(),
                                  'category': (existing?['category'] ??
                                          'Other')
                                      .toString(),
                                  'crop_type': (existing?['crop_type'] ??
                                          'Field')
                                      .toString(),
                                  'soil_type': (existing?['soil_type'] ??
                                          'Loamy')
                                      .toString(),
                                  'states':
                                      (existing?['states'] ?? '').toString(),
                                  'growth_duration_days':
                                      existing?['growth_duration_days'] ??
                                          100,
                                  'optimal_temperature':
                                      existing?['optimal_temperature'] ??
                                          26.0,
                                  'optimal_humidity':
                                      existing?['optimal_humidity'] ?? 60.0,
                                  'optimal_soil_moisture':
                                      existing?['optimal_soil_moisture'] ??
                                          45.0,
                                  'water_required_mm_per_week':
                                      existing?[
                                              'water_required_mm_per_week'] ??
                                          30.0,
                                  'fertilizer_required':
                                      existing?['fertilizer_required'] ??
                                          'NPK',
                                  'expected_yield_per_hectare':
                                      existing?[
                                              'expected_yield_per_hectare'] ??
                                          2000,
                                };

                                try {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  final id =
                                      (existing?['id'] as num?)?.toInt();
                                  if (id == null) {
                                    await ApiService.createCrop(payload);
                                  } else {
                                    await ApiService.updateCrop(
                                        id, payload);
                                  }
                                  if (!mounted) return;
                                  navigator.pop();
                                  await _loadCrops(reset: true);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        id == null
                                            ? 'Crop added'
                                            : 'Crop updated',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      backgroundColor:
                                          const Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
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
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Text(existing == null ? 'Add Crop' : 'Save'),
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

  void _toggleCompareSelection(int cropId) {
    setState(() {
      if (_selectedCompareIds.contains(cropId)) {
        _selectedCompareIds.remove(cropId);
      } else if (_selectedCompareIds.length < 3) {
        _selectedCompareIds.add(cropId);
      }
    });
  }

  void _openCompareScreen({required bool withSelected}) {
    final selectedCrops = _crops.where((crop) {
      final id = (crop['id'] as num?)?.toInt() ?? -1;
      return _selectedCompareIds.contains(id);
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CropCompareScreen(
          initiallySelected: withSelected ? selectedCrops : const <Map<String, dynamic>>[],
        ),
      ),
    );
  }
}