# Beginner File Guide

This guide explains what important files do in simple terms.

## Root Files

- `manage.py`: Run server, migrations, and admin commands.
- `requirements.txt`: Python packages for backend.
- `README.md`: Main project overview and run commands.
- `PROJECT_SUMMARY.md`: Architecture-level summary.
- `BEGINNER_FILE_GUIDE.md`: This beginner reference.
- `FLUTTER_DJANGO_INTEGRATION.md`: Frontend-backend integration notes.
- `db.sqlite3`: Local development database.

## Backend Folder: `AgroAssist_Backend/`

- `settings.py`: Main Django settings (apps, middleware, DB, REST config).
- `urls.py`: API route registration.
- `wsgi.py` / `asgi.py`: Server entry points.
- `templates/`: HTML templates for server-rendered pages.
- `static/`: Static assets for backend pages.

### App: `crops/`

- `models.py`: Crop tables and relationships.
- `serializers.py`: Input/output validation and JSON mapping.
- `views.py`: API logic for crop endpoints.
- `admin.py`: Django admin configuration.
- `migrations/`: Database schema history.

### App: `farmers/`

- `models.py`: Farmer profile and related entities.
- `serializers.py`: Validation and API mapping.
- `views.py`: Farmer API logic.
- `auth_views.py` / `auth_serializers.py` / `auth_urls.py`: Authentication endpoints and logic.
- `migrations/`: Schema history for farmer domain.

### App: `tasks/`

- `models.py`: Task records and status data.
- `serializers.py`: Task validation and payload shaping.
- `views.py`: Task endpoint behavior.
- `migrations/`: Schema history for tasks.

### App: `weather/`

- `models.py`: Weather and alert data models.
- `serializers.py`: Weather payload validation.
- `views.py`: Weather endpoint logic.
- `migrations/`: Schema history for weather.

## Frontend Folder: `agro_assist_app/`

- `pubspec.yaml`: Flutter dependencies and app metadata.
- `lib/main.dart`: App start, theme, and first route logic.
- `lib/screens/`: App screens.
- `lib/services/api_service.dart`: HTTP requests to backend APIs.
- `lib/services/auth_service.dart`: token/session storage and restore.
- `lib/services/auth_ui_service.dart`: logout and unauthorized session handling.
- `lib/models/`: Dart models for API JSON.
- `test/`: frontend tests.

## Platform Folders Inside Flutter App

- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`
- These contain platform-specific runner/build files.

## Files Beginners Usually Do Not Edit

- `.dart_tool/`, `build/`, generated plugin registrants
- Cache folders (`__pycache__`, etc.)
- Temporary logs and generated artifacts

## Suggested Reading Order

1. `README.md`
2. `PROJECT_SUMMARY.md`
3. `agro_assist_app/README.md`
4. This file when you need quick file-purpose clarity

