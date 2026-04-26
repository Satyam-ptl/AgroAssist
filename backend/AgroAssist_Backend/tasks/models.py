# Import Django model classes for database
from django.db import models
from django.conf import settings

# Import related models from other apps
from AgroAssist_Backend.farmers.models import Farmer, FarmerCrop  # Farmer and their crops
from AgroAssist_Backend.crops.models import CropCareTask  # Pre-defined crop care tasks

# MODEL 1: FarmerTask - Specific tasks assigned to a farmer for their crop
class FarmerTask(models.Model):
    # ForeignKey = Link to Farmer model (each farmer has multiple tasks)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='tasks')  # Which farmer
    
    # ForeignKey = Link to FarmerCrop model (task is for a specific crop the farmer is growing)
    farmer_crop = models.ForeignKey(FarmerCrop, on_delete=models.CASCADE, related_name='tasks')  # Which crop
    
    # ForeignKey = Link to CropCareTask model (template task from crop guide)
    # on_delete=models.SET_NULL = Keep task even if template is deleted
    care_task_template = models.ForeignKey(CropCareTask, on_delete=models.SET_NULL, null=True, blank=True, related_name='farmer_tasks')  # Based on which template task
    
    # CharField = Task name/title
    task_name = models.CharField(max_length=100)  # Name (e.g., "Apply NPK Fertilizer")
    
    # TextField = Detailed description of what to do
    task_description = models.TextField()  # Step-by-step instructions for farmer
    
    # CharField with choices = What status is this task in?
    STATUS_CHOICES = [
        ('Pending', 'Pending'),  # Not started yet
        ('In Progress', 'In Progress'),  # Farmer has started
        ('Completed', 'Completed'),  # Farmer finished
        ('Overdue', 'Overdue'),  # Deadline passed but not done
        ('Cancelled', 'Cancelled'),  # Task cancelled
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')  # Current status
    
    # DateField = When farmer should complete this task
    due_date = models.DateField()  # Deadline for this task (e.g., 2025-03-10)
    
    # DateField = When farmer actually completed this task (optional)
    completed_date = models.DateField(blank=True, null=True)  # When farmer actually did it
    
    # IntegerField = Priority level (1-10, higher = more important)
    priority = models.IntegerField(default=5)  # Priority scale 1-10 (10 = most urgent)
    
    # CharField with choices = How important is this task?
    IMPORTANCE_CHOICES = [
        ('Low', 'Low'),  # Not critical
        ('Medium', 'Medium'),  # Important
        ('High', 'High'),  # Very important
        ('Critical', 'Critical'),  # Must do or crop damage
    ]
    importance = models.CharField(max_length=20, choices=IMPORTANCE_CHOICES, default='Medium')  # Importance level
    
    # BooleanField = Has farmer completed this task?
    is_completed = models.BooleanField(default=False)  # True = completed, False = not done
    
    # DateTimeField = When was farmer reminded? (for notifications)
    reminder_sent_at = models.DateTimeField(blank=True, null=True)  # When notification was sent
    
    # TextField = Farmer's notes after completing task
    farmer_notes = models.TextField(blank=True)  # What farmer wants to record about doing this
    
    # IntegerField = Photos/evidence of task completion (number of photos)
    photo_count = models.IntegerField(default=0)  # How many proof photos farmer uploaded
    
    # DateTimeField = Auto-set when task created
    created_at = models.DateTimeField(auto_now_add=True)
    
    # DateTimeField = Auto-update when task modified
    updated_at = models.DateTimeField(auto_now=True)
    
    # Meta class = Configuration for FarmerTask model
    class Meta:
        verbose_name = "Farmer Task"  # Display name (singular)
        verbose_name_plural = "Farmer Tasks"  # Display name (plural)
        ordering = ['due_date', '-importance']  # Sort by due date, then by importance
        indexes = [
            models.Index(fields=['farmer']),
            models.Index(fields=['status']),
            models.Index(fields=['due_date']),
        ]
    
    def __str__(self):
        # Shows "Rajesh Patil - Apply Fertilizer (Pending)" when displaying
        return f"{self.farmer.first_name} - {self.task_name} ({self.status})"


# MODEL 2: TaskReminder - Notifications sent to farmers about upcoming tasks
class TaskReminder(models.Model):
    # ForeignKey = Link to FarmerTask model (reminder for a specific task)
    task = models.ForeignKey(FarmerTask, on_delete=models.CASCADE, related_name='reminders')  # Which task
    
    # CharField with choices = How should reminder be sent?
    REMINDER_CHANNEL_CHOICES = [
        ('SMS', 'SMS (Text Message)'),  # Send via SMS
        ('WhatsApp', 'WhatsApp'),  # Send via WhatsApp
        ('App', 'App Notification'),  # In-app notification
        ('Email', 'Email'),  # Send via email
    ]
    reminder_channel = models.CharField(max_length=20, choices=REMINDER_CHANNEL_CHOICES)  # How to notify
    
    # DateField = When should reminder be sent?
    reminder_date = models.DateField()  # Date to send reminder (e.g., day before task due date)
    
    # DateTimeField = When the reminder was actually sent
    sent_at = models.DateTimeField(blank=True, null=True)  # When reminder was actually sent at
    
    # BooleanField = Has reminder been sent?
    is_sent = models.BooleanField(default=False)  # True = sent, False = not sent yet
    
    # TextField = Message content for reminder
    reminder_message = models.TextField()  # Exact message text sent to farmer
    
    # DateTimeField = Auto-set when reminder created
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Meta class = Configuration for TaskReminder model
    class Meta:
        verbose_name = "Task Reminder"  # Display name (singular)
        verbose_name_plural = "Task Reminders"  # Display name (plural)
        ordering = ['reminder_date']  # Show reminders in chronological order
        indexes = [
            models.Index(fields=['task']),
            models.Index(fields=['reminder_date']),
            models.Index(fields=['is_sent']),
        ]
    
    def __str__(self):
        # Shows "Rajesh Patil - Apply Fertilizer - 2025-03-09 (Sent)" when displaying
        status = "Sent" if self.is_sent else "Pending"  # Show if sent or pending
        return f"{self.task.farmer.first_name} - {self.task.task_name} - {self.reminder_date} ({status})"


# MODEL 3: TaskLog - History of all tasks farmer has completed
class TaskLog(models.Model):
    # ForeignKey = Link to FarmerTask model (log entry for a task)
    task = models.ForeignKey(FarmerTask, on_delete=models.CASCADE, related_name='logs')  # Which task
    
    # CharField with choices = What action was taken on this task?
    ACTION_CHOICES = [
        ('Created', 'Task Created'),  # Task was created
        ('Started', 'Task Started'),  # Farmer started task
        ('Progress', 'Progress Update'),  # Farmer gave update on progress
        ('Completed', 'Task Completed'),  # Farmer finished task
        ('Updated', 'Task Updated'),  # Task details were changed
        ('Cancelled', 'Task Cancelled'),  # Task was cancelled
    ]
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)  # What happened to task
    
    # TextField = Details about what happened
    description = models.TextField(blank=True)  # Additional details about the action
    
    # ForeignKey = Which farmer made this action? (optional, in case admin updates)
    # on_delete=models.SET_NULL = Keep log even if farmer is deleted
    performed_by_farmer = models.ForeignKey(Farmer, on_delete=models.SET_NULL, null=True, blank=True, related_name='task_action_logs')  # Who did this action
    
    # DateTimeField = When did this action happen?
    timestamp = models.DateTimeField(auto_now_add=True)  # When action occurred (auto-set)
    
    # CharField = metadata from the action (optional)
    metadata = models.CharField(max_length=500, blank=True)  # Any additional data (e.g., "Temp: 25C, Humidity: 60%")
    
    # Meta class = Configuration for TaskLog model
    class Meta:
        verbose_name = "Task Log"  # Display name (singular)
        verbose_name_plural = "Task Logs"  # Display name (plural)
        ordering = ['-timestamp']  # Show most recent logs first
        indexes = [
            models.Index(fields=['task']),
            models.Index(fields=['action']),
            models.Index(fields=['timestamp']),
        ]
    
    def __str__(self):
        # Shows "2025-02-22 - Rajesh Patil - Apply Fertilizer - Completed" when displaying
        return f"{self.timestamp.date()} - {self.task.farmer.first_name} - {self.task.task_name} - {self.action}"


class Reminder(models.Model):
    REMINDER_TYPE_CHOICES = [
        ('pending', 'Pending'),
        ('overdue', 'Overdue'),
        ('custom', 'Custom'),
    ]

    farmers = models.ManyToManyField('farmers.Farmer', related_name='reminders')
    message = models.TextField()
    sent_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    sent_at = models.DateTimeField(auto_now_add=True)
    reminder_type = models.CharField(max_length=20, choices=REMINDER_TYPE_CHOICES)

    class Meta:
        ordering = ['-sent_at']

    def __str__(self):
        return f"Reminder {self.id} ({self.reminder_type})"

