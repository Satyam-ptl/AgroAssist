import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class CropScheduleScreen extends StatefulWidget {
  final int cropId;
  final String cropName;

  const CropScheduleScreen({
    required this.cropId,
    required this.cropName,
    super.key,
  });

  @override
  State<CropScheduleScreen> createState() => _CropScheduleScreenState();
}

class _CropScheduleScreenState extends State<CropScheduleScreen> {
  DateTime _plantingDate = DateTime.now();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = <String, dynamic>{};
  final Set<int> _expandedTasks = <int>{};

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  String get _plantingDateIso => DateFormat('yyyy-MM-dd').format(_plantingDate);

  Future<void> _loadSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final map = await ApiService.getCropSchedule(widget.cropId, _plantingDateIso);
      final list = List<Map<String, dynamic>>.from(
        ((map['schedule'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      )
        ..sort((a, b) => (a['due_date'] ?? '').toString().compareTo((b['due_date'] ?? '').toString()));

      if (!mounted) {
        return;
      }
      setState(() {
        _data = <String, dynamic>{...map, 'schedule': list};
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
    await _loadSchedule();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'overdue':
        return Colors.red;
      case 'due_today':
        return Colors.deepOrange;
      case 'due_soon':
        return Colors.amber.shade800;
      default:
        return Colors.green;
    }
  }

  String _statusLabel(String status, int daysRemaining) {
    if (status == 'overdue') {
      return '${daysRemaining.abs()} days overdue';
    }
    if (status == 'due_today') {
      return 'Due today!';
    }
    return 'In $daysRemaining days';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final schedule = List<Map<String, dynamic>>.from(
      (_data['schedule'] as List<dynamic>?) ?? const [],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.cropName} Schedule',
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
                    onRefresh: _loadSchedule,
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
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                'Planting Date: ${DateFormat('dd MMM yyyy').format(_plantingDate)}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          SizedBox(height: size.width * 0.03),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: size.width * 0.03,
                            mainAxisSpacing: size.width * 0.03,
                            childAspectRatio: 2.1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _summaryTile('Overdue', (_data['overdue'] ?? 0).toString(), Colors.red),
                              _summaryTile('Due Today', (_data['due_today'] ?? 0).toString(), Colors.deepOrange),
                              _summaryTile('Due Soon', (_data['due_soon'] ?? 0).toString(), Colors.amber.shade700),
                              _summaryTile('Upcoming', (_data['upcoming'] ?? 0).toString(), Colors.green),
                            ],
                          ),
                          SizedBox(height: size.width * 0.03),
                          if (schedule.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: size.height * 0.12),
                              child: const Center(
                                child: Text(
                                  'No care tasks available for this crop.',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              itemCount: schedule.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final item = schedule[index];
                                final taskId = (item['task_id'] as num?)?.toInt() ?? index;
                                final status = (item['reminder_status'] ?? 'upcoming').toString();
                                final daysRemaining = (item['days_remaining'] as num?)?.toInt() ?? 0;
                                final dueDateRaw = (item['due_date'] ?? '').toString();
                                DateTime? dueDate;
                                try {
                                  dueDate = DateTime.parse(dueDateRaw);
                                } catch (_) {}
                                final statusColor = _statusColor(status);
                                final expanded = _expandedTasks.contains(taskId);

                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: size.width * 0.02),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.04,
                                      vertical: size.width * 0.03,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (item['task_name'] ?? '').toString(),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: size.width * 0.02,
                                                vertical: size.width * 0.01,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                (item['frequency'] ?? 'Once').toString(),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: size.width * 0.02),
                                        Row(
                                          children: [
                                            const Icon(Icons.event, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                dueDate == null
                                                    ? dueDateRaw
                                                    : DateFormat('dd MMM yyyy').format(dueDate),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: size.width * 0.01),
                                        Row(
                                          children: [
                                            Icon(Icons.notifications_active, size: 16, color: statusColor),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _statusLabel(status, daysRemaining),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: size.width * 0.02),
                                        Text(
                                          (item['description'] ?? '').toString(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        SizedBox(height: size.width * 0.02),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (expanded) {
                                                _expandedTasks.remove(taskId);
                                              } else {
                                                _expandedTasks.add(taskId);
                                              }
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  (item['instructions'] ?? '').toString(),
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

  Widget _summaryTile(String label, String count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
