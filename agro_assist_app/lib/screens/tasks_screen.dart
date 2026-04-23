import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/auth_ui_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_surface_card.dart';
import '../widgets/section_title.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<FarmerTask> tasks = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'All';

  final List<String> statuses = const [
    'All',
    'Pending',
    'In Progress',
    'Completed',
    'Overdue',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<List<Map<String, dynamic>>> _fetchFarmerCropOptions() async {
    final response = await ApiService.getFarmerCrops(pageSize: 200);
    final List<dynamic> results = response['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((crop) => {
              'id': (crop['id'] as num?)?.toInt(),
              'farmerId': (crop['farmer'] as num?)?.toInt(),
              'farmerName': crop['farmer_name']?.toString() ?? '',
              'cropName': crop['crop_name']?.toString() ?? 'Crop',
              'status': crop['status']?.toString() ?? '',
            })
        .where((crop) => crop['id'] != null)
        .toList();
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getTasks(
        status: selectedStatus == 'All' ? null : selectedStatus,
        pageSize: 100,
      );

      final List<dynamic> tasksJson = (response['results'] as List<dynamic>? ?? []);
      final loadedTasks = tasksJson
          .map((json) => FarmerTask.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      setState(() {
        tasks = loadedTasks;
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
        errorMessage = 'Failed to load tasks: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Tasks')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthUiService.confirmAndLogout(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadTasks,
            tooltip: LocalizationService.tr('Refresh'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: 'Task Operations',
                  subtitle: 'Track work progress and close tasks quickly.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: statuses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      return ChoiceChip(
                        selected: selectedStatus == status,
                        label: Text(status),
                        onSelected: (_) {
                          setState(() => selectedStatus = status);
                          loadTasks();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadTasks,
                              child: Text(LocalizationService.tr('Retry')),
                            ),
                          ],
                        ),
                      )
                    : tasks.isEmpty
                        ? Center(child: Text(LocalizationService.tr('No tasks found')))
                        : RefreshIndicator(
                            onRefresh: loadTasks,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) => _buildTaskCard(tasks[index], colorScheme),
                            ),
                          ),
          ),
        ],
      ),
        floatingActionButton: AuthService.session != null
          ? FloatingActionButton.extended(
              heroTag: 'tasks-create-fab',
              onPressed: _showCreateTaskDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
            )
          : null,
    );
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final Future<List<Map<String, dynamic>>> farmerCropsFuture =
        _fetchFarmerCropOptions();
    DateTime? dueDate;
    String selectedImportance = 'Medium';
    int selectedPriority = 5;
    int? selectedFarmerCropId;
    int? selectedFarmerId;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Create New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: farmerCropsFuture,
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? const <Map<String, dynamic>>[];

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Unable to load your crops. Please close and retry.',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'No farmer crop found. Add a crop first to create tasks.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        );
                      }

                      final hasSelection = items.any((item) => item['id'] == selectedFarmerCropId);
                      if (!hasSelection && selectedFarmerCropId != null) {
                        selectedFarmerCropId = null;
                        selectedFarmerId = null;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedFarmerCropId,
                          decoration: const InputDecoration(labelText: 'Select Crop'),
                          items: items
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item['id'] as int,
                                  child: Text(
                                    '${item['cropName']} (${item['farmerName']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedFarmerCropId = value;
                              final selected = items.firstWhere(
                                (item) => item['id'] == value,
                                orElse: () => const <String, dynamic>{},
                              );
                              selectedFarmerId = selected['farmerId'] as int?;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      hintText: 'Enter task name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the task',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due Date'),
                    trailing: Text(
                      dueDate == null
                          ? 'Select date'
                          : DateFormat('dd MMM yyyy').format(dueDate!),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setDialogState(() => dueDate = pickedDate);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Low (1)')),
                      DropdownMenuItem(value: 5, child: Text('Medium (5)')),
                      DropdownMenuItem(value: 10, child: Text('High (10)')),
                    ],
                    onChanged: (val) => selectedPriority = val ?? 5,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedImportance,
                    decoration: const InputDecoration(labelText: 'Importance'),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                    ],
                    onChanged: (val) => selectedImportance = val ?? 'Medium',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final dialogNavigator = Navigator.of(dialogContext);
                  final dialogMessenger = ScaffoldMessenger.of(dialogContext);
                  final pageMessenger = ScaffoldMessenger.of(this.context);

                  if (selectedFarmerCropId == null) {
                    dialogMessenger.showSnackBar(
                      const SnackBar(content: Text('Please select a crop for this task')),
                    );
                    return;
                  }

                  if (titleController.text.trim().isEmpty) {
                    dialogMessenger.showSnackBar(
                      const SnackBar(content: Text('Task name is required')),
                    );
                    return;
                  }

                  if (dueDate == null) {
                    dialogMessenger.showSnackBar(
                      const SnackBar(content: Text('Due date is required')),
                    );
                    return;
                  }

                  try {
                    await ApiService.createTask({
                      if (selectedFarmerId != null) 'farmer': selectedFarmerId,
                      'farmer_crop': selectedFarmerCropId,
                      'task_name': titleController.text.trim(),
                      'task_description': descController.text.trim().isEmpty
                          ? 'Task created from AgroAssist app.'
                          : descController.text.trim(),
                      'due_date': '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                      'priority': selectedPriority,
                      'importance': selectedImportance,
                      'status': 'Pending',
                    });
                    if (!dialogContext.mounted) return;
                    dialogNavigator.pop();
                    await loadTasks();
                    if (!mounted) return;
                    pageMessenger.showSnackBar(
                      const SnackBar(content: Text('Task created successfully')),
                    );
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    dialogMessenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Create Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(FarmerTask task, ColorScheme colorScheme) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTaskDetails(task),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(task.status),
                  backgroundColor: _getStatusColor(task.status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _metaTag(Icons.person_outline, 'Farmer: ${task.farmerName}'),
                if (task.cropName != null) _metaTag(Icons.grass, 'Crop: ${task.cropName}'),
                if (task.dueDate != null)
                  _metaTag(
                    Icons.calendar_today,
                    'Due: ${dateFormat.format(task.dueDate!)}${task.daysRemaining != null ? ' (${task.daysRemaining}d)' : ''}',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(
                  label: Text('Priority: ${task.priority}'),
                  backgroundColor: _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(task.importance),
                  backgroundColor: _getImportanceColor(task.importance),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Show reminder indicator
            if (task.status != 'Completed' && task.status != 'Cancelled') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active, 
                      size: 14, 
                      color: Colors.blue.shade700
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reminders set',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaTag(IconData icon, String text) {
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
          Text(text),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade100;
      case 'In Progress':
        return Colors.blue.shade100;
      case 'Completed':
        return Colors.green.shade100;
      case 'Overdue':
        return Colors.red.shade100;
      case 'Cancelled':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red.shade100;
    if (priority >= 5) return Colors.orange.shade100;
    return Colors.blue.shade100;
  }

  Color _getImportanceColor(String importance) {
    switch (importance) {
      case 'Critical':
        return Colors.red.shade200;
      case 'High':
        return Colors.orange.shade200;
      case 'Medium':
        return Colors.yellow.shade200;
      case 'Low':
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  void _showTaskDetails(FarmerTask task) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.taskName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Farmer', task.farmerName),
              if (task.cropName != null) _buildDetailRow('Crop', task.cropName!),
              _buildDetailRow('Status', task.status),
              if (task.dueDate != null) _buildDetailRow('Due Date', dateFormat.format(task.dueDate!)),
              _buildDetailRow('Priority', task.priority.toString()),
              _buildDetailRow('Importance', task.importance),
              _buildDetailRow('Completed', task.isCompleted ? 'Yes' : 'No'),
              if (task.farmerNotes != null && task.farmerNotes!.isNotEmpty)
                _buildDetailRow('Notes', task.farmerNotes!),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.description),
            ],
          ),
        ),
        actions: [
          if (!task.isCompleted)
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(this.context);

                try {
                  await ApiService.updateTaskStatus(task.id, 'Completed');
                  if (!mounted) return;
                  navigator.pop();
                  await loadTasks();
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Task marked as completed')));
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Mark Complete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
