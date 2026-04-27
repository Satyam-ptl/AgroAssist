import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class GrowthStagesScreen extends StatefulWidget {
  final int cropId;
  final String cropName;

  const GrowthStagesScreen({
    required this.cropId,
    required this.cropName,
    super.key,
  });

  @override
  State<GrowthStagesScreen> createState() => _GrowthStagesScreenState();
}

class _GrowthStagesScreenState extends State<GrowthStagesScreen> {
  bool _loading = true;
  String? _error;
  DateTime _plantingDate = DateTime.now();
  List<Map<String, dynamic>> _stages = <Map<String, dynamic>>[];
  final Set<int> _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  Future<void> _loadStages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await ApiService.getCropDetails(widget.cropId);
      final stages = List<Map<String, dynamic>>.from(
        ((details['growth_stages'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      )..sort(
          (a, b) => ((a['stage_number'] as num?)?.toInt() ?? 0).compareTo(
            (b['stage_number'] as num?)?.toInt() ?? 0,
          ),
        );

      if (!mounted) {
        return;
      }
      setState(() {
        _stages = stages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickPlantingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _plantingDate = picked;
    });
  }

  int _stageStartOffset(int index) {
    int offset = 0;
    for (int i = 0; i < index; i++) {
      offset += (_stages[i]['duration_days'] as num?)?.toInt() ?? 0;
    }
    return offset;
  }

  int _currentStageIndex() {
    final elapsed = DateTime.now().difference(_plantingDate).inDays;
    if (elapsed < 0 || _stages.isEmpty) {
      return 0;
    }
    int total = 0;
    for (int i = 0; i < _stages.length; i++) {
      total += (_stages[i]['duration_days'] as num?)?.toInt() ?? 0;
      if (elapsed < total) {
        return i;
      }
    }
    return _stages.length - 1;
  }

  IconData _stageIcon(String stageName) {
    final lower = stageName.toLowerCase();
    if (lower.contains('germination')) return Icons.spa;
    if (lower.contains('seedling')) return Icons.eco;
    if (lower.contains('vegetative')) return Icons.grass;
    if (lower.contains('flower')) return Icons.local_florist;
    if (lower.contains('fruit')) return Icons.agriculture;
    if (lower.contains('maturity')) return Icons.star;
    if (lower.contains('harvest')) return Icons.content_cut;
    return Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalDays = _stages.fold<int>(
      0,
      (sum, item) => sum + ((item['duration_days'] as num?)?.toInt() ?? 0),
    );
    final currentIndex = _currentStageIndex();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.cropName} Growth Stages',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
                : RefreshIndicator(
                    onRefresh: _loadStages,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.width * 0.03,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: size.width,
                            child: OutlinedButton.icon(
                              onPressed: _pickPlantingDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'When did you plant? ${DateFormat('dd MMM yyyy').format(_plantingDate)}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          SizedBox(height: size.width * 0.03),
                          Container(
                            width: size.width,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.width * 0.04,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Duration: $totalDays days',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: size.width * 0.01),
                                Text(
                                  '${_stages.length} stages',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: size.width * 0.01),
                                if (_stages.isNotEmpty)
                                  Text(
                                    'You are in Stage ${(_stages[currentIndex]['stage_number'] ?? 1)}: ${(_stages[currentIndex]['stage_name'] ?? '').toString()}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.width * 0.03),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stages.length,
                            itemBuilder: (context, index) {
                              final stage = _stages[index];
                              final stageId = (stage['id'] as num?)?.toInt() ?? index;
                              final stageNumber = (stage['stage_number'] as num?)?.toInt() ?? (index + 1);
                              final duration = (stage['duration_days'] as num?)?.toInt() ?? 0;
                              final expanded = _expanded.contains(stageId);

                              final elapsed = DateTime.now().difference(_plantingDate).inDays;
                              final start = _stageStartOffset(index);
                              final end = start + duration;
                              final Color dotColor;
                              if (elapsed >= end) {
                                dotColor = Colors.green;
                              } else if (elapsed >= start) {
                                dotColor = Colors.orange;
                              } else {
                                dotColor = Colors.grey;
                              }

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      width: size.width * 0.12,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                                          ),
                                          if (index != _stages.length - 1)
                                            Expanded(
                                              child: Container(
                                                width: 3,
                                                color: Colors.grey.shade300,
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Card(
                                        margin: EdgeInsets.only(bottom: size.width * 0.025),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: size.width * 0.035,
                                            vertical: size.width * 0.03,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 13,
                                                    backgroundColor: Colors.green.shade100,
                                                    child: Text(
                                                      '$stageNumber',
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      (stage['stage_name'] ?? '').toString(),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                                    ),
                                                  ),
                                                  Icon(_stageIcon((stage['stage_name'] ?? '').toString()), color: Colors.green),
                                                ],
                                              ),
                                              SizedBox(height: size.width * 0.015),
                                              Text(
                                                'Duration: $duration days',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              SizedBox(height: size.width * 0.01),
                                              Row(
                                                children: [
                                                  const Icon(Icons.thermostat, size: 16),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${stage['optimal_temperature'] ?? '-'}°C',
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  const Icon(Icons.water_drop, size: 16),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${stage['optimal_humidity'] ?? '-'}% RH',
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: size.width * 0.015),
                                              Text(
                                                (stage['description'] ?? '').toString(),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: expanded ? 6 : 2,
                                                style: const TextStyle(color: Colors.black87),
                                              ),
                                              SizedBox(height: size.width * 0.01),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (expanded) {
                                                      _expanded.remove(stageId);
                                                    } else {
                                                      _expanded.add(stageId);
                                                    }
                                                  });
                                                },
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        (stage['care_instructions'] ?? '').toString(),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: expanded ? 8 : 2,
                                                        style: const TextStyle(color: Colors.black54),
                                                      ),
                                                    ),
                                                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
