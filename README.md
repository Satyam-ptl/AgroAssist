# AgroAssist

[![CI](https://img.shields.io/github/actions/workflow/status/Satyam-ptl/AgroAssist/django.yml?branch=main)](https://github.com/Satyam-ptl/AgroAssist/actions)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

AgroAssist is a full-stack agriculture management platform with a Django REST backend and a Flutter frontend. It helps manage crops, farmers, farm tasks, weather alerts, reminders, and admin workflows in one place.

## Overview

The repository is organized into three main areas:

- `backend/` for the Django project, API, database config, and deployment files
- `frontend/` for the Flutter app
- `docs/` for setup and project guides

## Features

- Token-based authentication for admin and farmer roles
- Crop, farmer, task, and weather management APIs
- Pagination, filtering, validation, and role-based permissions
- Reminder generation for farm tasks
- Cross-platform Flutter UI for web and Android
- Docker and GitHub Actions support

## Tech Stack

- Backend: Python, Django, Django REST Framework
- Frontend: Flutter, Dart
- Database: SQLite by default, PostgreSQL via `DATABASE_URL`
- CI/CD: GitHub Actions
- Containerization: Docker and Docker Compose

## Folder Structure

```text
AgroAssist/
├── backend/
│   ├── AgroAssist_Backend/
│   ├── api/
│   ├── import_templates/
│   ├── manage.py
│   ├── requirements.txt
│   ├── vercel.json
│   ├── Dockerfile
│   └── .env.example
├── frontend/
│   └── agro_assist_app/
├── docs/
├── .github/
├── .gitignore
├── docker-compose.yml
└── README.md
```

## Setup

### Prerequisites

- Python 3.11 or newer
- Flutter stable channel
- Git
- Optional: Docker Desktop for containerized PostgreSQL

### Backend Setup

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### Frontend Setup

```powershell
cd frontend/agro_assist_app
flutter pub get
flutter run
```

### Docker Setup

```powershell
docker compose up --build
```

The Django service uses the PostgreSQL container and reads environment values from `backend/.env`.

## Deployment Guide

### Backend (Vercel)

1. Import the repository into Vercel.
2. Set root directory to `backend`.
3. Build command: `pip install -r requirements.txt`.
4. Output command (if asked): `python manage.py collectstatic --noinput`.
5. Configure environment variables from `backend/.env.example`:
	- `SECRET_KEY`
	- `DEBUG=False`
	- `ALLOWED_HOSTS=.vercel.app,<your-domain>`
	- `DATABASE_URL=<production-postgres-url>`
	- `CORS_ALLOW_ALL_ORIGINS=False`
	- `CORS_ALLOWED_ORIGINS=<frontend-domain>`
	- `CSRF_TRUSTED_ORIGINS=<frontend-domain>`

### Containerized Backend (VM / ECS / Azure / GCP)

```powershell
docker compose up -d --build
docker compose logs -f django
```

Production notes:

- Keep `DEBUG=False`.
- Use a managed PostgreSQL database and strong credentials.
- Set `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, and `CSRF_COOKIE_SECURE` to `True` behind HTTPS.
- Restrict CORS and CSRF origins to your frontend domains only.

## Release Workflow (GitHub)

```powershell
git checkout -b release/prod-hardening
git add .
git commit -m "chore: production hardening, docker entrypoint, ci and deployment docs"
git push -u origin release/prod-hardening
```

Then open a PR to `main` and verify GitHub Actions checks pass before merge.

## Environment Files

- `backend/.env` is local only and should never be committed
- `backend/.env.example` is committed and contains placeholder values
- `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, and `DATABASE_URL` are loaded from environment variables

## API Docs

- Backend project summary: `docs/PROJECT_SUMMARY.md`
- Beginner guide: `docs/BEGINNER_FILE_GUIDE.md`
- Change log: `docs/CHANGES_SUMMARY.md`
- CSV import guide: `docs/CSV_IMPORT_GUIDE.md`
- Flutter integration notes: `docs/FLUTTER_DJANGO_INTEGRATION.md`
- Implementation notes: `docs/IMPLEMENTATION_COMPLETE.md`
- Quick start: `docs/QUICK_START.md`
- Technical integration: `docs/TECHNICAL_INTEGRATION.md`

## Development Checks

```powershell
# Backend
cd backend
python manage.py check
python manage.py test AgroAssist_Backend.crops AgroAssist_Backend.farmers AgroAssist_Backend.tasks AgroAssist_Backend.weather

# Frontend
cd frontend/agro_assist_app
flutter analyze
flutter test
```

## Security Notes

- Do not commit real secrets or credentials
- Use `createsuperuser` instead of shared admin credentials
- Keep `db.sqlite3` out of version control

## Contributing

1. Create a branch for your work
2. Make focused changes
3. Run the relevant backend or Flutter checks
4. Open a pull request

## License

This project is released under the MIT License.
