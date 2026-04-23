from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from AgroAssist_Backend.crops.models import Crop
from AgroAssist_Backend.farmers.models import Farmer, FarmerCrop
from AgroAssist_Backend.farmers.stateless_token_auth import issue_auth_token
from AgroAssist_Backend.tasks.models import FarmerTask, TaskReminder


class TaskReminderAutomationTests(TestCase):
    def setUp(self):
        user_model = get_user_model()
        self.admin = user_model.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='Admin@12345',
        )
        self.user = user_model.objects.create_user(
            username='farmer_user',
            email='farmer@example.com',
            password='Test@12345',
        )

        self.farmer = Farmer.objects.create(
            first_name='Rahul',
            last_name='Patel',
            email='farmer@example.com',
            phone_number='9876543210',
            address='Village Road',
            city='Indore',
            state='Madhya Pradesh',
            postal_code=452001,
            preferred_language='English',
            land_area_hectares=2.5,
            soil_type='Loamy',
            experience_level='Intermediate',
        )

        self.crop = Crop.objects.create(
            name='Soybean',
            description='Suitable for Madhya Pradesh during Kharif season.',
            season='Kharif',
            soil_type='Loamy',
            growth_duration_days=110,
            optimal_temperature=28.0,
            optimal_humidity=65.0,
            optimal_soil_moisture=45.0,
            water_required_mm_per_week=35.0,
            fertilizer_required='NPK',
            expected_yield_per_hectare=2200,
        )

        self.farmer_crop = FarmerCrop.objects.create(
            farmer=self.farmer,
            crop=self.crop,
            planting_date=timezone.localdate(),
            expected_harvest_date=timezone.localdate() + timedelta(days=110),
            status='Growing',
            area_allocated_hectares=1.5,
            expected_yield_kg=3300,
        )

        self.farmer_client = APIClient()
        self.farmer_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.user)}')

        self.admin_client = APIClient()
        self.admin_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.admin)}')

    def _create_task(self, due_days=7):
        response = self.farmer_client.post(
            '/api/tasks/',
            {
                'farmer_crop': self.farmer_crop.id,
                'task_name': 'Top dressing',
                'task_description': 'Apply fertilizer at vegetative stage.',
                'due_date': (timezone.localdate() + timedelta(days=due_days)).isoformat(),
                'priority': 7,
                'importance': 'High',
                'status': 'Pending',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        return response.data['id']

    def test_list_tasks_returns_paginated_results(self):
        self._create_task()
        response = self.farmer_client.get('/api/tasks/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('results', response.data)

    def test_create_task_generates_time_based_reminders(self):
        task_id = self._create_task()

        reminders = TaskReminder.objects.filter(task_id=task_id, reminder_channel='App')
        self.assertEqual(reminders.count(), 3)

        reminder_dates = set(reminders.values_list('reminder_date', flat=True))
        due_date = timezone.localdate() + timedelta(days=7)
        self.assertSetEqual(
            reminder_dates,
            {
                due_date - timedelta(days=3),
                due_date - timedelta(days=1),
                due_date,
            },
        )

    def test_admin_can_update_task_status(self):
        task = FarmerTask.objects.create(
            farmer=self.farmer,
            farmer_crop=self.farmer_crop,
            task_name='Irrigation check',
            task_description='Inspect and irrigate if moisture is low.',
            status='Pending',
            due_date=timezone.localdate() + timedelta(days=1),
            priority=5,
            importance='Medium',
            is_completed=False,
        )

        response = self.admin_client.patch(
            f'/api/tasks/{task.id}/',
            {
                'status': 'Completed',
                'is_completed': True,
                'completed_date': timezone.localdate(),
                'farmer_notes': 'Completed on time.',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        task.refresh_from_db()
        self.assertEqual(task.status, 'Completed')
        self.assertTrue(task.is_completed)

    def test_task_reminder_endpoint_lists_reminders(self):
        self._create_task()
        response = self.farmer_client.get('/api/task-reminders/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('results', response.data)

    def test_listing_tasks_marks_overdue_when_due_date_passed(self):
        task = FarmerTask.objects.create(
            farmer=self.farmer,
            farmer_crop=self.farmer_crop,
            task_name='Irrigation check',
            task_description='Inspect and irrigate if moisture is low.',
            status='Pending',
            due_date=timezone.localdate() - timedelta(days=1),
            priority=5,
            importance='Medium',
            is_completed=False,
        )

        response = self.farmer_client.get('/api/tasks/')
        self.assertEqual(response.status_code, 200)

        task.refresh_from_db()
        self.assertEqual(task.status, 'Overdue')