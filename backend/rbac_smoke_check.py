from datetime import date, timedelta

from django.contrib.auth.models import User
from django.conf import settings
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from AgroAssist_Backend.crops.models import Crop
from AgroAssist_Backend.farmers.models import Farmer, FarmerCrop, FarmerInventory
from AgroAssist_Backend.tasks.models import FarmerTask, TaskReminder, TaskLog
from AgroAssist_Backend.weather.models import FarmersWeatherAlert


PREFIX = "[RBAC-SMOKE]"

if "testserver" not in settings.ALLOWED_HOSTS:
    settings.ALLOWED_HOSTS.append("testserver")


def _print(message):
    print(f"{PREFIX} {message}")


def _ensure_user(username, email, password, is_staff=False, is_superuser=False):
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            "email": email,
            "is_staff": is_staff,
            "is_superuser": is_superuser,
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
        user.set_password(password)
        user.save()
    return user


def _ensure_farmer(email, first_name, last_name, phone_number, city):
    farmer, created = Farmer.objects.get_or_create(
        email=email,
        defaults={
            "first_name": first_name,
            "last_name": last_name,
            "phone_number": phone_number,
            "address": "RBAC Street",
            "city": city,
            "state": "Maharashtra",
            "postal_code": 411001,
            "preferred_language": "English",
            "land_area_hectares": 2.0,
            "soil_type": "Loamy",
            "experience_level": "Intermediate",
            "contact_method": "WhatsApp",
        },
    )
    if not created:
        dirty = False
        if farmer.first_name != first_name:
            farmer.first_name = first_name
            dirty = True
        if farmer.last_name != last_name:
            farmer.last_name = last_name
            dirty = True
        if farmer.city != city:
            farmer.city = city
            dirty = True
        if dirty:
            farmer.save()
    return farmer


def _ensure_crop():
    crop = Crop.objects.order_by("id").first()
    if crop:
        return crop
    return Crop.objects.create(
        name="RBAC Test Crop",
        description="RBAC seed data",
        season="Kharif",
        soil_type="Loamy",
        growth_duration_days=120,
        optimal_temperature=27.0,
        optimal_humidity=60.0,
        optimal_soil_moisture=40.0,
        water_required_mm_per_week=25.0,
        fertilizer_required="NPK",
        expected_yield_per_hectare=1000,
    )


def _upsert_task_bundle(farmer, crop, task_name_suffix):
    planting_date = date.today() - timedelta(days=7)
    farmer_crop, _ = FarmerCrop.objects.get_or_create(
        farmer=farmer,
        crop=crop,
        planting_date=planting_date,
        defaults={
            "expected_harvest_date": date.today() + timedelta(days=90),
            "status": "Growing",
            "area_allocated_hectares": 1.0,
            "expected_yield_kg": 1000,
        },
    )

    FarmerInventory.objects.get_or_create(
        farmer=farmer,
        item_name=f"Inventory {task_name_suffix}",
        defaults={
            "item_type": "Seeds",
            "quantity": 10,
            "unit": "kg",
            "purchase_date": date.today() - timedelta(days=2),
            "expiry_date": date.today() + timedelta(days=45),
            "notes": "rbac seed",
        },
    )

    task, _ = FarmerTask.objects.get_or_create(
        farmer=farmer,
        farmer_crop=farmer_crop,
        task_name=f"Task {task_name_suffix}",
        defaults={
            "task_description": "rbac task",
            "status": "Pending",
            "due_date": date.today() + timedelta(days=5),
            "priority": 5,
            "importance": "Medium",
            "is_completed": False,
        },
    )

    TaskReminder.objects.get_or_create(
        task=task,
        reminder_channel="App",
        reminder_date=date.today() + timedelta(days=1),
        defaults={
            "is_sent": False,
            "reminder_message": "rbac reminder",
        },
    )

    TaskLog.objects.get_or_create(
        task=task,
        action="Created",
        defaults={
            "description": "rbac log",
            "performed_by_farmer": farmer,
            "metadata": "{}",
        },
    )

    FarmersWeatherAlert.objects.get_or_create(
        farmer=farmer,
        alert_title=f"Alert {task_name_suffix}",
        defaults={
            "alert_message": "rbac alert",
            "severity": "Medium",
            "alert_type": "Rain",
            "issued_at": timezone.now(),
            "is_read": False,
        },
    )

    return farmer_crop, task


def _extract_ids(response_json):
    if isinstance(response_json, dict) and "results" in response_json:
        return [item.get("id") for item in response_json.get("results", [])]
    if isinstance(response_json, list):
        return [item.get("id") for item in response_json]
    return []


def _assert(condition, message):
    if not condition:
        raise AssertionError(message)


admin_user = User.objects.filter(is_staff=True).order_by("id").first()
if admin_user is None:
    admin_user = _ensure_user(
        username="rbac_admin",
        email="rbac_admin@example.com",
        password="RbacAdmin@123",
        is_staff=True,
        is_superuser=True,
    )

owner_user = _ensure_user(
    username="rbac_farmer_owner",
    email="rbac_owner@example.com",
    password="RbacOwner@123",
    is_staff=False,
    is_superuser=False,
)

owner_farmer = _ensure_farmer(
    email="rbac_owner@example.com",
    first_name="Rbac",
    last_name="Owner",
    phone_number="9999000001",
    city="Pune",
)

other_farmer = _ensure_farmer(
    email="rbac_other@example.com",
    first_name="Rbac",
    last_name="Other",
    phone_number="9999000002",
    city="Nashik",
)

crop = _ensure_crop()
_owner_crop, owner_task = _upsert_task_bundle(owner_farmer, crop, "Owner")
_other_crop, other_task = _upsert_task_bundle(other_farmer, crop, "Other")

admin_token, _ = Token.objects.get_or_create(user=admin_user)
farmer_token, _ = Token.objects.get_or_create(user=owner_user)

_print(f"Using admin user={admin_user.username}, farmer user={owner_user.username}")

farmer_client = APIClient()
farmer_client.credentials(HTTP_AUTHORIZATION=f"Token {farmer_token.key}")

admin_client = APIClient()
admin_client.credentials(HTTP_AUTHORIZATION=f"Token {admin_token.key}")

# Farmer: farmers list should include only own farmer profile
resp = farmer_client.get("/api/farmers/")
_assert(resp.status_code == 200, f"Farmer /api/farmers/ status={resp.status_code}")
farmer_ids = _extract_ids(resp.json())
_assert(farmer_ids == [owner_farmer.id], f"Farmer saw unexpected farmers: {farmer_ids}")

# Farmer: direct access to another farmer should be blocked
resp = farmer_client.get(f"/api/farmers/{other_farmer.id}/")
_assert(resp.status_code == 404, f"Farmer can access other farmer detail: status={resp.status_code}")

# Farmer: scoped collections
for path, expected_owner_id in [
    ("/api/farmer-crops/", owner_farmer.id),
    ("/api/inventory/", owner_farmer.id),
    ("/api/tasks/", owner_farmer.id),
    ("/api/task-reminders/", owner_task.id),
    ("/api/task-logs/", owner_task.id),
    ("/api/weather-alerts/", owner_farmer.id),
]:
    resp = farmer_client.get(path)
    _assert(resp.status_code == 200, f"Farmer {path} status={resp.status_code}")
    body = resp.json()
    rows = body.get("results", []) if isinstance(body, dict) else body
    if path in ["/api/task-reminders/", "/api/task-logs/"]:
        values = [row.get("task") for row in rows]
    else:
        values = [row.get("farmer") for row in rows]
    _assert(all(v == expected_owner_id for v in values), f"Farmer leakage at {path}: {values}")

# Farmer: query-param escalation attempts must not leak
resp = farmer_client.get(f"/api/weather-alerts/?farmer={other_farmer.id}")
_assert(resp.status_code == 200, f"Farmer weather filter status={resp.status_code}")
rows = resp.json().get("results", [])
_assert(all(row.get("farmer") == owner_farmer.id for row in rows), "Farmer weather filter leaked other farmer data")

resp = farmer_client.get(f"/api/inventory/for_farmer/?farmer_id={other_farmer.id}")
_assert(resp.status_code == 200, f"Farmer inventory for_farmer status={resp.status_code}")
rows = resp.json().get("results", [])
_assert(all(row.get("farmer") == owner_farmer.id for row in rows), "Farmer inventory for_farmer leaked other farmer data")

# Admin: broad visibility remains
resp = admin_client.get("/api/farmers/")
_assert(resp.status_code == 200, f"Admin /api/farmers/ status={resp.status_code}")
admin_farmer_ids = _extract_ids(resp.json())
_assert(owner_farmer.id in admin_farmer_ids and other_farmer.id in admin_farmer_ids, "Admin cannot see expected farmers")

resp = admin_client.get(f"/api/weather-alerts/?farmer={other_farmer.id}")
_assert(resp.status_code == 200, f"Admin weather filter status={resp.status_code}")
rows = resp.json().get("results", [])
_assert(all(row.get("farmer") == other_farmer.id for row in rows), "Admin weather farmer filter not respected")

_print("PASS: farmer is owner-scoped; admin retains broad visibility")
