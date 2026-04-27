import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'calculator_screen.dart';
import 'crop_schedule_screen.dart';
import 'growth_stages_screen.dart';

class CropDetailScreen extends StatefulWidget {
  final int cropId;
  final String cropName;

  const CropDetailScreen({
    required this.cropId,
    required this.cropName,
    super.key,
  });

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _details = <String, dynamic>{};
  Map<String, dynamic> _alerts = <String, dynamic>{};
  Map<String, dynamic> _schedulePreview = <String, dynamic>{};

  final Set<int> _expandedAlertIds = <int>{};
  final TextEditingController _quickAreaController = TextEditingController();
  bool _savingCrop = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await ApiService.getCropDetails(widget.cropId);
      final alerts = await ApiService.getCropAlerts(widget.cropId);
      final schedule = await ApiService.getCropSchedule(
        widget.cropId,
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
        _alerts = alerts;
        _schedulePreview = schedule;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cropName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Growth Stages'),
            Tab(text: 'Task Schedule'),
            Tab(text: 'Alerts & Tips'),
            Tab(text: 'Calculator'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                      child: Text(
                        _error!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(size),
                      _buildGrowthPreviewTab(size),
                      _buildSchedulePreviewTab(size),
                      _buildAlertsTab(size),
                      _buildCalculatorTab(size),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOverviewTab(Size size) {
    final states = List<dynamic>.from((_details['states_list'] as List<dynamic>?) ?? const []);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.width * 0.03,
        ),
        child: Column(
          children: [
            if (!AuthService.isAdmin)
              SizedBox(
                width: size.width,
                child: ElevatedButton.icon(
                  onPressed: _savingCrop ? null : _showStartGrowingSheet,
                  icon: _savingCrop
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    _savingCrop ? 'Adding...' : 'Start Growing This Crop',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            if (!AuthService.isAdmin) SizedBox(height: size.width * 0.03),
            _infoCard('Basic Info', [
              _pair('Name', (_details['name'] ?? '').toString()),
              _pair('Season', (_details['season'] ?? '').toString()),
              _pair('Soil Type', (_details['soil_type'] ?? '').toString()),
              _pair('Growth Duration', '${(_details['growth_duration_days'] ?? '-') } days'),
            ]),
            SizedBox(height: size.width * 0.03),
            _infoCard('Optimal Conditions', [
              _pair('Temperature', '${(_details['optimal_temperature'] ?? '-')}°C'),
              _pair('Humidity', '${(_details['optimal_humidity'] ?? '-')}%'),
              _pair('Soil Moisture', '${(_details['optimal_soil_moisture'] ?? '-')}%'),
              _pair('Water/Week', '${(_details['water_required_mm_per_week'] ?? '-')} mm'),
            ]),
            SizedBox(height: size.width * 0.03),
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.width * 0.03,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'States Where Grown',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: size.width * 0.02),
                    if (states.isEmpty)
                      const Text(
                        'No states available.',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: states
                            .map(
                              (s) => Chip(
                                label: Text(
                                  s.toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStartGrowingSheet() async {
    final areaController = TextEditingController(text: '1');
    DateTime plantingDate = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add to My Growing Crops',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: plantingDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheetState(() => plantingDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Planting Date'),
                        child: Text(DateFormat('dd MMM yyyy').format(plantingDate)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Area Allocated (Hectares)',
                        hintText: 'e.g. 1.5',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final area = double.tryParse(areaController.text.trim());
                          if (area == null || area <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid area in hectares.',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.of(ctx).pop();
                          await _addCropForGrowing(plantingDate, area);
                        },
                        child: const Text('Save Crop'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addCropForGrowing(DateTime plantingDate, double area) async {
    setState(() => _savingCrop = true);
    try {
      final growthDays = (_details['growth_duration_days'] as num?)?.toInt();
      final expectedHarvestDate = growthDays == null
          ? null
          : DateFormat('yyyy-MM-dd').format(plantingDate.add(Duration(days: growthDays)));

      await ApiService.addMyFarmerCrop(
        cropId: widget.cropId,
        plantingDate: DateFormat('yyyy-MM-dd').format(plantingDate),
        areaAllocatedHectares: area,
        expectedHarvestDate: expectedHarvestDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.cropName} added to your growing crops.',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingCrop = false);
      }
    }
  }

  Widget _buildGrowthPreviewTab(Size size) {
    final stages = List<Map<String, dynamic>>.from(
      ((_details['growth_stages'] as List<dynamic>?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    )
      ..sort((a, b) => ((a['stage_number'] as num?)?.toInt() ?? 0).compareTo((b['stage_number'] as num?)?.toInt() ?? 0));

    final preview = stages.take(2).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.width * 0.03,
      ),
      child: Column(
        children: [
          SizedBox(
            width: size.width,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GrowthStagesScreen(
                      cropId: widget.cropId,
                      cropName: widget.cropName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.timeline),
              label: const Text(
                'Open Full Growth Timeline',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(height: size.width * 0.03),
          ...preview.map(
            (stage) => Card(
              margin: EdgeInsets.symmetric(vertical: size.width * 0.015),
              child: ListTile(
                title: Text(
                  'Stage ${(stage['stage_number'] ?? '-')}: ${(stage['stage_name'] ?? '').toString()}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  'Duration: ${(stage['duration_days'] ?? '-')} days',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          if (preview.isEmpty)
            const Card(
              child: ListTile(
                title: Text(
                  'No growth stages available.',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreviewTab(Size size) {
    final tasks = List<Map<String, dynamic>>.from(
      ((_schedulePreview['schedule'] as List<dynamic>?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    )
      ..sort((a, b) => (a['due_date'] ?? '').toString().compareTo((b['due_date'] ?? '').toString()));

    final upcoming = tasks.where((task) {
      final status = (task['reminder_status'] ?? '').toString();
      return status == 'due_today' || status == 'due_soon' || status == 'upcoming';
    }).take(2).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.width * 0.03,
      ),
      child: Column(
        children: [
          SizedBox(
            width: size.width,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CropScheduleScreen(
                      cropId: widget.cropId,
                      cropName: widget.cropName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.event_note),
              label: const Text(
                'Open Full Task Schedule',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(height: size.width * 0.03),
          ...upcoming.map(
            (task) => Card(
              margin: EdgeInsets.symmetric(vertical: size.width * 0.015),
              child: ListTile(
                title: Text(
                  (task['task_name'] ?? '').toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  'Due: ${(task['due_date'] ?? '').toString()} | ${(task['reminder_status'] ?? '').toString()}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          if (upcoming.isEmpty)
            const Card(
              child: ListTile(
                title: Text(
                  'No upcoming tasks available.',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(Size size) {
    final alerts = List<Map<String, dynamic>>.from(
      ((_alerts['alerts'] as List<dynamic>?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.width * 0.03,
      ),
      child: Column(
        children: alerts.isEmpty
            ? [
                const Card(
                  child: ListTile(
                    title: Text(
                      'No alerts available.',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ]
            : alerts.asMap().entries.map((entry) {
                final index = entry.key;
                final alert = entry.value;
                final expanded = _expandedAlertIds.contains(index);
                final colors = _alertColors((alert['type'] ?? '').toString());
                final icon = _alertIcon((alert['type'] ?? '').toString());

                return Card(
                  color: colors.background,
                  margin: EdgeInsets.symmetric(vertical: size.width * 0.015),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.width * 0.025,
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 32, color: colors.foreground),
                            SizedBox(width: size.width * 0.02),
                            Expanded(
                              child: Text(
                                (alert['title'] ?? '').toString(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (alert['severity'] ?? '').toString().toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(fontSize: 10, color: colors.foreground, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.width * 0.015),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (expanded) {
                                _expandedAlertIds.remove(index);
                              } else {
                                _expandedAlertIds.add(index);
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (alert['message'] ?? '').toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: expanded ? 10 : 3,
                                ),
                              ),
                              Icon(expanded ? Icons.expand_less : Icons.expand_more),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
      ),
    );
  }

  Widget _buildCalculatorTab(Size size) {
    final crop = _details;
    final yieldPerHectare = _toDouble(crop['expected_yield_per_hectare']);
    final area = double.tryParse(_quickAreaController.text.trim()) ?? 0;
    final hectares = area * 0.4047;
    final quickYield = hectares * yieldPerHectare;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.width * 0.03,
      ),
      child: Column(
        children: [
          SizedBox(
            width: size.width,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CalculatorScreen(crop: crop),
                  ),
                );
              },
              icon: const Icon(Icons.calculate),
              label: const Text(
                'Calculate Inputs',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(height: size.width * 0.03),
          TextField(
            controller: _quickAreaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Quick Preview Area (Acres)',
              hintText: 'e.g. 2',
            ),
          ),
          SizedBox(height: size.width * 0.03),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.width * 0.03,
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      area <= 0
                          ? 'Enter area to see quick estimate.'
                          : 'Estimated yield: ${quickYield.toStringAsFixed(2)} kg',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _pair(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  _AlertColors _alertColors(String type) {
    switch (type) {
      case 'pest':
        return _AlertColors(Colors.orange.shade50, Colors.orange.shade900);
      case 'disease':
        return _AlertColors(Colors.red.shade50, Colors.red.shade900);
      case 'temperature':
        return _AlertColors(Colors.blue.shade50, Colors.blue.shade900);
      default:
        return _AlertColors(Colors.cyan.shade50, Colors.cyan.shade900);
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'pest':
        return Icons.bug_report;
      case 'disease':
        return Icons.local_hospital;
      case 'temperature':
        return Icons.thermostat;
      default:
        return Icons.water_drop;
    }
  }
}

class _AlertColors {
  final Color background;
  final Color foreground;

  _AlertColors(this.background, this.foreground);
}
