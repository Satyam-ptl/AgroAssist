import os
from datetime import date, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'AgroAssist_Backend.settings')

import django

django.setup()

from django.conf import settings
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from AgroAssist_Backend.crops.models import Crop
from AgroAssist_Backend.farmers.models import Farmer, FarmerCrop
from AgroAssist_Backend.tasks.models import FarmerTask


if 'testserver' not in settings.ALLOWED_HOSTS:
    settings.ALLOWED_HOSTS.append('testserver')


def ensure_user(username, email, is_staff=False, is_superuser=False):
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            'email': email,
            'is_staff': is_staff,
            'is_superuser': is_superuser,
        },
    )
    changed = False
    if user.email != email:
        user.email = email
        changed = True
    if user.is_staff != is_staff:
        user.is_staff = is_staff
        changed = True
    if user.is_superuser != is_superuser:
        user.is_superuser = is_superuser
        changed = True
    if created or changed:
        user.set_password('Pass@12345')
        user.save()
    return user


def ensure_farmer(user, first_name, last_name, city, phone_number):
    farmer = Farmer.objects.filter(email__iexact=user.email).first()
    if farmer is None:
        farmer = Farmer.objects.create(
            user=user,
            first_name=first_name,
            last_name=last_name,
            email=user.email,
            phone_number=phone_number,
            address='Checklist Address',
            city=city,
            state='Maharashtra',
            postal_code=411001,
            preferred_language='English',
            land_area_hectares=2.0,
            soil_type='Loamy',
            experience_level='Intermediate',
            contact_method='WhatsApp',
        )
    else:
        dirty = False
        if farmer.user_id != user.id:
            farmer.user = user
            dirty = True
        if farmer.phone_number != phone_number:
            farmer.phone_number = phone_number
            dirty = True
        if dirty:
            farmer.save()
    return farmer


def ensure_crop(name):
    crop, _ = Crop.objects.get_or_create(
        name=name,
        defaults={
            'description': 'Checklist crop',
            'category': 'Cereal',
            'crop_type': 'Field',
            'season': 'Kharif',
            'states': 'Maharashtra,Punjab',
            'soil_type': 'Loamy',
            'growth_duration_days': 120,
            'optimal_temperature': 27.0,
            'optimal_humidity': 60.0,
            'optimal_soil_moisture': 45.0,
            'water_required_mm_per_week': 30.0,
            'fertilizer_required': 'NPK',
            'expected_yield_per_hectare': 2000,
        },
    )
    if 'Maharashtra' not in (crop.states or ''):
        crop.states = 'Maharashtra,Punjab'
        crop.save(update_fields=['states'])
    return crop


def ensure_farmer_crop(farmer, crop):
    farmer_crop, _ = FarmerCrop.objects.get_or_create(
        farmer=farmer,
        crop=crop,
        planting_date=date.today() - timedelta(days=5),
        defaults={
            'expected_harvest_date': date.today() + timedelta(days=90),
            'status': 'Growing',
            'area_allocated_hectares': 1.0,
            'expected_yield_kg': 1000,
        },
    )
    return farmer_crop


def ensure_task(farmer, farmer_crop, task_name):
    task, _ = FarmerTask.objects.get_or_create(
        farmer=farmer,
        farmer_crop=farmer_crop,
        task_name=task_name,
        defaults={
            'task_description': 'Checklist task',
            'due_date': date.today() + timedelta(days=2),
            'status': 'Pending',
            'priority': 5,
            'importance': 'Medium',
            'is_completed': False,
        },
    )
    return task


def check(label, condition, detail=''):
    state = 'PASS' if condition else 'FAIL'
    print(f'{state} - {label} ({detail})')
    return 0 if condition else 1


def main():
    admin_user = ensure_user('check_admin', 'check_admin@example.com', True, True)
    farmer_user = ensure_user('check_farmer', 'check_farmer@example.com', False, False)
    other_user = ensure_user('check_other', 'check_other@example.com', False, False)

    farmer_a = ensure_farmer(farmer_user, 'Check', 'Farmer', 'Pune', '9000000001')
    farmer_b = ensure_farmer(other_user, 'Check', 'Other', 'Nashik', '9000000002')

    crop = ensure_crop('Wheat')
    farmer_crop_a = ensure_farmer_crop(farmer_a, crop)
    farmer_crop_b = ensure_farmer_crop(farmer_b, crop)
    task_a = ensure_task(farmer_a, farmer_crop_a, 'Checklist Task A')
    ensure_task(farmer_b, farmer_crop_b, 'Checklist Task B')

    admin_token, _ = Token.objects.get_or_create(user=admin_user)
    farmer_token, _ = Token.objects.get_or_create(user=farmer_user)

    admin_client = APIClient()
    admin_client.credentials(HTTP_AUTHORIZATION=f'Token {admin_token.key}')

    farmer_client = APIClient()
    farmer_client.credentials(HTTP_AUTHORIZATION=f'Token {farmer_token.key}')

    failures = 0

    response = admin_client.get('/api/crops/?search=wheat')
    failures += check('GET /api/crops/?search=wheat', response.status_code == 200, response.status_code)

    response = admin_client.get('/api/crops/?season=kharif')
    failures += check('GET /api/crops/?season=kharif', response.status_code == 200, response.status_code)

    response = admin_client.get('/api/crops/?state=Maharashtra')
    failures += check('GET /api/crops/?state=Maharashtra', response.status_code == 200, response.status_code)

    response = admin_client.get('/api/crops/seasons/')
    failures += check('GET /api/crops/seasons/', response.status_code == 200, response.status_code)

    response = admin_client.get('/api/crops/states/')
    failures += check('GET /api/crops/states/', response.status_code == 200, response.status_code)

    response_farmer = farmer_client.get('/api/tasks/')
    failures += check('GET /api/tasks/ as farmer', response_farmer.status_code == 200, response_farmer.status_code)
    if response_farmer.status_code == 200:
        visible_farmer_ids = [item.get('farmer') for item in response_farmer.json().get('results', [])]
        failures += check(
            'Farmer sees only own tasks',
            all(farmer_id == farmer_a.id for farmer_id in visible_farmer_ids),
            visible_farmer_ids,
        )

    response_admin = admin_client.get('/api/tasks/')
    failures += check('GET /api/tasks/ as admin', response_admin.status_code == 200, response_admin.status_code)
    if response_admin.status_code == 200:
        visible_farmer_ids = [item.get('farmer') for item in response_admin.json().get('results', [])]
        failures += check(
            'Admin sees all tasks',
            farmer_a.id in visible_farmer_ids and farmer_b.id in visible_farmer_ids,
            visible_farmer_ids,
        )

    response = farmer_client.patch(
        f'/api/tasks/{task_a.id}/update-status/',
        {'status': 'in_progress'},
        format='json',
    )
    failures += check('PATCH /api/tasks/{id}/update-status/', response.status_code == 200, response.status_code)

    target_user = ensure_user('delete_target', 'delete_target@example.com', False, False)
    target_farmer = ensure_farmer(target_user, 'Delete', 'Target', 'Kolhapur', '9000000003')

    response = farmer_client.delete(f'/api/farmers/{target_farmer.id}/')
    failures += check('DELETE /api/farmers/{id}/ as farmer', response.status_code == 403, response.status_code)

    response = admin_client.delete(f'/api/farmers/{target_farmer.id}/')
    failures += check('DELETE /api/farmers/{id}/ as admin', response.status_code == 204, response.status_code)

    response = farmer_client.get('/api/farmers/me/')
    failures += check('GET /api/farmers/me/', response.status_code == 200, response.status_code)

    response = admin_client.get('/api/dashboard/stats/')
    failures += check('GET /api/dashboard/stats/', response.status_code == 200, response.status_code)

    response = admin_client.post(
        '/api/tasks/send-reminder/',
        {'farmer_ids': [farmer_a.id], 'message': 'Checklist reminder', 'reminder_type': 'pending'},
        format='json',
    )
    failures += check('POST /api/tasks/send-reminder/', response.status_code in (200, 201), response.status_code)

    print(f'\nSUMMARY: failed={failures}')
    if failures:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
