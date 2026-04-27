import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reminders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _farmers = <Map<String, dynamic>>[];
  int? _selectedFarmerId;

  final List<String> _tabs = const ['pending', 'in_progress', 'completed', 'overdue'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTasks();
        if (!AuthService.isAdmin) {
          _loadMyReminders();
        }
      }
    });
    _loadFarmers();
    _loadTasks();
    if (!AuthService.isAdmin) {
      _loadMyReminders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    if (!AuthService.isAdmin) {
      return;
    }
    try {
      final response = await ApiService.getFarmers(pageSize: 200);
      final results = List<Map<String, dynamic>>.from(
        ((response['results'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      if (!mounted) return;
      setState(() => _farmers = results);
    } catch (_) {}
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);

    try {
      final map = await ApiService.getTasks(
        status: _tabs[_tabController.index],
        farmerId: AuthService.isAdmin ? _selectedFarmerId : null,
      );
      final results = List<Map<String, dynamic>>.from(
        ((map['results'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      if (!mounted) return;
      setState(() {
        _tasks = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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

  Future<void> _loadMyReminders() async {
    try {
      final items = await ApiService.getMyReminders();
      final mapped = items
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() => _reminders = mapped);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (AuthService.isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedFarmerId,
                  items: [
                    const DropdownMenuItem<int?>(child: Text('All Farmers')),
                    ..._farmers.map(
                      (f) => DropdownMenuItem<int?>(
                        value: (f['id'] as num?)?.toInt(),
                        child: Text(
                          '${(f['first_name'] ?? '').toString()} ${(f['last_name'] ?? '').toString()}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFarmerId = value);
                    _loadTasks();
                  },
                  decoration: const InputDecoration(labelText: 'Filter by farmer'),
                ),
              ),
            if (!AuthService.isAdmin && _reminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Reminders',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _reminders.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final reminder = _reminders[index];
                          final message = (reminder['message'] ?? '').toString();
                          final type = (reminder['reminder_type'] ?? 'custom').toString();
                          final sentAtRaw = (reminder['sent_at'] ?? '').toString();
                          final sentAt = DateTime.tryParse(sentAtRaw);
                          final sentAtText = sentAt == null
                              ? sentAtRaw
                              : DateFormat('dd MMM, hh:mm a').format(sentAt.toLocal());

                          return Container(
                            width: 280,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFE8F5E9),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B5E20),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Text(
                                    message,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                                Text(
                                  sentAtText,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _tasks.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return _buildTaskCard(task);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final dueDateText = (task['due_date'] ?? '').toString();
    final dueDate = DateTime.tryParse(dueDateText);
    final now = DateTime.now();
    final dueColor = dueDate == null
        ? Colors.grey
        : DateUtils.dateOnly(dueDate).isBefore(DateUtils.dateOnly(now))
            ? Colors.red
            : DateUtils.isSameDay(dueDate, now)
                ? Colors.orange
                : Colors.grey;

    final importance = (task['importance'] ?? 'Medium').toString().toLowerCase();
    final priorityColor = importance == 'high' || importance == 'critical'
        ? Colors.red
        : importance == 'medium'
            ? Colors.orange
            : Colors.green;

    final title = (task['task_name'] ?? '').toString();
    final farmerName = (task['farmer_name'] ?? '').toString();
    final status = (task['status'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        onTap: () => _openTaskBottomSheet(task),
        title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farmerName,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dueDate == null ? 'No due date' : DateFormat('dd MMM yyyy').format(dueDate),
                    style: TextStyle(color: dueColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Chip(
                  backgroundColor: priorityColor.withValues(alpha: 0.2),
                  label: Text(
                    (task['importance'] ?? 'Medium').toString(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(status, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
    );
  }

  Future<void> _openTaskBottomSheet(Map<String, dynamic> task) async {
    final id = (task['id'] as num?)?.toInt();
    if (id == null) {
      return;
    }

    String currentStatus = (task['status'] ?? 'Pending').toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (task['task_name'] ?? '').toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (task['task_description'] ?? '').toString(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    const Text('Change Status:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statusButton('Pending', currentStatus, setSheetState, id),
                        _statusButton('In Progress', currentStatus, setSheetState, id),
                        _statusButton('Completed', currentStatus, setSheetState, id),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await _loadTasks();
  }

  Widget _statusButton(
    String status,
    String currentStatus,
    void Function(void Function()) setSheetState,
    int taskId,
  ) {
    final selected = currentStatus.toLowerCase() == status.toLowerCase();
    return selected
        ? ElevatedButton(
            onPressed: null,
            child: Text(status, overflow: TextOverflow.ellipsis, maxLines: 1),
          )
        : OutlinedButton(
            onPressed: () async {
              try {
                await ApiService.updateTaskStatus(taskId, status.toLowerCase().replaceAll(' ', '_'));
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Task status updated', overflow: TextOverflow.ellipsis, maxLines: 1),
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
            },
            child: Text(status, overflow: TextOverflow.ellipsis, maxLines: 1),
          );
  }
}
