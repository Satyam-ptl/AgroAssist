import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _allFarmers = true;
  bool _sending = false;
  String _template = 'Please complete your pending tasks';

  final TextEditingController _customController = TextEditingController();
  final Set<int> _selectedFarmerIds = <int>{};
  List<Map<String, dynamic>> _farmers = <Map<String, dynamic>>[];
  final Map<int, int> _pendingTaskCounts = <int, int>{};

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    try {
      final response = await ApiService.getFarmers(pageSize: 200);
      final items = List<Map<String, dynamic>>.from(
        ((response['results'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final pendingCounts = <int, int>{};
      for (final farmer in items) {
        final farmerId = (farmer['id'] as num?)?.toInt();
        if (farmerId == null) {
          continue;
        }
        try {
          final tasksResp = await ApiService.getTasks(
            status: 'pending',
            farmerId: farmerId,
            pageSize: 1,
          );
          pendingCounts[farmerId] = (tasksResp['count'] as num?)?.toInt() ?? 0;
        } catch (_) {
          pendingCounts[farmerId] = 0;
        }
      }
      if (!mounted) return;
      setState(() {
        _farmers = items;
        _pendingTaskCounts
          ..clear()
          ..addAll(pendingCounts);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAdmin) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Only admin can send reminders.'))),
      );
    }

    final message = _template == 'Custom message...'
        ? _customController.text.trim()
        : _template;
    final sendCount = _allFarmers ? _farmers.length : _selectedFarmerIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Reminder')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send To:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Farmers'),
                    selected: _allFarmers,
                    onSelected: (_) => setState(() => _allFarmers = true),
                  ),
                  ChoiceChip(
                    label: const Text('Select Farmers'),
                    selected: !_allFarmers,
                    onSelected: (_) => setState(() => _allFarmers = false),
                  ),
                ],
              ),
              if (!_allFarmers)
                ListView.builder(
                  itemCount: _farmers.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final farmer = _farmers[index];
                    final id = (farmer['id'] as num?)?.toInt() ?? 0;
                    final checked = _selectedFarmerIds.contains(id);
                    final name = '${(farmer['first_name'] ?? '').toString()} ${(farmer['last_name'] ?? '').toString()}'.trim();
                    final pendingCount = _pendingTaskCounts[id] ?? 0;
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedFarmerIds.add(id);
                          } else {
                            _selectedFarmerIds.remove(id);
                          }
                        });
                      },
                      title: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
                      subtitle: Text(
                        'Pending tasks: $pendingCount',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 14),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _template,
                items: const [
                  DropdownMenuItem(value: 'Please complete your pending tasks', child: Text('Please complete your pending tasks')),
                  DropdownMenuItem(value: 'Your tasks are overdue, please take action', child: Text('Your tasks are overdue, please take action')),
                  DropdownMenuItem(value: 'Reminder: Farm tasks need your attention', child: Text('Reminder: Farm tasks need your attention')),
                  DropdownMenuItem(value: 'Custom message...', child: Text('Custom message...')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _template = value);
                },
              ),
              if (_template == 'Custom message...') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Enter custom message'),
                ),
              ],
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Will send to: $sendCount farmers', overflow: TextOverflow.ellipsis, maxLines: 1),
                      const SizedBox(height: 4),
                      Text('Message: $message', overflow: TextOverflow.ellipsis, maxLines: 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final message = _template == 'Custom message...'
        ? _customController.text.trim()
        : _template;

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message is required', overflow: TextOverflow.ellipsis, maxLines: 1),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await ApiService.sendReminder({
        'farmer_ids': _allFarmers ? 'all' : _selectedFarmerIds.toList(),
        'message': message,
        'reminder_type': _template.toLowerCase().contains('overdue') ? 'overdue' : 'pending',
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminders sent', overflow: TextOverflow.ellipsis, maxLines: 1),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
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
}
