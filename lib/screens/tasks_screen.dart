import 'package:flutter/material.dart';
import '../models/task_model.dart';  // Import Task model
import '../services/api_service.dart';  // Import API service
import '../services/localization_service.dart';
import 'package:intl/intl.dart';  // For date formatting

/// Tasks screen - shows list of all tasks
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<FarmerTask> tasks = [];  // List of tasks
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'All';  // Filter by status

  // Available statuses
  final List<String> statuses = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
    'Overdue',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    loadTasks();  // Load tasks when screen opens
  }

  /// Load tasks from Django API
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
      final List<FarmerTask> loadedTasks = tasksJson
          .map((json) => FarmerTask.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      setState(() {
        tasks = loadedTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load tasks: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.tr('Tasks')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadTasks,
            tooltip: LocalizationService.tr('Refresh'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter dropdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Status: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                      loadTasks();  // Reload with new filter
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage!,
                                style: const TextStyle(color: Colors.red)),
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
                              padding: const EdgeInsets.all(16),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return _buildTaskCard(task);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  /// Build a card widget for a task
  Widget _buildTaskCard(FarmerTask task) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');  // Date formatter

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showTaskDetails(task);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(task.status),
                    backgroundColor: _getStatusColor(task.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Farmer name
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('Farmer: ${task.farmerName}'),
                ],
              ),

              // Crop name if available
              if (task.cropName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.grass, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('Crop: ${task.cropName}'),
                  ],
                ),
              ],

              // Due date if available
              if (task.dueDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: task.isOverdue == true ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${dateFormat.format(task.dueDate!)}',
                      style: TextStyle(
                        color: task.isOverdue == true ? Colors.red : Colors.black,
                        fontWeight: task.isOverdue == true
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (task.daysRemaining != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${task.daysRemaining} days)',
                        style: TextStyle(
                          color: task.isOverdue == true ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Priority and importance
              const SizedBox(height: 8),
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

              // Description preview
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get color for status
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

  /// Get color for priority
  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red.shade100;
    if (priority >= 5) return Colors.orange.shade100;
    return Colors.blue.shade100;
  }

  /// Get color for importance
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

  /// Show task details dialog
  void _showTaskDetails(FarmerTask task) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.taskName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Farmer', task.farmerName),
              if (task.cropName != null)
                _buildDetailRow('Crop', task.cropName!),
              _buildDetailRow('Status', task.status),
              if (task.dueDate != null)
                _buildDetailRow('Due Date', dateFormat.format(task.dueDate!)),
              _buildDetailRow('Priority', task.priority.toString()),
              _buildDetailRow('Importance', task.importance),
              _buildDetailRow('Completed', task.isCompleted ? 'Yes' : 'No'),
              if (task.farmerNotes != null && task.farmerNotes!.isNotEmpty)
                _buildDetailRow('Notes', task.farmerNotes!),
              const SizedBox(height: 8),
              const Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(task.description),
            ],
          ),
        ),
        actions: [
          if (!task.isCompleted)
            TextButton(
              onPressed: () async {
                // Mark task as completed
                try {
                  await ApiService.updateTaskStatus(task.id, 'Completed');
                  Navigator.pop(context);
                  loadTasks();  // Reload tasks
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task marked as completed')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
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

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
