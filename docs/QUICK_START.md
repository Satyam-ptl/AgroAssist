# AgroAssist App - Quick Start Guide

## Prerequisites
- Flutter SDK 3.16.0+
- Python 3.8+
- Django installed
- Git for version control

---

## 1. Frontend Setup (Flutter)

### Step 1: Navigate to the Flutter app directory
```bash
cd d:\git\AgroAssist\agro_assist_app
```

### Step 2: Install dependencies
```bash
flutter pub get
```

### Step 3: Run the app
**For Web:**
```bash
flutter run -d chrome
```

**For Android:**
```bash
flutter run -d android
```

**For iOS:**
```bash
flutter run -d ios
```

### Step 4: Verify the app starts
- The home screen should display dashboard with Quick Actions
- Navigation between screens should work smoothly
- No compilation errors

---

## 2. Backend Setup (Django)

### Step 1: Navigate to backend directory
```bash
cd d:\git\AgroAssist
```

### Step 2: Activate virtual environment
```bash
# On Windows
.venv\Scripts\activate

# On macOS/Linux
source .venv/bin/activate
```

### Step 3: Install dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Apply database migrations
```bash
python manage.py migrate
```

### Step 5: Create a superuser (optional)
```bash
python manage.py createsuperuser
```

### Step 6: Run the development server
```bash
python manage.py runserver
```

The API should be accessible at: `http://localhost:8000`

---

## 3. Connecting Frontend to Backend

### Update API Configuration
**File**: `agro_assist_app/lib/services/api_service.dart`

Ensure the `baseUrl` matches your backend:
```dart
final String baseUrl = 'http://localhost:8000';
```

For Android emulator or physical device, use:
```dart
final String baseUrl = 'http://10.0.2.2:8000';  // Android
```

### Test Connection
1. Launch the Flutter app
2. Navigate to any screen that makes an API call
3. Check for successful responses or error messages
4. Review API logs in Django console

---

## 4. Testing

### Run Flutter Tests
```bash
cd agro_assist_app
flutter test
```

**Expected Output**: All tests should pass âœ“

### Run Flutter Analysis (code quality check)
```bash
flutter analyze
```

**Note**: Some lint warnings about deprecated APIs are expected and non-critical.

### Run Django System Check
```bash
cd d:\git\AgroAssist
python manage.py check
```

**Expected**: No issues found

---

## 5. Main App Screens

### Home Screen
- **Location**: `/agro_assist_app/lib/screens/home_screen.dart`
- **Features**: Dashboard overview, quick actions, recent activity
- **Route**: `/`

### Crops Screen
- **Location**: `/agro_assist_app/lib/screens/crops_screen.dart`
- **Features**: View all crops, add new crop, edit crop details
- **Route**: `/crops`

### Tasks Screen
- **Location**: `/agro_assist_app/lib/screens/tasks_screen.dart`
- **Features**: Task management, filtering, status tracking
- **Route**: `/tasks`

### Weather Screen
- **Location**: `/agro_assist_app/lib/screens/weather_screen.dart`
- **Features**: Current weather, forecast (integration ready)
- **Route**: `/weather`

---

## 6. Available API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout

### Crops
- `GET /crops/` - List all crops (paginated)
- `POST /crops/create` - Create new crop
- `PUT /crops/{id}/update` - Update crop info
- `DELETE /crops/{id}/delete` - Delete crop

### Tasks
- `GET /tasks/` - List all tasks (with filtering)
- `POST /tasks/create` - Create new task
- `PUT /tasks/{id}/update` - Update task
- `DELETE /tasks/{id}/delete` - Delete task

### Weather
- `GET /weather` - Current weather data
- `GET /weather/forecast` - 7-day forecast

### Health Check
- `GET /` - API health check

---

## 7. Common Issues & Solutions

### Issue: "Failed to connect to backend"
**Solution:**
1. Verify Django server is running: `python manage.py runserver`
2. Check API base URL in `api_service.dart`
3. Ensure CORS is configured in Django settings
4. Try using `10.0.2.2:8000` for Android emulator

### Issue: "Flutter compilation errors"
**Solution:**
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter pub upgrade`
4. Try again with `flutter run`

### Issue: "Port 8000 already in use"
**Solution:**
```bash
python manage.py runserver 8001
# Then update API base URL to use port 8001
```

### Issue: "Database not found"
**Solution:**
```bash
python manage.py migrate
```

---

## 8. Database Management

### View Database
```bash
# Using Django shell
python manage.py shell

# Or using SQLite browser
# Install: DB Browser for SQLite
# Open: db.sqlite3
```

### Reset Database
```bash
# Delete existing data
python manage.py flush

# Or remove and recreate
rm db.sqlite3
python manage.py migrate
```

### Create Sample Data
Sample crop and task data can be added through:
1. Django admin panel: `/admin`
2. API endpoints using curl/Postman
3. Django management commands

---

## 9. Building for Production

### Flutter Web Build
```bash
cd agro_assist_app
flutter build web --release
```

Output will be in `build/web/`

### Django Production Deployment
1. Set `DEBUG = False` in `settings.py`
2. Configure allowed hosts
3. Set up proper database (PostgreSQL recommended)
4. Configure static files with whitenoise or CDN
5. Set environment variables for sensitive data

---

## 10. Useful Commands

### Flutter
```bash
flutter clean                  # Clean build files
flutter pub get               # Install dependencies
flutter pub upgrade           # Upgrade dependencies
flutter analyze               # Code quality check
flutter test                  # Run tests
flutter doctor                # Diagnose issues
flutter devices               # List connected devices
```

### Django
```bash
python manage.py migrate      # Apply migrations
python manage.py makemigrations  # Create migrations
python manage.py shell        # Interactive shell
python manage.py createsuperuser  # Create admin user
python manage.py collectstatic    # Collect static files
python manage.py runserver    # Run development server
python manage.py test         # Run tests
```

---

## 11. Project Structure

```
AgroAssist/
â”œâ”€â”€ agro_assist_app/           # Flutter frontend
â”‚   â”œâ”€â”€ lib/
â”‚   â”‚   â”œâ”€â”€ screens/          # UI screens
â”‚   â”‚   â”œâ”€â”€ services/         # API services
â”‚   â”‚   â”œâ”€â”€ models/           # Data models
â”‚   â”‚   â”œâ”€â”€ widgets/          # Reusable widgets
â”‚   â”‚   â””â”€â”€ main.dart         # Entry point
â”‚   â””â”€â”€ pubspec.yaml          # Dependencies
â”‚
â”œâ”€â”€ AgroAssist_Backend/        # Django backend
â”‚   â”œâ”€â”€ crops/                # Crops app
â”‚   â”œâ”€â”€ tasks/                # Tasks app
â”‚   â”œâ”€â”€ farmers/              # Farmers app (if present)
â”‚   â”œâ”€â”€ weather/              # Weather app (if present)
â”‚   â”œâ”€â”€ settings.py           # Configuration
â”‚   â”œâ”€â”€ urls.py               # URL routing
â”‚   â””â”€â”€ manage.py             # Django management
â”‚
â””â”€â”€ README.md                 # Project documentation
```

---

## 12. Support

For detailed information about changes, see `CHANGES_SUMMARY.md`

For bugs or feature requests, check the project documentation or reach out to the development team.

---

## Next Steps

1. âœ… Set up both frontend and backend
2. âœ… Test the app is running
3. âœ… Verify API connection works
4. âœ… Create sample crops and tasks
5. âœ… Explore all features
6. ðŸ”„ Continue development or deployment

Happy farming! ðŸŒ¾

