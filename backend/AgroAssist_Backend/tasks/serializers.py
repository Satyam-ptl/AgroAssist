# Import serializer classes from Django REST Framework
from rest_framework import serializers

# Import models to serialize
from .models import FarmerTask, TaskReminder, TaskLog, Reminder


# SERIALIZER 1: FarmerTaskSerializer - Convert farmer tasks to/from JSON
class FarmerTaskSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields that calculate data
    farmer_name = serializers.SerializerMethodField()  # Show farmer name
    crop_name = serializers.SerializerMethodField()  # Show crop name
    days_remaining = serializers.SerializerMethodField()  # Calculate days until due
    is_overdue = serializers.SerializerMethodField()  # Check if deadline passed
    
    class Meta:
        model = FarmerTask
        fields = ['id', 'farmer', 'farmer_name', 'farmer_crop', 'crop_name', 'care_task_template',
                  'task_name', 'task_description', 'status', 'due_date', 'completed_date',
                  'priority', 'importance', 'is_completed', 'days_remaining', 'is_overdue',
                  'reminder_sent_at', 'farmer_notes', 'photo_count', 'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'farmer_name', 'crop_name', 
                           'days_remaining', 'is_overdue']  # Can't edit these
        extra_kwargs = {
            'farmer': {'required': False, 'allow_null': True},
            'task_name': {'required': True, 'min_length': 3},
            'task_description': {'required': True, 'min_length': 5},
            'due_date': {'required': True},
            'farmer_crop': {'required': True},
        }
    
    def validate_due_date(self, value):
        """Allow past dates; overdue calculation handles warning behavior in API/UI."""
        return value
    
    def validate_priority(self, value):
        """Validate priority is in valid range."""
        if not (1 <= value <= 10):
            raise serializers.ValidationError("Priority must be between 1 and 10.")
        return value

    def validate_status(self, value):
        valid = {choice[0] for choice in FarmerTask.STATUS_CHOICES}
        if value not in valid:
            raise serializers.ValidationError("Select a valid status.")
        return value
    
    def get_farmer_name(self, obj):
        # Returns farmer's full name
        return f"{obj.farmer.first_name} {obj.farmer.last_name}"
    
    def get_crop_name(self, obj):
        # Returns the crop this task is for
        return obj.farmer_crop.crop.name
    
    def get_days_remaining(self, obj):
        # Calculate days until task is due
        from datetime import datetime
        today = datetime.now().date()  # Get today's date
        
        if obj.is_completed:  # If task already completed
            return 0  # Return 0
        
        days = (obj.due_date - today).days  # Calculate remaining days
        return days  # Can be negative if overdue
    
    def get_is_overdue(self, obj):
        # Check if task deadline has passed but not completed
        if obj.is_completed:  # If already done
            return False  # Not overdue
        
        from datetime import datetime
        today = datetime.now().date()  # Get today's date
        return today > obj.due_date  # True if today is after due date


# SERIALIZER 2: TaskReminderSerializer - Convert reminders to/from JSON
class TaskReminderSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields
    task_name = serializers.SerializerMethodField()  # Show task name
    farmer_name = serializers.SerializerMethodField()  # Show farmer name
    is_pending = serializers.SerializerMethodField()  # Check if reminder not sent yet
    
    class Meta:
        model = TaskReminder
        fields = ['id', 'task', 'task_name', 'farmer_name', 'reminder_channel',
                  'reminder_date', 'sent_at', 'is_sent', 'is_pending',
                  'reminder_message', 'created_at']
        
        read_only_fields = ['created_at', 'sent_at', 'task_name', 'farmer_name', 'is_pending']  # Can't edit
    
    def get_task_name(self, obj):
        # Returns the task this reminder is for
        return obj.task.task_name
    
    def get_farmer_name(self, obj):
        # Returns farmer's full name
        return f"{obj.task.farmer.first_name} {obj.task.farmer.last_name}"
    
    def get_is_pending(self, obj):
        # Check if reminder hasn't been sent yet
        return not obj.is_sent  # True if not sent


# SERIALIZER 3: TaskLogSerializer - Convert task history to/from JSON
class TaskLogSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields
    task_name = serializers.SerializerMethodField()  # Show task name
    farmer_name = serializers.SerializerMethodField()  # Show farmer name
    formatted_timestamp = serializers.SerializerMethodField()  # Format date nicely
    
    class Meta:
        model = TaskLog
        fields = ['id', 'task', 'task_name', 'farmer_name', 'action', 'description',
                  'performed_by_farmer', 'timestamp', 'formatted_timestamp', 'metadata']
        
        read_only_fields = ['timestamp', 'formatted_timestamp']  # Can't edit
    
    def get_task_name(self, obj):
        # Returns the task name
        return obj.task.task_name
    
    def get_farmer_name(self, obj):
        # Returns farmer's full name
        return f"{obj.task.farmer.first_name} {obj.task.farmer.last_name}"
    
    def get_formatted_timestamp(self, obj):
        # Format timestamp nicely like "2025-02-22 14:30"
        return obj.timestamp.strftime('%Y-%m-%d %H:%M')


# SERIALIZER 4: CreateTaskSerializer - For creating new tasks with validation
class CreateTaskSerializer(serializers.ModelSerializer):
    # Stricter validation for creating new tasks
    
    class Meta:
        model = FarmerTask
        fields = ['farmer', 'farmer_crop', 'task_name', 'task_description', 'due_date',
                  'priority', 'importance', 'care_task_template']
        
        # Validation rules
        extra_kwargs = {
            'task_name': {'required': True, 'min_length': 3},  # At least 3 characters
            'task_description': {'required': True, 'min_length': 10},  # At least 10 chars
            'due_date': {'required': True},  # Must provide date
            'farmer': {'required': True},  # Must specify farmer
            'farmer_crop': {'required': True},  # Must specify which crop
        }
    
    def validate_due_date(self, value):
        # Overdue tasks are allowed; clients can still highlight this as a warning.
        return value

    def validate_priority(self, value):
        if not (1 <= value <= 10):
            raise serializers.ValidationError("Priority must be between 1 and 10.")
        return value


# SERIALIZER 5: TaskDetailSerializer - Show task with related reminders and history
class TaskDetailSerializer(serializers.ModelSerializer):
    # Nested serializers to show all related data
    
    farmer_name = serializers.SerializerMethodField()  # Farmer name
    crop_name = serializers.SerializerMethodField()  # Crop name
    reminders = TaskReminderSerializer(many=True, read_only=True)  # All reminders for this task
    logs = TaskLogSerializer(many=True, read_only=True)  # All history for this task
    days_remaining = serializers.SerializerMethodField()  # Days until due
    is_overdue = serializers.SerializerMethodField()  # If past due date
    
    class Meta:
        model = FarmerTask
        fields = ['id', 'farmer', 'farmer_name', 'farmer_crop', 'crop_name',
                  'care_task_template', 'task_name', 'task_description', 'status',
                  'due_date', 'completed_date', 'days_remaining', 'is_overdue',
                  'priority', 'importance', 'is_completed', 'reminder_sent_at',
                  'farmer_notes', 'photo_count', 'reminders', 'logs',
                  'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'farmer_name', 'crop_name',
                           'days_remaining', 'is_overdue', 'reminders', 'logs']  # Can't edit
    
    def get_farmer_name(self, obj):
        # Returns farmer's full name
        return f"{obj.farmer.first_name} {obj.farmer.last_name}"
    
    def get_crop_name(self, obj):
        # Returns crop name
        return obj.farmer_crop.crop.name
    
    def get_days_remaining(self, obj):
        # Calculate days until due
        from datetime import datetime
        today = datetime.now().date()
        
        if obj.is_completed:
            return 0  # Task done
        
        days = (obj.due_date - today).days
        return days
    
    def get_is_overdue(self, obj):
        # Check if late
        if obj.is_completed:
            return False
        
        from datetime import datetime
        today = datetime.now().date()
        return today > obj.due_date


# SERIALIZER 6: UpdateTaskStatusSerializer - For marking tasks complete
class UpdateTaskStatusSerializer(serializers.ModelSerializer):
    # Limited serializer for updating task status
    
    class Meta:
        model = FarmerTask
        fields = ['status', 'is_completed', 'completed_date', 'farmer_notes']  # Only these fields can be updated
        
        extra_kwargs = {
            'status': {'required': True},  # Must set status
            'is_completed': {'required': True},  # Must specify if complete
        }
    
    def validate(self, data):
        # Custom validation logic
        # If marking as completed, must set completed_date
        if data.get('is_completed') and not data.get('completed_date'):
            raise serializers.ValidationError(
                "completed_date is required when marking task as complete."
            )
        
        return data


# SERIALIZER 7: DailyTaskSummarySerializer - Summary of tasks for a farmer on a day
class DailyTaskSummarySerializer(serializers.Serializer):
    # Custom serializer (not based on model) for daily task summary
    
    # DateField = The date we're summarizing
    date = serializers.DateField()  # Which day (e.g., 2025-02-22)
    
    # IntegerField = Count of tasks
    total_tasks = serializers.IntegerField()  # Total tasks for the day
    completed_tasks = serializers.IntegerField()  # How many completed
    pending_tasks = serializers.IntegerField()  # How many not done
    overdue_tasks = serializers.IntegerField()  # How many late
    
    # ListField = List of task objects
    tasks = FarmerTaskSerializer(many=True)  # Actual task data
    
    # CharField = Summary text
    summary = serializers.CharField()  # Generated summary (e.g., "5 tasks, 2 completed")


class ReminderSerializer(serializers.ModelSerializer):
    sent_to_count = serializers.SerializerMethodField()

    class Meta:
        model = Reminder
        fields = ['id', 'farmers', 'message', 'sent_by', 'sent_at', 'reminder_type', 'sent_to_count']
        read_only_fields = ['id', 'sent_by', 'sent_at', 'sent_to_count']

    def get_sent_to_count(self, obj):
        return obj.farmers.count()
