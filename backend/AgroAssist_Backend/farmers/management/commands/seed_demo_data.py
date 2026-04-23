from datetime import datetime, time, timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from AgroAssist_Backend.crops.models import Crop, CropCareTask, CropGuide, CropRecommendation
from AgroAssist_Backend.farmers.models import Farmer, FarmerCrop, FarmerInventory
from AgroAssist_Backend.tasks.models import FarmerTask, TaskLog, TaskReminder
from AgroAssist_Backend.weather.models import FarmersWeatherAlert, WeatherData, WeatherForecast


class Command(BaseCommand):
    help = "Create demo data for Farm Buddy in one command"

    def handle(self, *args, **options):
        today = timezone.localdate()
        now = timezone.now()
        morning_reading = timezone.make_aware(datetime.combine(today, time(6, 30)))
        evening_reading = timezone.make_aware(datetime.combine(today, time(18, 30)))

        crops_created = 0
        farmers_created = 0
        tasks_created = 0

        crop_catalog = [
            {
                "name": "Rice",
                "season": "Kharif",
                "description": "Staple crop for monsoon season with high local demand.",
                "soil_type": "Loamy",
                "growth_duration_days": 120,
                "optimal_temperature": 28.0,
                "optimal_humidity": 70.0,
                "optimal_soil_moisture": 55.0,
                "water_required_mm_per_week": 35.0,
                "fertilizer_required": "NPK 10-26-26",
                "expected_yield_per_hectare": 4500.00,
                "guide": {
                    "sowing_instructions": "Raise nursery, then transplant healthy seedlings at 20-25 days.",
                    "watering_schedule": "Keep shallow standing water in field during vegetative growth.",
                    "watering_days_interval": 2,
                    "fertilizer_schedule": "Apply basal dose at transplanting and top dressing at 30 and 50 DAP.",
                    "disease_management": "Monitor for blast and sheath blight weekly; spray on early symptoms.",
                    "pest_management": "Use pheromone traps and neem spray for stem borer management.",
                    "harvesting_instructions": "Harvest when 80% panicles turn golden and grain is hard.",
                    "storage_instructions": "Dry grains below safe moisture before storage.",
                },
                "care_tasks": [
                    {
                        "task_name": "Apply first top dressing",
                        "recommended_dap": 30,
                        "description": "Nitrogen top dressing to support tillering.",
                        "frequency": "Once",
                        "instructions": "Broadcast evenly on moist soil and irrigate lightly.",
                    },
                    {
                        "task_name": "Field scouting for pests",
                        "recommended_dap": 20,
                        "description": "Check leaves and stems for early pest attack.",
                        "frequency": "Weekly",
                        "instructions": "Inspect 10 random plants in each plot section.",
                    },
                ],
                "recommendation": {
                    "recommended_season": "Kharif",
                    "recommendation_reason": "Reliable market and suitable rainfall in this zone.",
                    "priority_score": 8,
                },
            },
            {
                "name": "Wheat",
                "season": "Rabi",
                "description": "Winter cereal crop with stable returns and low pest pressure.",
                "soil_type": "Loamy",
                "growth_duration_days": 110,
                "optimal_temperature": 22.0,
                "optimal_humidity": 55.0,
                "optimal_soil_moisture": 45.0,
                "water_required_mm_per_week": 22.0,
                "fertilizer_required": "NPK 12-32-16 + Urea",
                "expected_yield_per_hectare": 3800.00,
                "guide": {
                    "sowing_instructions": "Sow treated seeds in rows with proper spacing.",
                    "watering_schedule": "Irrigate at crown root initiation, tillering, and grain filling.",
                    "watering_days_interval": 10,
                    "fertilizer_schedule": "Apply basal NPK before sowing and split nitrogen in 2 doses.",
                    "disease_management": "Watch for rust symptoms and use resistant varieties where possible.",
                    "pest_management": "Keep field weed-free to reduce pest and disease load.",
                    "harvesting_instructions": "Harvest when grains are hard and moisture falls suitably.",
                    "storage_instructions": "Store in dry, aerated godown with periodic inspection.",
                },
                "care_tasks": [
                    {
                        "task_name": "First irrigation",
                        "recommended_dap": 21,
                        "description": "Critical irrigation at crown root initiation stage.",
                        "frequency": "Once",
                        "instructions": "Provide uniform irrigation without waterlogging.",
                    },
                    {
                        "task_name": "Weed control",
                        "recommended_dap": 25,
                        "description": "Control early weeds to reduce nutrient competition.",
                        "frequency": "Once",
                        "instructions": "Use mechanical weeding or selective herbicide as advised.",
                    },
                ],
                "recommendation": {
                    "recommended_season": "Rabi",
                    "recommendation_reason": "Good fit for cooler months and irrigation availability.",
                    "priority_score": 7,
                },
            },
            {
                "name": "Tomato",
                "season": "Summer",
                "description": "High-value vegetable crop for regular market supply.",
                "soil_type": "Mixed",
                "growth_duration_days": 95,
                "optimal_temperature": 26.0,
                "optimal_humidity": 60.0,
                "optimal_soil_moisture": 50.0,
                "water_required_mm_per_week": 28.0,
                "fertilizer_required": "NPK 19-19-19 + Calcium",
                "expected_yield_per_hectare": 30000.00,
                "guide": {
                    "sowing_instructions": "Use healthy seedlings and transplant in raised beds.",
                    "watering_schedule": "Use frequent light irrigation or drip system.",
                    "watering_days_interval": 3,
                    "fertilizer_schedule": "Fertigation every 7-10 days based on growth stage.",
                    "disease_management": "Prevent blight with timely fungicide and proper airflow.",
                    "pest_management": "Use yellow sticky traps and regular scouting for whitefly.",
                    "harvesting_instructions": "Harvest at breaker or pink stage depending on market distance.",
                    "storage_instructions": "Avoid direct sun and pack in ventilated crates.",
                },
                "care_tasks": [
                    {
                        "task_name": "Stake and tie plants",
                        "recommended_dap": 18,
                        "description": "Support plants to prevent lodging and fruit rot.",
                        "frequency": "Once",
                        "instructions": "Use bamboo/plastic stakes and soft ties.",
                    },
                    {
                        "task_name": "Spray micronutrients",
                        "recommended_dap": 30,
                        "description": "Improve flowering and fruit set.",
                        "frequency": "Bi-weekly",
                        "instructions": "Apply recommended dose in cool hours.",
                    },
                ],
                "recommendation": {
                    "recommended_season": "Summer",
                    "recommendation_reason": "Strong nearby city demand for fresh vegetables.",
                    "priority_score": 9,
                },
            },
        ]

        crops_by_name = {}
        care_templates = {}

        for crop_data in crop_catalog:
            crop, created = Crop.objects.get_or_create(
                name=crop_data["name"],
                season=crop_data["season"],
                defaults={
                    "description": crop_data["description"],
                    "soil_type": crop_data["soil_type"],
                    "growth_duration_days": crop_data["growth_duration_days"],
                    "optimal_temperature": crop_data["optimal_temperature"],
                    "optimal_humidity": crop_data["optimal_humidity"],
                    "optimal_soil_moisture": crop_data["optimal_soil_moisture"],
                    "water_required_mm_per_week": crop_data["water_required_mm_per_week"],
                    "fertilizer_required": crop_data["fertilizer_required"],
                    "expected_yield_per_hectare": crop_data["expected_yield_per_hectare"],
                },
            )
            if created:
                crops_created += 1

            crops_by_name[crop_data["name"]] = crop

            CropGuide.objects.get_or_create(crop=crop, defaults=crop_data["guide"])

            for task_data in crop_data["care_tasks"]:
                care_task, _ = CropCareTask.objects.get_or_create(
                    crop=crop,
                    task_name=task_data["task_name"],
                    recommended_dap=task_data["recommended_dap"],
                    defaults={
                        "description": task_data["description"],
                        "frequency": task_data["frequency"],
                        "instructions": task_data["instructions"],
                    },
                )
                care_templates[(crop_data["name"], task_data["task_name"])] = care_task

            CropRecommendation.objects.get_or_create(
                crop=crop,
                recommended_season=crop_data["recommendation"]["recommended_season"],
                defaults={
                    "recommendation_reason": crop_data["recommendation"]["recommendation_reason"],
                    "priority_score": crop_data["recommendation"]["priority_score"],
                },
            )

        farmer_catalog = [
            {
                "email": "rajesh.patil@example.com",
                "first_name": "Rajesh",
                "last_name": "Patil",
                "phone_number": "9876543210",
                "address": "Village Sonwadi, Taluka Baramati",
                "city": "Pune",
                "state": "Maharashtra",
                "postal_code": 413102,
                "preferred_language": "Marathi",
                "land_area_hectares": 4.5,
                "soil_type": "Loamy",
                "experience_level": "Intermediate",
                "farming_notes": "Uses drip irrigation for vegetable block.",
                "contact_method": "WhatsApp",
                "crop": {
                    "name": "Rice",
                    "planting_date": today - timedelta(days=20),
                    "expected_harvest_date": today + timedelta(days=100),
                    "status": "Growing",
                    "area_allocated_hectares": 2.0,
                    "expected_yield_kg": 8500,
                },
                "inventory": [
                    {
                        "item_name": "Rice Seeds",
                        "item_type": "Seeds",
                        "quantity": 120.0,
                        "unit": "kg",
                        "purchase_date": today - timedelta(days=25),
                        "notes": "Certified seed lot",
                    },
                    {
                        "item_name": "NPK 10-26-26",
                        "item_type": "Fertilizer",
                        "quantity": 18.0,
                        "unit": "bags",
                        "purchase_date": today - timedelta(days=10),
                        "notes": "For top dressing stages",
                    },
                ],
                "tasks": [
                    {
                        "task_name": "Apply first top dressing",
                        "template_task_name": "Apply first top dressing",
                        "task_description": "Apply recommended top dressing for active tillering.",
                        "status": "Pending",
                        "due_date": today + timedelta(days=2),
                        "priority": 8,
                        "importance": "High",
                    },
                ],
                "alerts": [
                    {
                        "alert_title": "Moderate Rain Expected",
                        "alert_message": "Light to moderate rain expected in next 24 hours. Delay pesticide spray.",
                        "severity": "Medium",
                        "alert_type": "Rain",
                        "issued_at": now,
                        "expires_at": now + timedelta(hours=24),
                    }
                ],
            },
            {
                "email": "sunita.sharma@example.com",
                "first_name": "Sunita",
                "last_name": "Sharma",
                "phone_number": "9876501234",
                "address": "Near Canal Road, Kurukshetra",
                "city": "Kurukshetra",
                "state": "Haryana",
                "postal_code": 136118,
                "preferred_language": "Hindi",
                "land_area_hectares": 3.2,
                "soil_type": "Loamy",
                "experience_level": "Expert",
                "farming_notes": "Tracks irrigation and spray activities in notebook.",
                "contact_method": "SMS",
                "crop": {
                    "name": "Wheat",
                    "planting_date": today - timedelta(days=35),
                    "expected_harvest_date": today + timedelta(days=65),
                    "status": "Growing",
                    "area_allocated_hectares": 2.5,
                    "expected_yield_kg": 9200,
                },
                "inventory": [
                    {
                        "item_name": "Wheat Seeds",
                        "item_type": "Seeds",
                        "quantity": 80.0,
                        "unit": "kg",
                        "purchase_date": today - timedelta(days=40),
                        "notes": "HD variety for local climate",
                    },
                    {
                        "item_name": "Weeder Tool",
                        "item_type": "Tools",
                        "quantity": 1.0,
                        "unit": "piece",
                        "purchase_date": today - timedelta(days=200),
                        "notes": "In good condition",
                    },
                ],
                "tasks": [
                    {
                        "task_name": "First irrigation",
                        "template_task_name": "First irrigation",
                        "task_description": "Provide critical irrigation at crown root initiation.",
                        "status": "In Progress",
                        "due_date": today + timedelta(days=1),
                        "priority": 9,
                        "importance": "High",
                    },
                    {
                        "task_name": "Weed control",
                        "template_task_name": "Weed control",
                        "task_description": "Control early weeds in row spacing.",
                        "status": "Pending",
                        "due_date": today + timedelta(days=3),
                        "priority": 7,
                        "importance": "Medium",
                    },
                ],
                "alerts": [
                    {
                        "alert_title": "Cold Morning Advisory",
                        "alert_message": "Low night temperature likely. Avoid late evening irrigation.",
                        "severity": "Low",
                        "alert_type": "Frost",
                        "issued_at": now - timedelta(hours=2),
                        "expires_at": now + timedelta(hours=12),
                    }
                ],
            },
            {
                "email": "imran.khan@example.com",
                "first_name": "Imran",
                "last_name": "Khan",
                "phone_number": "9811122233",
                "address": "Block B, Niphad Farm Cluster",
                "city": "Nashik",
                "state": "Maharashtra",
                "postal_code": 422303,
                "preferred_language": "English",
                "land_area_hectares": 2.1,
                "soil_type": "Mixed",
                "experience_level": "Beginner",
                "farming_notes": "Needs reminders for spray and staking tasks.",
                "contact_method": "WhatsApp",
                "crop": {
                    "name": "Tomato",
                    "planting_date": today - timedelta(days=16),
                    "expected_harvest_date": today + timedelta(days=70),
                    "status": "Growing",
                    "area_allocated_hectares": 1.6,
                    "expected_yield_kg": 42000,
                },
                "inventory": [
                    {
                        "item_name": "Tomato Seedlings",
                        "item_type": "Seeds",
                        "quantity": 3500.0,
                        "unit": "plants",
                        "purchase_date": today - timedelta(days=20),
                        "notes": "Hybrid variety",
                    },
                    {
                        "item_name": "Calcium Nitrate",
                        "item_type": "Fertilizer",
                        "quantity": 8.0,
                        "unit": "bags",
                        "purchase_date": today - timedelta(days=7),
                        "notes": "For blossom-end rot prevention",
                    },
                ],
                "tasks": [
                    {
                        "task_name": "Stake and tie plants",
                        "template_task_name": "Stake and tie plants",
                        "task_description": "Support tomato plants to avoid stem damage.",
                        "status": "Pending",
                        "due_date": today + timedelta(days=1),
                        "priority": 8,
                        "importance": "Critical",
                    },
                    {
                        "task_name": "Spray micronutrients",
                        "template_task_name": "Spray micronutrients",
                        "task_description": "Apply foliar micronutrient dose in early morning.",
                        "status": "Completed",
                        "due_date": today - timedelta(days=1),
                        "completed_date": today - timedelta(days=1),
                        "priority": 6,
                        "importance": "Medium",
                        "is_completed": True,
                        "farmer_notes": "Completed with knapsack sprayer at 7 AM.",
                    },
                ],
                "alerts": [
                    {
                        "alert_title": "Heat Stress Watch",
                        "alert_message": "Day temperature above 34Â°C expected; increase mulch and morning irrigation.",
                        "severity": "High",
                        "alert_type": "Heat",
                        "issued_at": now - timedelta(hours=1),
                        "expires_at": now + timedelta(hours=18),
                    }
                ],
            },
        ]

        for farmer_data in farmer_catalog:
            farmer, created = Farmer.objects.get_or_create(
                email=farmer_data["email"],
                defaults={
                    "first_name": farmer_data["first_name"],
                    "last_name": farmer_data["last_name"],
                    "phone_number": farmer_data["phone_number"],
                    "address": farmer_data["address"],
                    "city": farmer_data["city"],
                    "state": farmer_data["state"],
                    "postal_code": farmer_data["postal_code"],
                    "preferred_language": farmer_data["preferred_language"],
                    "land_area_hectares": farmer_data["land_area_hectares"],
                    "soil_type": farmer_data["soil_type"],
                    "experience_level": farmer_data["experience_level"],
                    "farming_notes": farmer_data["farming_notes"],
                    "contact_method": farmer_data["contact_method"],
                },
            )
            if created:
                farmers_created += 1

            crop_name = farmer_data["crop"]["name"]
            crop = crops_by_name[crop_name]
            farmer_crop, _ = FarmerCrop.objects.get_or_create(
                farmer=farmer,
                crop=crop,
                planting_date=farmer_data["crop"]["planting_date"],
                defaults={
                    "expected_harvest_date": farmer_data["crop"]["expected_harvest_date"],
                    "status": farmer_data["crop"]["status"],
                    "area_allocated_hectares": farmer_data["crop"]["area_allocated_hectares"],
                    "expected_yield_kg": farmer_data["crop"]["expected_yield_kg"],
                },
            )

            for inventory_item in farmer_data["inventory"]:
                FarmerInventory.objects.get_or_create(
                    farmer=farmer,
                    item_name=inventory_item["item_name"],
                    item_type=inventory_item["item_type"],
                    defaults={
                        "quantity": inventory_item["quantity"],
                        "unit": inventory_item["unit"],
                        "purchase_date": inventory_item["purchase_date"],
                        "notes": inventory_item["notes"],
                    },
                )

            for task_data in farmer_data["tasks"]:
                care_template = care_templates.get((crop_name, task_data["template_task_name"]))
                task, created = FarmerTask.objects.get_or_create(
                    farmer=farmer,
                    farmer_crop=farmer_crop,
                    task_name=task_data["task_name"],
                    due_date=task_data["due_date"],
                    defaults={
                        "care_task_template": care_template,
                        "task_description": task_data["task_description"],
                        "status": task_data["status"],
                        "completed_date": task_data.get("completed_date"),
                        "priority": task_data["priority"],
                        "importance": task_data["importance"],
                        "is_completed": task_data.get("is_completed", False),
                        "farmer_notes": task_data.get("farmer_notes", ""),
                    },
                )
                if created:
                    tasks_created += 1

                TaskLog.objects.get_or_create(
                    task=task,
                    action="Created",
                    metadata="source=seed_demo_data",
                    defaults={
                        "description": "Task generated from practical demo dataset.",
                        "performed_by_farmer": farmer,
                    },
                )

                if task.status == "Completed":
                    TaskLog.objects.get_or_create(
                        task=task,
                        action="Completed",
                        metadata="source=seed_demo_data",
                        defaults={
                            "description": "Task marked completed in demo dataset.",
                            "performed_by_farmer": farmer,
                        },
                    )
                else:
                    TaskReminder.objects.get_or_create(
                        task=task,
                        reminder_channel=farmer.contact_method if farmer.contact_method in ["SMS", "WhatsApp", "Email", "App"] else "App",
                        reminder_date=max(today, task.due_date - timedelta(days=1)),
                        defaults={
                            "is_sent": False,
                            "reminder_message": f"Reminder: {task.task_name} is due on {task.due_date}.",
                        },
                    )

            for alert_data in farmer_data["alerts"]:
                FarmersWeatherAlert.objects.get_or_create(
                    farmer=farmer,
                    alert_title=alert_data["alert_title"],
                    issued_at=alert_data["issued_at"],
                    defaults={
                        "alert_message": alert_data["alert_message"],
                        "severity": alert_data["severity"],
                        "alert_type": alert_data["alert_type"],
                        "expires_at": alert_data["expires_at"],
                    },
                )

        weather_snapshots = [
            {
                "location": "Pune",
                "recorded_at": morning_reading,
                "temperature": 24.0,
                "humidity": 82,
                "rainfall": 2,
                "condition": "Cloudy",
                "wind_speed": 10.0,
            },
            {
                "location": "Nashik",
                "recorded_at": evening_reading,
                "temperature": 31.0,
                "humidity": 58,
                "rainfall": 0,
                "condition": "Sunny",
                "wind_speed": 14.0,
            },
        ]

        for weather in weather_snapshots:
            WeatherData.objects.get_or_create(
                location=weather["location"],
                recorded_at=weather["recorded_at"],
                defaults={
                    "temperature": weather["temperature"],
                    "humidity": weather["humidity"],
                    "rainfall": weather["rainfall"],
                    "condition": weather["condition"],
                    "wind_speed": weather["wind_speed"],
                },
            )

        forecasts = [
            {
                "location": "Pune",
                "forecast_date": today + timedelta(days=1),
                "min_temperature": 22.0,
                "max_temperature": 31.0,
                "rainfall_probability": 60,
                "expected_rainfall_mm": 10,
                "humidity": 72,
                "condition": "Rainy",
                "wind_speed": 14.0,
                "forecast_issued_at": now,
            },
            {
                "location": "Nashik",
                "forecast_date": today + timedelta(days=1),
                "min_temperature": 20.0,
                "max_temperature": 33.0,
                "rainfall_probability": 20,
                "expected_rainfall_mm": 1,
                "humidity": 54,
                "condition": "Partly Cloudy",
                "wind_speed": 16.0,
                "forecast_issued_at": now,
            },
        ]

        for forecast in forecasts:
            WeatherForecast.objects.get_or_create(
                location=forecast["location"],
                forecast_date=forecast["forecast_date"],
                defaults={
                    "min_temperature": forecast["min_temperature"],
                    "max_temperature": forecast["max_temperature"],
                    "rainfall_probability": forecast["rainfall_probability"],
                    "expected_rainfall_mm": forecast["expected_rainfall_mm"],
                    "humidity": forecast["humidity"],
                    "condition": forecast["condition"],
                    "wind_speed": forecast["wind_speed"],
                    "forecast_issued_at": forecast["forecast_issued_at"],
                },
            )

        self.stdout.write(self.style.SUCCESS("Practical demo data ready."))
        self.stdout.write("Created/ensured records for crops, guides, recommendations, farmers, inventory, tasks, reminders, logs, and weather.")
        self.stdout.write(f"Crops created: {crops_created}")
        self.stdout.write(f"Farmers created: {farmers_created}")
        self.stdout.write(f"Tasks created: {tasks_created}")
        self.stdout.write(f"Total crops: {Crop.objects.count()}")
        self.stdout.write(f"Total farmers: {Farmer.objects.count()}")
        self.stdout.write(f"Total tasks: {FarmerTask.objects.count()}")

