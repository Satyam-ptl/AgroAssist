/// FarmerTask model - represents tasks for farmers
class FarmerTask {
  final int id;
  final int farmerId;  // Foreign key to Farmer
  final String farmerName;  // Farmer's name
  final int? farmerCropId;  // Foreign key to FarmerCrop (optional)
  final String? cropName;  // Crop name if task is crop-specific
  final String taskName;  // Name/title of the task
  final String description;  // Detailed task description
  final String status;  // Pending, In Progress, Completed, Overdue, Cancelled
  final DateTime? dueDate;  // When task should be completed
  final bool isCompleted;  // Whether task is done
  final int priority;  // Priority level (1-10)
  final String importance;  // Low, Medium, High, Critical
  final DateTime? reminderSentAt;  // When reminder was sent
  final String? farmerNotes;  // Notes added by farmer
  final int? daysRemaining;  // Calculated: days until due date
  final bool? isOverdue;  // Calculated: whether task is overdue
  final DateTime createdAt;  // When task was created
  final DateTime updatedAt;  // Last updated time

  FarmerTask({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerCropId,
    this.cropName,
    required this.taskName,
    required this.description,
    required this.status,
    this.dueDate,
    required this.isCompleted,
    required this.priority,
    required this.importance,
    this.reminderSentAt,
    this.farmerNotes,
    this.daysRemaining,
    this.isOverdue,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create FarmerTask from JSON
  factory FarmerTask.fromJson(Map<String, dynamic> json) {
    final String status = _toStringValue(json['status']);
    return FarmerTask(
      id: _toInt(json['id']),
      farmerId: _toInt(json['farmer']),
      farmerName: _toStringValue(json['farmer_name']),
      farmerCropId: json['farmer_crop'] != null ? _toInt(json['farmer_crop']) : null,
      cropName: json['crop_name']?.toString(),
      taskName: _toStringValue(json['task_name']),
      description: _toStringValue(json['task_description'] ?? json['description']),
      status: status,
      dueDate: json['due_date'] != null 
          ? _toDateTime(json['due_date'])
          : null,
      isCompleted: _toBool(json['is_completed'], defaultValue: status == 'Completed'),
      priority: _toInt(json['priority']),
      importance: _toStringValue(json['importance']),
      reminderSentAt: json['reminder_sent_at'] != null
          ? _toDateTime(json['reminder_sent_at'])
          : null,
      farmerNotes: json['farmer_notes']?.toString(),
      daysRemaining: json['days_remaining'] != null ? _toInt(json['days_remaining']) : null,
      isOverdue: json['is_overdue'] != null ? _toBool(json['is_overdue']) : null,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toStringValue(dynamic value) {
    return value?.toString() ?? '';
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return defaultValue;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Convert FarmerTask to JSON (for creating/updating)
  Map<String, dynamic> toJson() {
    return {
      'farmer': farmerId,
      'farmer_crop': farmerCropId,
      'task_name': taskName,
      'task_description': description,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted,
      'priority': priority,
      'importance': importance,
      'farmer_notes': farmerNotes,
    };
  }
}

/// TaskReminder model - represents reminders for tasks
class TaskReminder {
  final int id;
  final int taskId;  // Foreign key to FarmerTask
  final String reminderChannel;  // SMS, WhatsApp, App, Email
  final DateTime reminderDate;  // When to send reminder
  final bool isSent;  // Whether reminder was sent
  final String? reminderMessage;  // Custom reminder message
  final DateTime createdAt;

  TaskReminder({
    required this.id,
    required this.taskId,
    required this.reminderChannel,
    required this.reminderDate,
    required this.isSent,
    this.reminderMessage,
    required this.createdAt,
  });

  /// Create TaskReminder from JSON
  factory TaskReminder.fromJson(Map<String, dynamic> json) {
    return TaskReminder(
      id: _toInt(json['id']),
      taskId: _toInt(json['task']),
      reminderChannel: _toStringValue(json['reminder_channel']),
      reminderDate: _toDateTime(json['reminder_date']),
      isSent: _toBool(json['is_sent']),
      reminderMessage: json['reminder_message']?.toString(),
      createdAt: _toDateTime(json['created_at']),
    );
  }
}

/// TaskLog model - represents activity log for tasks
class TaskLog {
  final int id;
  final int taskId;  // Foreign key to FarmerTask
  final String action;  // Created, Started, Progress, Completed, Updated, Cancelled
  final String description;  // Description of what happened
  final DateTime timestamp;  // When action occurred
  final Map<String, dynamic>? metadata;  // Additional data (JSON)

  TaskLog({
    required this.id,
    required this.taskId,
    required this.action,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  /// Create TaskLog from JSON
  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: _toInt(json['id']),
      taskId: _toInt(json['task']),
      action: _toStringValue(json['action']),
      description: _toStringValue(json['description']),
      timestamp: _toDateTime(json['timestamp']),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _toStringValue(dynamic value) {
  return value?.toString() ?? '';
}

bool _toBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  final normalized = value?.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return defaultValue;
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
