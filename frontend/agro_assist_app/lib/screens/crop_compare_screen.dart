import 'package:flutter/material.dart';

import '../services/api_service.dart';

class CropCompareScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initiallySelected;

  const CropCompareScreen({
    super.key,
    this.initiallySelected = const [],
  });

  @override
  State<CropCompareScreen> createState() => _CropCompareScreenState();
}

class _CropCompareScreenState extends State<CropCompareScreen> {
  bool _loading = true;
  String _query = '';
  List<Map<String, dynamic>> _allCrops = <Map<String, dynamic>>[];
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    for (final crop in widget.initiallySelected) {
      final id = (crop['id'] as num?)?.toInt();
      if (id != null) {
        _selectedIds.add(id);
      }
    }
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _loading = true;
    });

    try {
      final map = await ApiService.getCrops(pageSize: 200);
      final crops = List<Map<String, dynamic>>.from(
        ((map['results'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _allCrops = crops;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final selectedCount = _selectedIds.length;
    final filtered = _allCrops.where((crop) {
      final name = (crop['name'] ?? '').toString().toLowerCase();
      return name.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compare Crops',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.width * 0.03,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select 2 or 3 crops to compare',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: size.width * 0.03),
                        TextField(
                          onChanged: (value) => setState(() => _query = value.trim()),
                          decoration: const InputDecoration(
                            hintText: 'Search crops',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final crop = filtered[index];
                          final id = (crop['id'] as num?)?.toInt() ?? -1;
                          final selected = _selectedIds.contains(id);
                          final season = (crop['season'] ?? '').toString();

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.width * 0.015,
                            ),
                            child: CheckboxListTile(
                              value: selected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    if (_selectedIds.length < 3) {
                                      _selectedIds.add(id);
                                    }
                                  } else {
                                    _selectedIds.remove(id);
                                  }
                                });
                              },
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (crop['name'] ?? '').toString(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.02,
                                      vertical: size.width * 0.008,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      season,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.width * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedCount selected',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: selectedCount < 2 || selectedCount > 3
                    ? null
                    : () {
                        final selectedCrops = _allCrops
                            .where((crop) => _selectedIds.contains((crop['id'] as num?)?.toInt() ?? -1))
                            .toList();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CropComparisonTableScreen(crops: selectedCrops),
                          ),
                        );
                      },
                child: const Text(
                  'Compare',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CropComparisonTableScreen extends StatelessWidget {
  final List<Map<String, dynamic>> crops;

  const CropComparisonTableScreen({required this.crops, super.key});

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestGrowth = crops.isEmpty
        ? 0
        : crops
            .map((c) => _toDouble(c['growth_duration_days']))
            .reduce((a, b) => a < b ? a : b);
    final lowestWater = crops.isEmpty
        ? 0
        : crops
            .map((c) => _toDouble(c['water_required_mm_per_week']))
            .reduce((a, b) => a < b ? a : b);
    final highestYield = crops.isEmpty
        ? 0
        : crops
            .map((c) => _toDouble(c['expected_yield_per_hectare']))
            .reduce((a, b) => a > b ? a : b);

    Map<String, dynamic> recommendation = crops.isEmpty ? <String, dynamic>{} : crops.first;
    double bestScore = -999999;
    for (final crop in crops) {
      final yield = _toDouble(crop['expected_yield_per_hectare']);
      final water = _toDouble(crop['water_required_mm_per_week']);
      final score = yield - (water * 4);
      if (score > bestScore) {
        bestScore = score;
        recommendation = crop;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crop Comparison',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.width * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: <int, TableColumnWidth>{
                    0: const FixedColumnWidth(140),
                    for (int i = 0; i < crops.length; i++) i + 1: const FixedColumnWidth(120),
                  },
                  children: [
                    TableRow(
                      children: [
                        _headerCell('Property', Colors.grey.shade200),
                        ...crops.map((crop) => _headerCell((crop['name'] ?? '').toString(), Colors.green.shade100)),
                      ],
                    ),
                    _propertyRow('Season', (c) => (c['season'] ?? '').toString()),
                    _propertyRow(
                      'Growth Duration (days)',
                      (c) => (c['growth_duration_days'] ?? '').toString(),
                      highlightIf: (c) => _toDouble(c['growth_duration_days']) == shortestGrowth,
                    ),
                    _propertyRow('Soil Type', (c) => (c['soil_type'] ?? '').toString()),
                    _propertyRow(
                      'Water/Week (mm)',
                      (c) => (c['water_required_mm_per_week'] ?? '').toString(),
                      highlightIf: (c) => _toDouble(c['water_required_mm_per_week']) == lowestWater,
                    ),
                    _propertyRow('Fertilizer', (c) => (c['fertilizer_required'] ?? '').toString()),
                    _propertyRow(
                      'Expected Yield (per hectare)',
                      (c) => (c['expected_yield_per_hectare'] ?? '').toString(),
                      highlightIf: (c) => _toDouble(c['expected_yield_per_hectare']) == highestYield,
                    ),
                    _propertyRow('Optimal Temperature', (c) => '${c['optimal_temperature'] ?? '-'}°C'),
                    _propertyRow('Optimal Humidity', (c) => '${c['optimal_humidity'] ?? '-'}%'),
                  ],
                ),
              ),
              SizedBox(height: size.width * 0.04),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.width * 0.03,
                  ),
                  child: Text(
                    'Based on comparison, ${(recommendation['name'] ?? '').toString()} is recommended because it has the strongest yield to water-use ratio among selected crops.',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _propertyRow(
    String property,
    String Function(Map<String, dynamic>) valueBuilder, {
    bool Function(Map<String, dynamic>)? highlightIf,
  }) {
    return TableRow(
      children: [
        _propertyCell(property),
        ...crops.map((crop) {
          final highlighted = highlightIf?.call(crop) ?? false;
          return _valueCell(valueBuilder(crop), highlight: highlighted);
        }),
      ],
    );
  }

  Widget _headerCell(String text, Color bgColor) {
    return Container(
      height: 48,
      color: bgColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _propertyCell(String text) {
    return Container(
      height: 48,
      color: Colors.grey.shade200,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _valueCell(String text, {bool highlight = false}) {
    return Container(
      height: 48,
      color: highlight ? Colors.green.shade100 : Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }
}
