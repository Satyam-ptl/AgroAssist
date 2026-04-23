import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/auth_ui_service.dart';
import '../services/localization_service.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  List<Crop> crops = [];
  List<Map<String, dynamic>> recommendations = [];
  final Set<int> selectedForComparison = <int>{};
  final TextEditingController areaController = TextEditingController(text: '1');
  String areaUnit = 'Hectare';

  bool isLoading = true;
  String? errorMessage;
  Set<int> mySelectedCropIds = <int>{};

  String selectedSeason = 'All';
  String selectedSoil = 'All';
  String selectedState = '';
  String searchQuery = '';
  bool toolsExpanded = false;
  final ExpansibleController toolsController = ExpansibleController();
  final TextEditingController searchController = TextEditingController();

  final List<String> seasons = [
    'All',
    'Kharif',
    'Rabi',
    'Zaid',
  ];
  final List<String> soils = ['All', 'Clay', 'Sandy', 'Loamy', 'Mixed'];

  static const List<String> _indianStatesAndUts = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static const Map<String, String> _stateAliases = {
    'ap': 'Andhra Pradesh',
    'ar': 'Arunachal Pradesh',
    'as': 'Assam',
    'br': 'Bihar',
    'cg': 'Chhattisgarh',
    'ga': 'Goa',
    'gj': 'Gujarat',
    'hr': 'Haryana',
    'hp': 'Himachal Pradesh',
    'jh': 'Jharkhand',
    'ka': 'Karnataka',
    'kl': 'Kerala',
    'mp': 'Madhya Pradesh',
    'mh': 'Maharashtra',
    'mn': 'Manipur',
    'ml': 'Meghalaya',
    'mz': 'Mizoram',
    'nl': 'Nagaland',
    'od': 'Odisha',
    'orissa': 'Odisha',
    'pb': 'Punjab',
    'rj': 'Rajasthan',
    'sk': 'Sikkim',
    'tn': 'Tamil Nadu',
    'tg': 'Telangana',
    'ts': 'Telangana',
    'tr': 'Tripura',
    'up': 'Uttar Pradesh',
    'uk': 'Uttarakhand',
    'ut': 'Uttarakhand',
    'wb': 'West Bengal',
    'an': 'Andaman and Nicobar Islands',
    'ch': 'Chandigarh',
    'dn': 'Dadra and Nagar Haveli and Daman and Diu',
    'dd': 'Dadra and Nagar Haveli and Daman and Diu',
    'dl': 'Delhi',
    'jk': 'Jammu and Kashmir',
    'la': 'Ladakh',
    'ld': 'Lakshadweep',
    'py': 'Puducherry',
    'pondicherry': 'Puducherry',
  };

  static const Map<String, String> _seasonApiMapping = {'Zaid': 'Summer'};

  bool get _canSelectCropForTasks =>
      AuthService.session?.isFarmer == true &&
      AuthService.session?.farmerId != null;

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
      final futures = <Future<Object>>[
        ApiService.getCrops(
          season: _seasonQueryValue(selectedSeason),
          soilType: selectedSoil == 'All' ? null : selectedSoil,
          state: selectedState.isEmpty ? null : selectedState,
          search: searchQuery.isEmpty ? null : searchQuery,
          pageSize: 100,
        ),
      ];

      if (_canSelectCropForTasks) {
        futures.add(ApiService.getFarmerCrops(pageSize: 200));
      }

      final results = await Future.wait<Object>(futures);
      final response = results.first as Map<String, dynamic>;

      final List<dynamic> cropsJson =
          (response['results'] as List<dynamic>? ?? []);
      final loadedCrops = cropsJson
          .map((json) => Crop.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Some datasets contain repeated crop entries. Keep one unique crop per
      // name/season/soil combination so users do not see duplicates.
      final seenCropKeys = <String>{};
      final dedupedCrops = <Crop>[];
      for (final crop in loadedCrops) {
        final key =
            '${crop.name.trim().toLowerCase()}|${crop.season.trim().toLowerCase()}|${crop.soilType.trim().toLowerCase()}';
        if (seenCropKeys.add(key)) {
          dedupedCrops.add(crop);
        }
      }

      final filteredCrops =
          dedupedCrops.where(_matchesSelectedFilters).toList();

      var selectedCropIds = <int>{};
      if (_canSelectCropForTasks && results.length > 1) {
        final farmerCropsResponse = results[1] as Map<String, dynamic>;
        final farmerCropsJson =
            (farmerCropsResponse['results'] as List<dynamic>? ?? []);
        selectedCropIds = farmerCropsJson
            .map((item) =>
                _toInt(Map<String, dynamic>.from(item as Map)['crop']))
            .where((cropId) => cropId > 0)
            .toSet();
      }

      setState(() {
        crops = filteredCrops;
        mySelectedCropIds = selectedCropIds;
        isLoading = false;
      });

      await loadRecommendations();
    } catch (e) {
      if (!mounted) return;
      final handled = await AuthUiService.handleAuthError(
        context,
        e,
        message: 'Session expired. Please sign in again.',
      );
      if (handled) return;
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
        _seasonQueryValue(selectedSeason) ?? selectedSeason,
        soilType: selectedSoil == 'All' ? null : selectedSoil,
        state: selectedState.isEmpty ? null : selectedState,
      );

      setState(() {
        recommendations =
            recs.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      final handled = await AuthUiService.handleAuthError(
        context,
        e,
        message: 'Session expired. Please sign in again.',
      );
      if (handled) return;
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
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthUiService.confirmAndLogout(context),
          ),
          if (selectedForComparison.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: _showCropComparison,
              tooltip: 'Compare selected crops',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadCrops,
            tooltip: LocalizationService.tr('Refresh'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadCrops,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        controller: toolsController,
                        initiallyExpanded: toolsExpanded,
                        onExpansionChanged: (value) {
                          setState(() => toolsExpanded = value);
                        },
                        leading: const Icon(Icons.tune),
                        title: const Text('Crop tools'),
                        subtitle: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Chip(label: Text('Season: $selectedSeason')),
                            Chip(label: Text('Soil: $selectedSoil')),
                            if (selectedState.isNotEmpty)
                              Chip(label: Text('State: $selectedState')),
                            if (searchQuery.isNotEmpty)
                              Chip(label: Text('Search: $searchQuery')),
                          ],
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: seasons
                                  .map(
                                    (season) => ChoiceChip(
                                      label: Text(season),
                                      selected: selectedSeason == season,
                                      onSelected: (_) {
                                        setState(() => selectedSeason = season);
                                        loadCrops();
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: soils.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final soil = soils[index];
                                return FilterChip(
                                  label: Text(soil),
                                  selected: selectedSoil == soil,
                                  onSelected: (_) {
                                    setState(() => selectedSoil = soil);
                                    loadCrops();
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 760;

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    TextField(
                                      controller: searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search crop name',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  searchController.clear();
                                                  setState(() => searchQuery = '');
                                                  loadCrops();
                                                },
                                              )
                                            : null,
                                        isDense: true,
                                      ),
                                      onSubmitted: (value) {
                                        setState(() => searchQuery = value.trim());
                                        loadCrops();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedState.isEmpty
                                          ? _allStatesValue
                                          : selectedState,
                                      decoration: const InputDecoration(
                                        hintText: 'Filter by state',
                                        prefixIcon: Icon(Icons.location_on_outlined),
                                        isDense: true,
                                      ),
                                      items: _stateDropdownItems,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          selectedState =
                                              value == _allStatesValue ? '' : value;
                                        });
                                        loadCrops();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () {
                                          setState(() {
                                            searchQuery = searchController.text.trim();
                                          });
                                          loadCrops();
                                        },
                                        child: const Text('Apply'),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search crop name',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  searchController.clear();
                                                  setState(() => searchQuery = '');
                                                  loadCrops();
                                                },
                                              )
                                            : null,
                                        isDense: true,
                                      ),
                                      onSubmitted: (value) {
                                        setState(() => searchQuery = value.trim());
                                        loadCrops();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedState.isEmpty
                                          ? _allStatesValue
                                          : selectedState,
                                      decoration: const InputDecoration(
                                        hintText: 'Filter by state',
                                        prefixIcon: Icon(Icons.location_on_outlined),
                                        isDense: true,
                                      ),
                                      items: _stateDropdownItems,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          selectedState =
                                              value == _allStatesValue ? '' : value;
                                        });
                                        loadCrops();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = searchController.text.trim();
                                      });
                                      loadCrops();
                                    },
                                    child: const Text('Apply'),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      selectedSeason = 'All';
                                      selectedSoil = 'All';
                                      selectedState = '';
                                      searchQuery = '';
                                    });
                                    loadCrops();
                                  },
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text('Reset filters'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    toolsController.collapse();
                                    setState(() => toolsExpanded = false);
                                  },
                                  icon: const Icon(Icons.expand_less),
                                  label: const Text('Minimize tools'),
                                ),
                              ],
                            ),
                          ),
                          if (recommendations.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                LocalizationService.tr('Recommendations'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: recommendations.length > 8
                                    ? 8
                                    : recommendations.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final rec = recommendations[index];
                                  return Chip(
                                      label: Text(rec['crop_name']?.toString() ?? ''));
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildInputCalculatorCard(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'Season',
                              onSelected: (value) {
                                setState(() => selectedSeason = value);
                                loadCrops();
                              },
                              itemBuilder: (context) => seasons
                                  .map((season) => PopupMenuItem<String>(
                                        value: season,
                                        child: Text(season),
                                      ))
                                  .toList(),
                              child: Chip(
                                avatar: const Icon(Icons.event, size: 16),
                                label: Text('Season: $selectedSeason'),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Soil',
                              onSelected: (value) {
                                setState(() => selectedSoil = value);
                                loadCrops();
                              },
                              itemBuilder: (context) => soils
                                  .map((soil) => PopupMenuItem<String>(
                                        value: soil,
                                        child: Text(soil),
                                      ))
                                  .toList(),
                              child: Chip(
                                avatar: const Icon(Icons.terrain, size: 16),
                                label: Text('Soil: $selectedSoil'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${crops.length} crops',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                            IconButton(
                              tooltip: toolsExpanded ? 'Hide tools' : 'Show tools',
                              onPressed: () {
                                if (toolsExpanded) {
                                  toolsController.collapse();
                                } else {
                                  toolsController.expand();
                                }
                                setState(() => toolsExpanded = !toolsExpanded);
                              },
                              icon: Icon(
                                toolsExpanded ? Icons.expand_less : Icons.expand_more,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_canSelectCropForTasks)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected crops for tasks: ${mySelectedCropIds.length}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                ),
              )
            else if (crops.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 14),
                        Text(
                          'No crops match current filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing season, soil, or state filter.',
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.builder(
                  itemCount: crops.length,
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    return _buildCropCard(crop);
                  },
                ),
              ),
          ],
        ),
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      selectedForComparison.contains(crop.id)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selectedForComparison.contains(crop.id)
                          ? Colors.green
                          : Colors.grey,
                    ),
                    tooltip: 'Select for comparison',
                    onPressed: () {
                      setState(() {
                        if (selectedForComparison.contains(crop.id)) {
                          selectedForComparison.remove(crop.id);
                        } else {
                          selectedForComparison.add(crop.id);
                        }
                      });
                    },
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
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.blue),
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
              if (_canSelectCropForTasks) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: mySelectedCropIds.contains(crop.id)
                        ? null
                        : () => _showSelectCropForTasksDialog(crop),
                    icon: Icon(
                      mySelectedCropIds.contains(crop.id)
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                    ),
                    label: Text(
                      mySelectedCropIds.contains(crop.id)
                          ? 'Added for tasks'
                          : 'Add crop for tasks',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSelectCropForTasksDialog(Crop crop) async {
    final messenger = ScaffoldMessenger.of(context);
    final farmerId = AuthService.session?.farmerId;

    if (farmerId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Your account is not linked to a farmer profile yet. Please contact admin.',
          ),
        ),
      );
      return;
    }

    final areaController = TextEditingController(text: '1.0');
    DateTime plantingDate = DateTime.now();
    String selectedStatus = 'Growing';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final expectedHarvestDate = plantingDate.add(
              Duration(days: crop.growthDurationDays),
            );

            return AlertDialog(
              title: Text('Add ${crop.name} to my crops'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: areaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Area allocated (hectares)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Crop status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Planned', child: Text('Planned')),
                      DropdownMenuItem(
                          value: 'Growing', child: Text('Growing')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value ?? 'Growing';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Planting date'),
                    subtitle: Text(_formatDateForApi(plantingDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: plantingDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 3650)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );

                      if (pickedDate == null) return;
                      setDialogState(() {
                        plantingDate = pickedDate;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Expected harvest: ${_formatDateForApi(expectedHarvestDate)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final dialogNavigator = Navigator.of(dialogContext);
                    final area = double.tryParse(areaController.text.trim());
                    if (area == null || area <= 0) {
                      messenger.showSnackBar(
                        const SnackBar(
                            content:
                                Text('Enter a valid area greater than 0.')),
                      );
                      return;
                    }

                    final expectedYield =
                        (crop.expectedYieldPerHectare * area).round();

                    try {
                      await ApiService.createFarmerCrop({
                        'farmer': farmerId,
                        'crop': crop.id,
                        'planting_date': _formatDateForApi(plantingDate),
                        'expected_harvest_date': _formatDateForApi(
                          plantingDate
                              .add(Duration(days: crop.growthDurationDays)),
                        ),
                        'status': selectedStatus,
                        'area_allocated_hectares': area,
                        'expected_yield_kg': expectedYield,
                      });

                      if (!mounted) return;
                      dialogNavigator.pop();
                      await loadCrops();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              '${crop.name} added. You can now assign tasks for this crop.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      final handled = await AuthUiService.handleAuthError(
                        this.context,
                        e,
                        message: 'Session expired. Please sign in again.',
                      );
                      if (handled) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not add crop. ${e.toString().replaceFirst('Exception: ', '')}',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Add crop'),
                ),
              ],
            );
          },
        );
      },
    );

    areaController.dispose();
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
    final commonMistakes = _getCommonMistakes(crop);
    final area = double.tryParse(areaController.text.trim()) ?? 0;
    final hectares = areaUnit == 'Acre' ? area * 0.404686 : area;
    final seedKg = _estimateSeedKgPerHectare(crop) * hectares;
    final fertilizerKg = _estimateFertilizerKgPerHectare(crop) * hectares;
    final waterLitersPerWeek = crop.waterRequiredMmPerWeek * hectares * 10000;

    showDialog<void>(
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
                  _buildDetailRow(
                      LocalizationService.tr('Season'), crop.season),
                  _buildDetailRow(
                      LocalizationService.tr('Soil'), crop.soilType),
                  _buildDetailRow(LocalizationService.tr('Temperature'),
                      '${crop.optimalTemperatureMax}-¦C'),
                  _buildDetailRow(
                    LocalizationService.tr('Watering'),
                    guide['watering_schedule']?.toString() ?? '-',
                  ),
                  _buildDetailRow(
                    LocalizationService.tr('Fertilizer'),
                    guide['fertilizer_schedule']?.toString() ??
                        crop.fertilizerRequired,
                  ),
                  _buildDetailRow(
                    LocalizationService.tr('Disease'),
                    guide['disease_management']?.toString() ?? '-',
                  ),
                  _buildDetailRow(
                    LocalizationService.tr('Harvest'),
                    guide['harvesting_instructions']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Input estimate by land area',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow('Area', '${hectares.toStringAsFixed(2)} ha'),
                  _buildDetailRow('Seeds', '${seedKg.toStringAsFixed(1)} kg'),
                  _buildDetailRow(
                      'Fertilizer', '${fertilizerKg.toStringAsFixed(1)} kg'),
                  _buildDetailRow(
                    'Water / week',
                    '${waterLitersPerWeek.toStringAsFixed(0)} liters',
                  ),
                  const SizedBox(height: 12),
                  _buildGrowthStages(crop),
                  const SizedBox(height: 12),
                  const Text(
                    'Common mistakes to avoid',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...commonMistakes.map(
                    (mistake) {
                      final riskLevel = mistake['risk'] as String? ?? 'MEDIUM';
                      final riskColor = riskLevel == 'CRITICAL' 
                          ? Colors.red 
                          : riskLevel == 'HIGH' 
                              ? Colors.orange 
                              : Colors.yellow;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: riskColor,
                                width: 4,
                              ),
                            ),
                            color: riskColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      riskLevel,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: riskColor,
                                    labelStyle: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mistake['mistake'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Action: ${mistake['action']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    areaController.dispose();
    toolsController.dispose();
    super.dispose();
  }

  bool _matchesSelectedFilters(Crop crop) {
    final seasonMatches = _isSeasonMatch(crop.season, selectedSeason);
    final soilMatches = selectedSoil == 'All' || crop.soilType == selectedSoil;

    if (!seasonMatches || !soilMatches) {
      return false;
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      final inName = crop.name.toLowerCase().contains(q);
      final inDescription = (crop.description ?? '').toLowerCase().contains(q);
      if (!inName && !inDescription) {
        return false;
      }
    }

    if (selectedState.trim().isEmpty) {
      return true;
    }

    final stateNormalized = _normalizeStateInput(selectedState).toLowerCase();
    final description = (crop.description ?? '').toLowerCase();
    if (description.contains(stateNormalized)) {
      return true;
    }

    final aliases = _stateAliases.entries
        .where((entry) => entry.value.toLowerCase() == stateNormalized)
        .map((entry) => entry.key)
        .toList();
    return aliases.any((alias) => description.contains(alias.toLowerCase()));
  }

  String? _seasonQueryValue(String season) {
    if (season == 'All') return null;
    return _seasonApiMapping[season] ?? season;
  }

  bool _isSeasonMatch(String cropSeason, String selected) {
    if (selected == 'All') return true;

    final selectedApi = _seasonQueryValue(selected);
    if (selectedApi == null) return true;

    final normalizedCrop = cropSeason.trim().toLowerCase();
    return normalizedCrop == selectedApi.toLowerCase();
  }

  String _normalizeStateInput(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return '';

    final lower = input.toLowerCase();
    final alias = _stateAliases[lower];
    if (alias != null) return alias;

    for (final state in _indianStatesAndUts) {
      if (state.toLowerCase() == lower) {
        return state;
      }
    }

    return input;
  }

  static const String _allStatesValue = '__ALL_STATES__';

  List<DropdownMenuItem<String>> get _stateDropdownItems {
    return [
      const DropdownMenuItem<String>(
        value: _allStatesValue,
        child: Text('All Indian States'),
      ),
      ..._indianStatesAndUts.map(
        (state) => DropdownMenuItem<String>(
          value: state,
          child: Text(state),
        ),
      ),
    ];
  }

  Widget _buildInputCalculatorCard() {
    final area = double.tryParse(areaController.text.trim()) ?? 0;
    final hectares = areaUnit == 'Acre' ? area * 0.404686 : area;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input calculator (Seeds, Fertilizer, Water)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: areaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Land area',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    initialValue: areaUnit,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'Hectare', child: Text('Hectare')),
                      DropdownMenuItem(value: 'Acre', child: Text('Acre')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        areaUnit = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Area used for calculation: ${hectares.toStringAsFixed(2)} ha',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (crops.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Tap a crop card to see crop-specific totals.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthStages(Crop crop) {
    final totalDays =
        crop.growthDurationDays <= 0 ? 1 : crop.growthDurationDays;
    final stageDays = <int>[
      (totalDays * 0.15).round(),
      (totalDays * 0.35).round(),
      (totalDays * 0.3).round(),
      (totalDays * 0.2).round(),
    ];

    const labels = ['Sowing', 'Vegetative', 'Flowering', 'Harvest'];
    final colors = [
      Colors.brown.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.blue.shade300,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Growth stages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Container(
                margin:
                    EdgeInsets.only(right: index == labels.length - 1 ? 0 : 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stageDays[index]} d',
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (_getStageTasks(labels[index]).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getStageTasks(labels[index]).first,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, height: 1.2),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        _buildStageTasks(crop),
      ],
    );
  }

  /// Returns common mistakes with risk levels and preventive actions
  /// Enhanced to provide actionable guidance for farmers
  List<Map<String, dynamic>> _getCommonMistakes(Crop crop) {
    return [
      {
        'mistake': 'Late sowing for ${crop.season} season can reduce yield by 20-30%.',
        'risk': 'HIGH',
        'action': 'Follow recommended sowing window for ${crop.season}. Set task reminder 2 weeks before sowing date.',
        'impact': 'Directly affects yield and growth duration',
      },
      {
        'mistake': 'Over-watering beyond ${crop.waterRequiredMmPerWeek.toStringAsFixed(0)} mm/week causes root damage and fungal disease.',
        'risk': 'HIGH',
        'action': 'Use drip irrigation. Check soil moisture before watering. Follow watering schedule task reminders.',
        'impact': 'Damages root system and increases disease risk',
      },
      {
        'mistake': 'Ignoring soil type mismatch (recommended: ${crop.soilType}) reduces nutrient absorption.',
        'risk': 'MEDIUM',
        'action': 'Test soil before planting. Amend soil with organic matter if needed.',
        'impact': 'Reduces fertility and crop performance by 15-20%',
      },
      {
        'mistake': 'Skipping balanced fertilizer schedule delays growth stages and reduces yield.',
        'risk': 'MEDIUM',
        'action': 'Create fertilizer tasks at key growth stages. Use ${crop.fertilizerRequired} as recommended.',
        'impact': 'Extends growth cycle and reduces final yield',
      },
      {
        'mistake': 'Ignoring pest/disease symptoms during vegetative stage causes widespread loss.',
        'risk': 'CRITICAL',
        'action': 'Scout crops twice weekly. Apply preventive pesticide/fungicide at first sign.',
        'impact': 'Can destroy entire crop if not addressed early',
      },
    ];
  }

  /// Get key tasks for each growth stage
  List<String> _getStageTasks(String stage) {
    const stageTasks = {
      'Sowing': ['Prepare field', 'Sow seeds'],
      'Vegetative': ['Apply fertilizer', 'Weed control'],
      'Flowering': ['Monitor pests', 'Ensure water'],
      'Harvest': ['Check ripeness', 'Harvest'],
    };
    return stageTasks[stage] ?? [];
  }

  /// Build detailed task list for each growth stage
  Widget _buildStageTasks(Crop crop) {
    final stages = [
      {
        'name': 'Sowing',
        'tasks': [
          'Prepare field by removing weeds',
          'Apply base fertilizer to soil',
          'Sow seeds at recommended depth and spacing',
          'Provide initial irrigation',
        ]
      },
      {
        'name': 'Vegetative',
        'tasks': [
          'Apply nitrogen-rich fertilizer every 3-4 weeks',
          'Perform weed control 2-3 times',
          'Monitor for early pest/disease symptoms',
          'Provide consistent irrigation',
        ]
      },
      {
        'name': 'Flowering',
        'tasks': [
          'Reduce excessive nitrogen application',
          'Monitor pollinator activity',
          'Scout for flower-feeding pests daily',
          'Maintain soil moisture at flowering stage',
        ]
      },
      {
        'name': 'Harvest',
        'tasks': [
          'Monitor crop maturity indicators',
          'Reduce irrigation 2 weeks before harvest',
          'Harvest at optimal ripeness',
          'Handle carefully to minimize damage',
        ]
      },
    ];

    return ExpansionTile(
      title: const Text(
        'Stage-wise care tasks',
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stages
                .map((stage) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...(stage['tasks'] as List<String>)
                              .map((task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(fontSize: 12)),
                                        Expanded(
                                          child: Text(
                                            task,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showCropComparison() {
    final selectedCrops =
        crops.where((crop) => selectedForComparison.contains(crop.id)).toList();

    if (selectedCrops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 crops to compare.')),
      );
      return;
    }

    final comparison = selectedCrops.map((crop) {
      final score = _calculateSuitabilityScore(crop, selectedCrops);
      return {'crop': crop, 'score': score};
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop comparison'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: comparison.map((item) {
              final crop = item['crop'] as Crop;
              final score = item['score'] as double;
              final isBest = identical(item, comparison.first);
              
              // Calculate additional metrics
              final riskLevel = _calculateCropRisk(crop);
              final profitabilityIndex = (crop.expectedYieldPerHectare * 1.5) / (crop.growthDurationDays / 30);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBest
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isBest ? Colors.green : Colors.grey,
                    width: isBest ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            crop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isBest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Best fit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildComparisonRow('Suitability', '${score.toStringAsFixed(1)}/10', Colors.blue),
                    _buildComparisonRow('Risk Level', riskLevel, _getRiskColor(riskLevel)),
                    _buildComparisonRow('Profitability', '${profitabilityIndex.toStringAsFixed(1)}x', Colors.orange),
                    const SizedBox(height: 6),
                    Text(
                      'Season: ${crop.season} | Soil: ${crop.soilType}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Water: ${crop.waterRequiredMmPerWeek.toStringAsFixed(0)} mm/wk | Duration: ${crop.growthDurationDays}d',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Yield: ${crop.expectedYieldPerHectare.toStringAsFixed(0)} kg/ha',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
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

  /// Build a comparison metric row with color coding
  Widget _buildComparisonRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate risk level based on crop water and duration requirements
  String _calculateCropRisk(Crop crop) {
    if (crop.waterRequiredMmPerWeek > 80 || crop.growthDurationDays > 150) {
      return 'HIGH';
    } else if (crop.waterRequiredMmPerWeek > 50 || crop.growthDurationDays > 100) {
      return 'MEDIUM';
    }
    return 'LOW';
  }

  /// Get risk color for display
  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _calculateSuitabilityScore(Crop crop, List<Crop> selectedCrops) {
    final minWater = selectedCrops
        .map((item) => item.waterRequiredMmPerWeek)
        .reduce((a, b) => a < b ? a : b);
    final maxWater = selectedCrops
        .map((item) => item.waterRequiredMmPerWeek)
        .reduce((a, b) => a > b ? a : b);
    final minDuration = selectedCrops
        .map((item) => item.growthDurationDays)
        .reduce((a, b) => a < b ? a : b);
    final maxDuration = selectedCrops
        .map((item) => item.growthDurationDays)
        .reduce((a, b) => a > b ? a : b);
    final minYield = selectedCrops
        .map((item) => item.expectedYieldPerHectare)
        .reduce((a, b) => a < b ? a : b);
    final maxYield = selectedCrops
        .map((item) => item.expectedYieldPerHectare)
        .reduce((a, b) => a > b ? a : b);

    double normalize(double value, double min, double max,
        {bool reverse = false}) {
      if ((max - min).abs() < 0.0001) return 1.0;
      final v = (value - min) / (max - min);
      return reverse ? (1 - v) : v;
    }

    final seasonScore =
        selectedSeason == 'All' || crop.season == selectedSeason ? 1.0 : 0.0;
    final soilScore =
        selectedSoil == 'All' || crop.soilType == selectedSoil ? 1.0 : 0.0;
    final waterScore = normalize(
        crop.waterRequiredMmPerWeek, minWater, maxWater,
        reverse: true);
    final durationScore = normalize(crop.growthDurationDays.toDouble(),
        minDuration.toDouble(), maxDuration.toDouble(),
        reverse: true);
    final yieldScore =
        normalize(crop.expectedYieldPerHectare, minYield, maxYield);

    return (seasonScore * 30) +
        (soilScore * 20) +
        (waterScore * 20) +
        (durationScore * 15) +
        (yieldScore * 15);
  }

  double _estimateSeedKgPerHectare(Crop crop) {
    if (crop.season == 'Kharif') return 45;
    if (crop.season == 'Rabi') return 55;
    return 40;
  }

  double _estimateFertilizerKgPerHectare(Crop crop) {
    if (crop.expectedYieldPerHectare >= 5000) return 220;
    if (crop.expectedYieldPerHectare >= 3000) return 180;
    return 140;
  }
}
