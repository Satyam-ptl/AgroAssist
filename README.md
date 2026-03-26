# AgroAssist

AgroAssist is a full-stack agriculture management platform with a Django REST backend and a Flutter frontend.

It helps manage:

- Crops and cultivation guidance
- Farmers and farmer profiles
- Farm tasks and priorities
- Weather alerts and advisories

## Repository Layout

- `AgroAssist_Backend/`: Django project and apps (`crops`, `farmers`, `tasks`, `weather`)
- `agro_assist_app/`: Flutter client app
- `import_templates/`: CSV templates for bulk import
- `requirements.txt`: backend dependencies
- `manage.py`: Django entry point

## Core Features

- REST API for all major farm operations
- Role-aware workflows (admin and farmer)
- Task lifecycle tracking with validation
- Crop filtering and recommendations
- Weather alerts and summaries
- Token-based authentication
- Session-expiry handling in Flutter (`401/403` auto logout)

## Tech Stack

- Backend: Python, Django, Django REST Framework
- Frontend: Flutter, Dart
- Database: SQLite (default)

## Quick Start

### 1. Backend

```powershell
cd D:\git\AgroAssist
d:\git\.venv\Scripts\python.exe manage.py check
d:\git\.venv\Scripts\python.exe manage.py migrate
d:\git\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

### 2. Frontend

```powershell
cd D:\git\AgroAssist\agro_assist_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
```

## API Base URL

Flutter reads API URL from `--dart-define`:

- key: `API_BASE_URL`
- default: `http://localhost:8000/api`

For Android emulator use:

- `http://10.0.2.2:8000/api`

## Development Checks

```powershell
# Backend
cd D:\git\AgroAssist
d:\git\.venv\Scripts\python.exe manage.py check

# Frontend
cd D:\git\AgroAssist\agro_assist_app
flutter analyze
flutter test
```

## Run Checklist (Backend + Flutter)

Use this checklist when starting the project from scratch or after switching branches.

1. Start backend first (port `8000`)

```powershell
cd D:\git\AgroAssist
d:\git\.venv\Scripts\python.exe manage.py check
d:\git\.venv\Scripts\python.exe manage.py migrate
d:\git\.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```

2. Verify backend is reachable

- Health/API check: `http://127.0.0.1:8000/api/`
- Auth route check: `http://127.0.0.1:8000/api/auth/login/`

3. Start Flutter app (port `8088` recommended)

```powershell
cd D:\git\AgroAssist\agro_assist_app
flutter pub get
flutter run --release -d web-server --web-hostname 127.0.0.1 --web-port 8088 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

4. Open app URL

- `http://127.0.0.1:8088/`

5. Validate with local admin login

- Username: `Satyam`
- Password: `AgroAssist@123`

### Common Startup Issues

- If `8088` is already in use, stop the existing process or change `--web-port`.
- If login fails with `404` on `/api/auth/login/`, ensure you started backend from `D:\git\AgroAssist` (not another folder).
- If Flutter web debug crashes with DDS/WebSocket errors, run with `--release` as shown above.

## Documentation

- `PROJECT_SUMMARY.md`: architecture and system summary
- `BEGINNER_FILE_GUIDE.md`: beginner-friendly file explanations
- `agro_assist_app/README.md`: Flutter app documentation
- `agro_assist_app/INSTALLATION.md`: frontend setup details
- `agro_assist_app/QUICKSTART.md`: fast startup commands

