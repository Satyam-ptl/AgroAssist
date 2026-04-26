# Tasks API ViewSets - Task management for farmers
from datetime import timedelta

from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.exceptions import PermissionDenied, ValidationError
from django.utils import timezone
from django.db.models import Case, IntegerField, Value, When

from .models import FarmerTask, TaskReminder, TaskLog, Reminder
from .serializers import FarmerTaskSerializer, TaskReminderSerializer, TaskLogSerializer, ReminderSerializer
from AgroAssist_Backend.farmers.models import Farmer


def _linked_farmer_for_user(user):
    farmer = getattr(user, 'farmer', None)
    if farmer is not None:
        return farmer

    user_email = getattr(user, 'email', '')
    if not user_email:
        return None

    return Farmer.objects.filter(email__iexact=user_email).first()


def _build_reminder_message(task, days_before):
    if days_before <= 0:
        return (
            f"Today's task: {task.task_name} for {task.farmer_crop.crop.name}. "
            f"Please complete it by end of day."
        )

    day_text = 'day' if days_before == 1 else 'days'
    return (
        f"Upcoming task in {days_before} {day_text}: {task.task_name} "
        f"for {task.farmer_crop.crop.name} due on {task.due_date}."
    )


def _sync_task_reminders(task):
    """Create/update date-based in-app reminders for the task due date."""
    today = timezone.localdate()
    reminder_offsets = [3, 1, 0]
    expected_dates = set()

    for days_before in reminder_offsets:
        reminder_date = task.due_date - timedelta(days=days_before)
        if reminder_date < today:
            continue

        expected_dates.add(reminder_date)
        TaskReminder.objects.update_or_create(
            task=task,
            reminder_channel='App',
            reminder_date=reminder_date,
            defaults={
                'reminder_message': _build_reminder_message(task, days_before),
            },
        )

    TaskReminder.objects.filter(task=task, reminder_channel='App').exclude(
        reminder_date__in=expected_dates,
    ).delete()


def _refresh_overdue_tasks(queryset):
    """Ensure pending/in-progress tasks are marked overdue after due date."""
    today = timezone.localdate()
    queryset.filter(
        is_completed=False,
        due_date__lt=today,
    ).exclude(status='Overdue').update(status='Overdue')

class StandardPagination(PageNumberPagination):
    page_size = 20  # Show 20 results per page

# FarmerTask ViewSet - Task management for farmers
class FarmerTaskViewSet(viewsets.ModelViewSet):
    queryset = FarmerTask.objects.all()  # All farmer tasks
    serializer_class = FarmerTaskSerializer  # Convert to JSON
    pagination_class = StandardPagination  # Paginate results
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Filter/sort
    search_fields = ['farmer__first_name', 'task_name']  # Search by farmer or task name
    ordering = ['due_date']  # Sort by due date (urgent first)
    
    # Require authentication (ADDED)
    permission_classes = [IsAuthenticated]
    
    def get_permissions(self):
        """Authenticated users can create; only admins can update/delete."""
        if self.action in ['update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return super().get_permissions()

    @staticmethod
    def _normalize_status(status_value):
        if not status_value:
            return None

        normalized = status_value.strip().lower().replace('-', '_').replace(' ', '_')
        mapping = {
            'pending': 'Pending',
            'in_progress': 'In Progress',
            'completed': 'Completed',
            'overdue': 'Overdue',
        }
        return mapping.get(normalized)
    
    def get_queryset(self):
        """Scope tasks: admins see all, farmers see only their assigned tasks."""
        user = self.request.user
        queryset = FarmerTask.objects.all()

        _refresh_overdue_tasks(queryset)
        
        # Admins see all tasks
        if user.is_staff or user.is_superuser:
            scoped_queryset = queryset
            farmer_id = self.request.query_params.get('farmer_id')
            if farmer_id:
                scoped_queryset = scoped_queryset.filter(farmer_id=farmer_id)
        else:
            # Farmers see only their assigned tasks
            farmer = _linked_farmer_for_user(user)
            if farmer:
                scoped_queryset = queryset.filter(farmer=farmer)
            else:
                # Return empty if not admin and not linked farmer
                scoped_queryset = queryset.none()
        
        status = self.request.query_params.get('status', None)
        if status:
            normalized_status = self._normalize_status(status)
            if normalized_status:
                scoped_queryset = scoped_queryset.filter(status=normalized_status)
            else:
                scoped_queryset = scoped_queryset.none()
        
        priority = self.request.query_params.get('priority', None)
        if priority:
            scoped_queryset = scoped_queryset.filter(priority=priority)

        return scoped_queryset.annotate(
            overdue_rank=Case(
                When(status='Overdue', then=Value(0)),
                default=Value(1),
                output_field=IntegerField(),
            )
        ).order_by('overdue_rank', 'due_date')

    def perform_create(self, serializer):
        user = self.request.user

        # Admins can create broadly; infer farmer from farmer_crop when omitted.
        if user.is_staff or user.is_superuser:
            farmer = serializer.validated_data.get('farmer')
            farmer_crop = serializer.validated_data.get('farmer_crop')

            if farmer is None and farmer_crop is not None:
                task = serializer.save(farmer=farmer_crop.farmer)
                _sync_task_reminders(task)
                return

            task = serializer.save()
            _sync_task_reminders(task)
            return

        # Farmers can create only for their own profile and own crop records.
        farmer = _linked_farmer_for_user(user)
        if not farmer:
            raise PermissionDenied('No farmer profile linked to this user.')

        farmer_crop = serializer.validated_data.get('farmer_crop')
        if not farmer_crop:
            raise ValidationError({'farmer_crop': ['This field is required.']})

        if farmer_crop.farmer_id != farmer.id:
            raise PermissionDenied('You can only create tasks for your own crops.')

        task = serializer.save(farmer=farmer)
        _sync_task_reminders(task)

    def perform_update(self, serializer):
        task = serializer.save()
        _sync_task_reminders(task)

    @action(detail=True, methods=['patch'], url_path='update-status')
    def update_status(self, request, pk=None):
        task = self.get_object()
        user = request.user

        if not (user.is_staff or user.is_superuser):
            farmer = _linked_farmer_for_user(user)
            if not farmer or task.farmer_id != farmer.id:
                raise PermissionDenied('You can only update your own tasks.')

        requested_status = request.data.get('status')
        normalized_status = self._normalize_status(requested_status)
        if not normalized_status:
            raise ValidationError(
                {'status': ['Allowed values: pending, in_progress, completed, overdue.']}
            )

        task.status = normalized_status
        task.is_completed = normalized_status == 'Completed'
        task.completed_date = timezone.localdate() if task.is_completed else None
        task.save(update_fields=['status', 'is_completed', 'completed_date', 'updated_at'])
        _sync_task_reminders(task)

        serializer = self.get_serializer(task)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='send-reminder')
    def send_reminder(self, request):
        user = request.user
        if not (user.is_staff or user.is_superuser):
            raise PermissionDenied('Only admin users can send reminders.')

        farmer_ids = request.data.get('farmer_ids')
        message = (request.data.get('message') or '').strip()
        reminder_type = (request.data.get('reminder_type') or '').strip().lower()

        if reminder_type not in {'pending', 'overdue', 'custom'}:
            raise ValidationError({'reminder_type': ['Allowed values: pending, overdue, custom.']})
        if not message:
            raise ValidationError({'message': ['This field is required.']})

        if farmer_ids == 'all':
            target_farmers = Farmer.objects.all()
        elif isinstance(farmer_ids, list):
            target_farmers = Farmer.objects.filter(id__in=farmer_ids)
        else:
            raise ValidationError({'farmer_ids': ['Use "all" or a list of farmer IDs.']})

        reminder = Reminder.objects.create(
            message=message,
            sent_by=user,
            reminder_type=reminder_type,
        )
        reminder.farmers.set(target_farmers)

        return Response({'sent_to': target_farmers.count(), 'message': 'Reminders sent'})

    @action(detail=False, methods=['get'], url_path='reminders')
    def reminders(self, request):
        user = request.user
        queryset = Reminder.objects.prefetch_related('farmers').select_related('sent_by')

        if user.is_staff or user.is_superuser:
            serializer = ReminderSerializer(queryset, many=True)
            return Response(serializer.data)

        farmer = _linked_farmer_for_user(user)
        if not farmer:
            return Response([])

        serializer = ReminderSerializer(queryset.filter(farmers=farmer), many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='reminders-history')
    def reminders_history(self, request):
        user = request.user
        if not (user.is_staff or user.is_superuser):
            raise PermissionDenied('Only admin users can view reminder history.')

        queryset = Reminder.objects.prefetch_related('farmers').select_related('sent_by')
        serializer = ReminderSerializer(queryset, many=True)
        return Response(serializer.data)

# Task Reminder ViewSet - Notifications for tasks
class TaskReminderViewSet(viewsets.ModelViewSet):
    queryset = TaskReminder.objects.all()  # All reminders
    serializer_class = TaskReminderSerializer  # Convert to JSON
    pagination_class = StandardPagination  # Paginate
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Filter
    search_fields = ['task__task_name']  # Search by task name
    ordering = ['reminder_date']  # By date
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        queryset = TaskReminder.objects.select_related('task', 'task__farmer').all()

        if user.is_staff or user.is_superuser:
            return queryset

        farmer = _linked_farmer_for_user(user)
        if farmer:
            return queryset.filter(task__farmer=farmer)

        return queryset.none()

# Task Log ViewSet - Task history and activity tracking
class TaskLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TaskLog.objects.all()  # All task logs (read-only)
    serializer_class = TaskLogSerializer  # Convert to JSON
    pagination_class = StandardPagination  # Paginate
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Filter
    search_fields = ['task__task_name']  # Search by task name
    ordering = ['-timestamp']  # Newest logs first
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = TaskLog.objects.select_related('task', 'task__farmer').all()

        if user.is_staff or user.is_superuser:
            return queryset

        farmer = _linked_farmer_for_user(user)
        if farmer:
            return queryset.filter(task__farmer=farmer)

        return queryset.none()
