# CSV Import Guide (Beginner Friendly)

This guide helps you import large datasets (for example, cleaned Kaggle CSV files) into Farm Buddy.

## 1) Generate sample templates

Run this from the backend folder:

```powershell
d:/git/.venv-1/Scripts/python.exe manage.py import_csv_data --write-templates .\import_templates
```

This creates:
- `import_templates/crops_template.csv`
- `import_templates/farmers_template.csv`
- `import_templates/tasks_template.csv`

Use these headers as your format.

## 2) Put your real data into CSV files

- Keep date format as `YYYY-MM-DD`
- Keep category values exactly from allowed options
- Save files as UTF-8

## 3) Validate first (safe dry run)

```powershell
d:/git/.venv-1/Scripts/python.exe manage.py import_csv_data --crops .\import_templates\crops_template.csv --farmers .\import_templates\farmers_template.csv --tasks .\import_templates\tasks_template.csv --dry-run
```

Dry run checks rows and errors but does not save data.

## 4) Run actual import

```powershell
d:/git/.venv-1/Scripts/python.exe manage.py import_csv_data --crops .\import_templates\crops_template.csv --farmers .\import_templates\farmers_template.csv --tasks .\import_templates\tasks_template.csv
```

## 5) Re-run behavior

The importer is duplicate-safe:
- Crops are upserted by `(name + season)`
- Farmers are upserted by `email`
- Tasks are upserted by `(farmer + farmer_crop + task_name + due_date)`

So re-running updates existing rows instead of creating duplicate records.

## Important options

- `--dry-run` : validate only, do not save
- `--delimiter ';'` : use semicolon-delimited CSV
- `--encoding utf-8` : default encoding

## Common mistakes

1. Wrong date format (`DD-MM-YYYY`) -> use `YYYY-MM-DD`
2. Invalid choice values (example: `kharif`) -> use `Kharif`
3. Importing tasks before farmers/crops -> import farmers/crops first

## Kaggle Column Mapping (Quick Sheet)

Use this when Kaggle column names are different from your template.

### A) Crop dataset mapping

| If Kaggle column is... | Put into template column... |
|---|---|
| `Crop`, `crop_name`, `CropName` | `name` |
| `Season`, `crop_season` | `season` (`Kharif`/`Rabi`/`Summer`) |
| `Soil`, `soil`, `Soil Type` | `soil_type` (`Clay`/`Sandy`/`Loamy`/`Mixed`) |
| `Duration`, `days_to_harvest` | `growth_duration_days` |
| `Temp`, `avg_temp`, `temperature` | `optimal_temperature` |
| `Humidity`, `avg_humidity` | `optimal_humidity` |
| `Soil Moisture`, `soil_moisture` | `optimal_soil_moisture` |
| `Water Requirement`, `water_mm` | `water_required_mm_per_week` |
| `Fertilizer`, `fertilizer_name` | `fertilizer_required` |
| `Yield`, `yield_per_hectare` | `expected_yield_per_hectare` |

### B) Farmer dataset mapping

| If Kaggle column is... | Put into template column... |
|---|---|
| `email`, `Email` | `email` |
| `first_name`, `fname`, `FarmerName` | `first_name` |
| `last_name`, `lname` | `last_name` |
| `phone`, `mobile` | `phone_number` |
| `address`, `location_detail` | `address` |
| `city`, `district_city` | `city` |
| `state`, `province` | `state` |
| `pincode`, `postal`, `zip` | `postal_code` |
| `language` | `preferred_language` (`English`/`Hindi`/`Marathi`) |
| `land_size`, `land_area` | `land_area_hectares` |
| `soil` | `soil_type` |
| `experience`, `experience_level` | `experience_level` (`Beginner`/`Intermediate`/`Expert`) |
| `notes` | `farming_notes` |
| `contact`, `contact_channel` | `contact_method` |

### C) Task dataset mapping

| If Kaggle column is... | Put into template column... |
|---|---|
| `farmer_email`, `email` | `farmer_email` |
| `crop`, `crop_name` | `crop_name` |
| `season` | `crop_season` |
| `sowing_date`, `start_date` | `planting_date` |
| `harvest_date` | `expected_harvest_date` |
| `crop_status` | `farmer_crop_status` |
| `task`, `task_name` | `task_name` |
| `description`, `task_desc` | `task_description` |
| `due`, `due_date` | `due_date` (`YYYY-MM-DD`) |
| `status` | `status` (`Pending`/`In Progress`/`Completed`/`Overdue`/`Cancelled`) |
| `priority` | `priority` (number) |
| `importance` | `importance` (`Low`/`Medium`/`High`/`Critical`) |
| `done`, `is_done` | `is_completed` (`true/false`) |
| `remarks`, `notes` | `farmer_notes` |

## Beginner-safe workflow for Kaggle files

1. Download Kaggle CSV.
2. Open in Excel/Google Sheets.
3. Keep only useful columns.
4. Rename columns to match templates exactly.
5. Convert date columns to `YYYY-MM-DD`.
6. Export as UTF-8 CSV.
7. Run `--dry-run` first.
8. Fix row errors.
9. Run final import.

## Example final commands

```powershell
d:/git/.venv-1/Scripts/python.exe manage.py import_csv_data --crops .\data\kaggle_crops_clean.csv --farmers .\data\kaggle_farmers_clean.csv --tasks .\data\kaggle_tasks_clean.csv --dry-run
```

```powershell
d:/git/.venv-1/Scripts/python.exe manage.py import_csv_data --crops .\data\kaggle_crops_clean.csv --farmers .\data\kaggle_farmers_clean.csv --tasks .\data\kaggle_tasks_clean.csv
```
