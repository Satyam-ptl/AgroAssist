from django.contrib import admin
from .models import FarmerTask, TaskReminder, TaskLog

# Register FarmerTask model - Tasks for farmers
@admin.register(FarmerTask)
class FarmerTaskAdmin(admin.ModelAdmin):
    list_display = ['farmer', 'task_name', 'due_date', 'status', 'priority']  # Show tasks
    list_filter = ['status', 'importance', 'due_date']  # Filters
    search_fields = ['farmer__first_name', 'task_name']  # Search
    readonly_fields = ['created_at', 'updated_at']  # Can't edit timestamps

# Register TaskReminder model - Notifications
@admin.register(TaskReminder)
class TaskReminderAdmin(admin.ModelAdmin):
    list_display = ['task', 'reminder_channel', 'reminder_date', 'is_sent']  # Show reminders
    list_filter = ['reminder_channel', 'is_sent', 'reminder_date']  # Filters
    search_fields = ['task__task_name']  # Search
    readonly_fields = ['created_at', 'sent_at']  # Can't edit

# Register TaskLog model - Task history
@admin.register(TaskLog)
class TaskLogAdmin(admin.ModelAdmin):
    list_display = ['task', 'action', 'timestamp']  # Show task history
    list_filter = ['action', 'timestamp']  # Filters
    search_fields = ['task__task_name']  # Search
    readonly_fields = ['timestamp']  # Can't edit creation time
