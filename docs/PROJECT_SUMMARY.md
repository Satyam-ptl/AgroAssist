# Project Summary

## Overview

Farm Buddy is a full-stack monorepo that combines:

- A Django REST backend for farm data and workflows
- A Flutter frontend for web/mobile client access

Primary domains:

- Crops
- Farmers
- Tasks
- Weather
- Authentication/session management

## High-Level Architecture

- Client: Flutter app (`agro_assist_app`)
- API: Django REST endpoints under `/api/`
- Data layer: Django ORM with SQLite by default

Data flow:

1. Flutter sends HTTP requests to Django API.
2. Django viewsets validate input through serializers.
3. ORM persists and queries data.
4. JSON responses return to Flutter models/services.

## Backend Modules

- `AgroAssist_Backend/crops/`: crop records, recommendations, related operations
- `AgroAssist_Backend/farmers/`: farmer profiles and farmer-linked crop data
- `AgroAssist_Backend/tasks/`: task creation, validation, status updates
- `AgroAssist_Backend/weather/`: weather alerts and forecast data

Cross-cutting backend pieces:

- `AgroAssist_Backend/settings.py`: installed apps, middleware, REST config
- `AgroAssist_Backend/urls.py`: API routing
- `AgroAssist_Backend/templates/`: dashboard pages and static integration

## Frontend Modules

- `lib/main.dart`: app bootstrap and auth gate
- `lib/screens/`: UI screens (home, crops, farmers, tasks, weather)
- `lib/services/api_service.dart`: HTTP API integration
- `lib/services/auth_service.dart`: session persistence and auth state
- `lib/services/auth_ui_service.dart`: logout and unauthorized handling
- `lib/models/`: JSON model mapping

## Authentication and Reliability

- Token-based auth used for protected endpoints.
- Flutter persists session locally and restores on startup.
- Unauthorized API responses (`401/403`) trigger forced logout and redirect to login.
- Backend validation enforces consistency for task and farmer-crop workflows.

## Operational Notes

- Backend default local endpoint: `http://localhost:8000`
- Frontend default API endpoint: `http://localhost:8000/api`
- Android emulator API endpoint: `http://10.0.2.2:8000/api`

## Recommended Developer Workflow

1. Run backend checks and server.
2. Run frontend with explicit `API_BASE_URL` define.
3. Execute `flutter analyze` and `flutter test` before pushing changes.
4. Keep docs synchronized with code-level behavior changes.

