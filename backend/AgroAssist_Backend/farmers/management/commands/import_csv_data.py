import csv
from datetime import timedelta
from pathlib import Path

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from AgroAssist_Backend.crops.models import Crop
from AgroAssist_Backend.farmers.models import Farmer, FarmerCrop
from AgroAssist_Backend.tasks.models import FarmerTask


class Command(BaseCommand):
    help = "Import crops, farmers, and tasks from CSV files with validation and duplicate checks"

    CROP_SEASONS = {"Kharif", "Rabi", "Summer"}
    SOIL_TYPES = {"Clay", "Sandy", "Loamy", "Mixed"}
    FARMER_LANGUAGES = {"English", "Hindi", "Marathi"}
    FARMER_EXPERIENCE = {"Beginner", "Intermediate", "Expert"}
    FARMER_CROP_STATUS = {"Planned", "Growing", "Harvested", "Completed"}
    TASK_STATUS = {"Pending", "In Progress", "Completed", "Overdue", "Cancelled"}
    TASK_IMPORTANCE = {"Low", "Medium", "High", "Critical"}

    def add_arguments(self, parser):
        parser.add_argument("--crops", type=str, help="Path to crops CSV")
        parser.add_argument("--farmers", type=str, help="Path to farmers CSV")
        parser.add_argument("--tasks", type=str, help="Path to tasks CSV")
        parser.add_argument("--delimiter", type=str, default=",", help="CSV delimiter (default: ,)")
        parser.add_argument("--encoding", type=str, default="utf-8", help="CSV encoding (default: utf-8)")
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Validate and simulate import without saving to database",
        )
        parser.add_argument(
            "--write-templates",
            type=str,
            help="Write sample CSV templates to this folder and exit",
        )

    def handle(self, *args, **options):
        delimiter = options["delimiter"]
        encoding = options["encoding"]
        dry_run = options["dry_run"]

        if options.get("write_templates"):
            self._write_templates(options["write_templates"])
            return

        crops_path = options.get("crops")
        farmers_path = options.get("farmers")
        tasks_path = options.get("tasks")

        if not crops_path and not farmers_path and not tasks_path:
            raise CommandError("Provide at least one file: --crops, --farmers, or --tasks")

        summary = {
            "crops_created": 0,
            "crops_updated": 0,
            "crops_skipped": 0,
            "farmers_created": 0,
            "farmers_updated": 0,
            "farmers_skipped": 0,
            "tasks_created": 0,
            "tasks_updated": 0,
            "tasks_skipped": 0,
            "errors": [],
        }

        with transaction.atomic():
            if crops_path:
                self._import_crops(crops_path, delimiter, encoding, summary)
            if farmers_path:
                self._import_farmers(farmers_path, delimiter, encoding, summary)
            if tasks_path:
                self._import_tasks(tasks_path, delimiter, encoding, summary)

            if dry_run:
                transaction.set_rollback(True)

        self._print_summary(summary, dry_run)

    def _import_crops(self, file_path, delimiter, encoding, summary):
        required_fields = [
            "name",
            "season",
            "soil_type",
            "growth_duration_days",
            "optimal_temperature",
            "optimal_humidity",
            "optimal_soil_moisture",
        ]
        rows = self._read_csv_rows(file_path, delimiter, encoding, required_fields)

        for row_number, row in rows:
            try:
                name = self._required(row, "name", row_number, "crops")
                season = self._choice(row.get("season"), self.CROP_SEASONS, "season", row_number, "crops")
                soil_type = self._choice(row.get("soil_type"), self.SOIL_TYPES, "soil_type", row_number, "crops")

                defaults = {
                    "description": row.get("description", ""),
                    "soil_type": soil_type,
                    "growth_duration_days": self._to_int(row.get("growth_duration_days"), "growth_duration_days", row_number, "crops"),
                    "optimal_temperature": self._to_float(row.get("optimal_temperature"), "optimal_temperature", row_number, "crops"),
                    "optimal_humidity": self._to_float(row.get("optimal_humidity"), "optimal_humidity", row_number, "crops"),
                    "optimal_soil_moisture": self._to_float(row.get("optimal_soil_moisture"), "optimal_soil_moisture", row_number, "crops"),
                    "water_required_mm_per_week": self._to_float_optional(row.get("water_required_mm_per_week"), default=25.0),
                    "fertilizer_required": row.get("fertilizer_required") or "NPK",
                    "expected_yield_per_hectare": self._to_float_optional(row.get("expected_yield_per_hectare"), default=0.0),
                }

                crop, created = Crop.objects.update_or_create(
                    name=name,
                    season=season,
                    defaults=defaults,
                )
                if created:
                    summary["crops_created"] += 1
                else:
                    summary["crops_updated"] += 1

            except Exception as exc:
                summary["crops_skipped"] += 1
                summary["errors"].append(f"crops row {row_number}: {exc}")

    def _import_farmers(self, file_path, delimiter, encoding, summary):
        required_fields = [
            "email",
            "first_name",
            "last_name",
            "phone_number",
            "address",
            "city",
            "state",
            "postal_code",
            "land_area_hectares",
            "soil_type",
            "experience_level",
        ]
        rows = self._read_csv_rows(file_path, delimiter, encoding, required_fields)

        for row_number, row in rows:
            try:
                email = self._required(row, "email", row_number, "farmers").lower()
                phone_number = self._required(row, "phone_number", row_number, "farmers")

                existing_with_phone = Farmer.objects.filter(phone_number=phone_number).exclude(email=email).first()
                if existing_with_phone:
                    raise ValueError(
                        f"phone_number '{phone_number}' already belongs to {existing_with_phone.email}."
                    )

                preferred_language = row.get("preferred_language") or "English"
                experience_level = self._choice(
                    row.get("experience_level"),
                    self.FARMER_EXPERIENCE,
                    "experience_level",
                    row_number,
                    "farmers",
                )
                soil_type = self._choice(row.get("soil_type"), self.SOIL_TYPES, "soil_type", row_number, "farmers")
                if preferred_language:
                    preferred_language = self._choice(
                        preferred_language,
                        self.FARMER_LANGUAGES,
                        "preferred_language",
                        row_number,
                        "farmers",
                    )

                defaults = {
                    "first_name": self._required(row, "first_name", row_number, "farmers"),
                    "last_name": self._required(row, "last_name", row_number, "farmers"),
                    "phone_number": phone_number,
                    "address": self._required(row, "address", row_number, "farmers"),
                    "city": self._required(row, "city", row_number, "farmers"),
                    "state": self._required(row, "state", row_number, "farmers"),
                    "postal_code": self._to_int(row.get("postal_code"), "postal_code", row_number, "farmers"),
                    "preferred_language": preferred_language,
                    "land_area_hectares": self._to_float(row.get("land_area_hectares"), "land_area_hectares", row_number, "farmers"),
                    "soil_type": soil_type,
                    "experience_level": experience_level,
                    "farming_notes": row.get("farming_notes", ""),
                    "contact_method": row.get("contact_method") or "WhatsApp",
                }

                _, created = Farmer.objects.update_or_create(
                    email=email,
                    defaults=defaults,
                )
                if created:
                    summary["farmers_created"] += 1
                else:
                    summary["farmers_updated"] += 1

            except Exception as exc:
                summary["farmers_skipped"] += 1
                summary["errors"].append(f"farmers row {row_number}: {exc}")

    def _import_tasks(self, file_path, delimiter, encoding, summary):
        required_fields = [
            "farmer_email",
            "crop_name",
            "task_name",
            "due_date",
        ]
        rows = self._read_csv_rows(file_path, delimiter, encoding, required_fields)

        for row_number, row in rows:
            try:
                farmer_email = self._required(row, "farmer_email", row_number, "tasks").lower()
                crop_name = self._required(row, "crop_name", row_number, "tasks")
                task_name = self._required(row, "task_name", row_number, "tasks")
                due_date = self._to_date(self._required(row, "due_date", row_number, "tasks"), "due_date", row_number, "tasks")

                farmer = Farmer.objects.filter(email=farmer_email).first()
                if not farmer:
                    raise ValueError(f"farmer '{farmer_email}' not found. Import farmers first.")

                crop_season = row.get("crop_season", "").strip()
                crop_qs = Crop.objects.filter(name=crop_name)
                if crop_season:
                    crop_qs = crop_qs.filter(season=crop_season)
                crop = crop_qs.first()
                if not crop:
                    if crop_season:
                        raise ValueError(f"crop '{crop_name}' with season '{crop_season}' not found.")
                    raise ValueError(f"crop '{crop_name}' not found. Import crops first.")

                planting_date = row.get("planting_date", "").strip()
                if planting_date:
                    planting_date = self._to_date(planting_date, "planting_date", row_number, "tasks")
                else:
                    planting_date = timezone.localdate() - timedelta(days=15)

                expected_harvest = row.get("expected_harvest_date", "").strip()
                expected_harvest_date = (
                    self._to_date(expected_harvest, "expected_harvest_date", row_number, "tasks") if expected_harvest else None
                )

                farmer_crop_status = row.get("farmer_crop_status", "").strip() or "Growing"
                farmer_crop_status = self._choice(
                    farmer_crop_status,
                    self.FARMER_CROP_STATUS,
                    "farmer_crop_status",
                    row_number,
                    "tasks",
                )

                farmer_crop, _ = FarmerCrop.objects.get_or_create(
                    farmer=farmer,
                    crop=crop,
                    planting_date=planting_date,
                    defaults={
                        "expected_harvest_date": expected_harvest_date,
                        "status": farmer_crop_status,
                        "area_allocated_hectares": self._to_float_optional(row.get("area_allocated_hectares"), default=1.0),
                        "expected_yield_kg": self._to_int_optional(row.get("expected_yield_kg")),
                    },
                )

                status = row.get("status", "").strip() or "Pending"
                status = self._choice(status, self.TASK_STATUS, "status", row_number, "tasks")
                importance = row.get("importance", "").strip() or "Medium"
                importance = self._choice(importance, self.TASK_IMPORTANCE, "importance", row_number, "tasks")
                is_completed = self._to_bool_optional(row.get("is_completed"), default=(status == "Completed"))
                completed_date = row.get("completed_date", "").strip()
                if completed_date:
                    completed_date = self._to_date(completed_date, "completed_date", row_number, "tasks")
                elif is_completed or status == "Completed":
                    completed_date = due_date
                else:
                    completed_date = None

                defaults = {
                    "task_description": row.get("task_description") or "Task imported from CSV.",
                    "status": status,
                    "completed_date": completed_date,
                    "priority": self._to_int_optional(row.get("priority"), default=5),
                    "importance": importance,
                    "is_completed": is_completed,
                    "farmer_notes": row.get("farmer_notes", ""),
                }

                _, created = FarmerTask.objects.update_or_create(
                    farmer=farmer,
                    farmer_crop=farmer_crop,
                    task_name=task_name,
                    due_date=due_date,
                    defaults=defaults,
                )

                if created:
                    summary["tasks_created"] += 1
                else:
                    summary["tasks_updated"] += 1

            except Exception as exc:
                summary["tasks_skipped"] += 1
                summary["errors"].append(f"tasks row {row_number}: {exc}")

    def _read_csv_rows(self, file_path, delimiter, encoding, required_fields):
        path = Path(file_path)
        if not path.exists():
            raise CommandError(f"File not found: {path}")

        with path.open("r", encoding=encoding, newline="") as csv_file:
            reader = csv.DictReader(csv_file, delimiter=delimiter)
            if not reader.fieldnames:
                raise CommandError(f"CSV has no header row: {path}")

            header_set = {header.strip() for header in reader.fieldnames if header}
            missing = [field for field in required_fields if field not in header_set]
            if missing:
                raise CommandError(f"{path.name} is missing required columns: {', '.join(missing)}")

            rows = []
            for index, row in enumerate(reader, start=2):
                cleaned = {k.strip(): (v.strip() if isinstance(v, str) else v) for k, v in row.items() if k}
                if any(value for value in cleaned.values()):
                    rows.append((index, cleaned))
            return rows

    def _required(self, row, field_name, row_number, section):
        value = (row.get(field_name) or "").strip()
        if not value:
            raise ValueError(f"{section}.{field_name} is required (row {row_number}).")
        return value

    def _choice(self, value, allowed_values, field_name, row_number, section):
        if value is None:
            raise ValueError(f"{section}.{field_name} is required (row {row_number}).")

        normalized = value.strip().lower()
        for option in allowed_values:
            if option.lower() == normalized:
                return option

        allowed = ", ".join(sorted(allowed_values))
        raise ValueError(f"{section}.{field_name}='{value}' is invalid (row {row_number}). Allowed: {allowed}")

    def _to_int(self, value, field_name, row_number, section):
        try:
            return int(str(value).strip())
        except Exception as exc:
            raise ValueError(f"{section}.{field_name} must be an integer (row {row_number}).") from exc

    def _to_int_optional(self, value, default=None):
        if value is None or str(value).strip() == "":
            return default
        return int(str(value).strip())

    def _to_float(self, value, field_name, row_number, section):
        try:
            return float(str(value).strip())
        except Exception as exc:
            raise ValueError(f"{section}.{field_name} must be a number (row {row_number}).") from exc

    def _to_float_optional(self, value, default=None):
        if value is None or str(value).strip() == "":
            return default
        return float(str(value).strip())

    def _to_bool_optional(self, value, default=False):
        if value is None or str(value).strip() == "":
            return default

        lowered = str(value).strip().lower()
        truthy = {"1", "true", "yes", "y"}
        falsy = {"0", "false", "no", "n"}
        if lowered in truthy:
            return True
        if lowered in falsy:
            return False
        raise ValueError(f"Invalid boolean value '{value}'. Use true/false, yes/no, or 1/0.")

    def _to_date(self, value, field_name, row_number, section):
        try:
            return timezone.datetime.strptime(value, "%Y-%m-%d").date()
        except Exception as exc:
            raise ValueError(
                f"{section}.{field_name} must be YYYY-MM-DD (row {row_number})."
            ) from exc

    def _write_templates(self, output_dir):
        directory = Path(output_dir)
        directory.mkdir(parents=True, exist_ok=True)

        crops_template = directory / "crops_template.csv"
        farmers_template = directory / "farmers_template.csv"
        tasks_template = directory / "tasks_template.csv"

        crops_template.write_text(
            "name,season,description,soil_type,growth_duration_days,optimal_temperature,optimal_humidity,optimal_soil_moisture,water_required_mm_per_week,fertilizer_required,expected_yield_per_hectare\n"
            "Rice,Kharif,Staple monsoon crop,Loamy,120,28,70,55,35,NPK 10-26-26,4500\n"
            "Wheat,Rabi,Major winter crop,Loamy,110,22,55,45,22,NPK 12-32-16,3800\n",
            encoding="utf-8",
        )

        farmers_template.write_text(
            "email,first_name,last_name,phone_number,address,city,state,postal_code,preferred_language,land_area_hectares,soil_type,experience_level,farming_notes,contact_method\n"
            "rajesh.patil@example.com,Rajesh,Patil,9876543210,Village Sonwadi,Pune,Maharashtra,413102,Marathi,4.5,Loamy,Intermediate,Uses drip irrigation,WhatsApp\n"
            "sunita.sharma@example.com,Sunita,Sharma,9876501234,Canal Road,Kurukshetra,Haryana,136118,Hindi,3.2,Loamy,Expert,Maintains spray records,SMS\n",
            encoding="utf-8",
        )

        tasks_template.write_text(
            "farmer_email,crop_name,crop_season,planting_date,expected_harvest_date,farmer_crop_status,area_allocated_hectares,expected_yield_kg,task_name,task_description,due_date,status,completed_date,priority,importance,is_completed,farmer_notes\n"
            "rajesh.patil@example.com,Rice,Kharif,2026-02-01,2026-06-05,Growing,2.0,8500,Apply first top dressing,Top dressing at tillering stage,2026-03-01,Pending,,8,High,false,\n"
            "sunita.sharma@example.com,Wheat,Rabi,2026-01-20,2026-04-20,Growing,2.5,9200,First irrigation,Critical irrigation at CRI stage,2026-02-28,In Progress,,9,High,false,\n",
            encoding="utf-8",
        )

        self.stdout.write(self.style.SUCCESS("CSV templates generated:"))
        self.stdout.write(f"- {crops_template}")
        self.stdout.write(f"- {farmers_template}")
        self.stdout.write(f"- {tasks_template}")

    def _print_summary(self, summary, dry_run):
        if dry_run:
            self.stdout.write(self.style.WARNING("Dry run completed. No database changes were saved."))
        else:
            self.stdout.write(self.style.SUCCESS("Import completed."))

        self.stdout.write("--- Summary ---")
        self.stdout.write(f"Crops: created={summary['crops_created']}, updated={summary['crops_updated']}, skipped={summary['crops_skipped']}")
        self.stdout.write(f"Farmers: created={summary['farmers_created']}, updated={summary['farmers_updated']}, skipped={summary['farmers_skipped']}")
        self.stdout.write(f"Tasks: created={summary['tasks_created']}, updated={summary['tasks_updated']}, skipped={summary['tasks_skipped']}")

        if summary["errors"]:
            self.stdout.write(self.style.WARNING("--- Row Errors ---"))
            for err in summary["errors"]:
                self.stdout.write(f"- {err}")

