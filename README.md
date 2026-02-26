# Farm Buddy Flutter App

A mobile application for **Farm Buddy - Multi-Crop Growth Assistant** built with Flutter and connected to Django REST API backend.

## 📱 Features

- **Dashboard**: Overview of crops, farmers, tasks, and weather alerts
- **Crops Management**: Browse and search crops with detailed information
- **Farmers Management**: View and manage farmer profiles
- **Tasks Management**: Track and complete farming tasks
- **Weather Alerts**: View weather forecasts and alerts

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (version 3.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your system PATH

2. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK and emulator

3. **VS Code** (recommended) with Flutter extension
   - Or use Android Studio with Flutter plugin

4. **Django Backend** must be running
   - The Django REST API should be running on `http://localhost:8000`

## 📦 Installation

### Step 1: Install Flutter

**For Windows:**
```powershell
# Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\src\flutter
# Add C:\src\flutter\bin to PATH

# Verify installation
flutter doctor
```

**For macOS/Linux:**
```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### Step 2: Setup Project

1. Navigate to the Flutter app directory:
```powershell
cd D:\git\farm_buddy_app
```

2. Install dependencies:
```powershell
flutter pub get
```

This will download all required packages:
- `http`: For API communication with Django
- `provider`: For state management
- `intl`: For date formatting
- `shared_preferences`: For local storage

### Step 3: Configure API URL

Open `lib/services/api_service.dart` and update the `baseUrl`:

```dart
// For Android Emulator (default):
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For iOS Simulator:
static const String baseUrl = 'http://localhost:8000/api';

// For Physical Device (replace with your computer's IP):
static const String baseUrl = 'http://192.168.1.5:8000/api';
```

**To find your computer's IP address:**
- Windows: `ipconfig` (look for IPv4 Address)
- macOS/Linux: `ifconfig` or `ip addr`

### Step 4: Start Django Backend

Make sure your Django backend is running:

```powershell
cd D:\git\FarmBuddy
python manage.py runserver 0.0.0.0:8000
```

The `0.0.0.0:8000` allows connections from other devices on the network (including emulator/physical device).

### Step 5: Run Flutter App

**Option 1: Android Emulator**
```powershell
# Start Android emulator from Android Studio
# Or from command line:
flutter emulators --launch <emulator_id>

# Run the app
flutter run
```

**Option 2: Physical Device**
1. Enable Developer Mode on your phone
2. Enable USB Debugging
3. Connect phone via USB
4. Run: `flutter run`

**Option 3: Chrome (Web)**
```powershell
flutter run -d chrome
```

## 🏗️ Project Structure

```
farm_buddy_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── crop_model.dart       # Crop and CropGuide models
│   │   ├── farmer_model.dart     # Farmer, FarmerCrop, FarmerInventory
│   │   ├── task_model.dart       # FarmerTask, TaskReminder, TaskLog
│   │   └── weather_model.dart    # WeatherData, WeatherAlert, Forecast
│   ├── services/                 # API services
│   │   └── api_service.dart      # Django API communication layer
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart      # Dashboard
│   │   ├── crops_screen.dart     # Crops list and details
│   │   ├── farmers_screen.dart   # Farmers list and profiles
│   │   ├── tasks_screen.dart     # Tasks management
│   │   └── weather_screen.dart   # Weather alerts
│   └── widgets/                  # Reusable widgets
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
├── test/                         # Unit tests
└── pubspec.yaml                  # Dependencies configuration
```

## 🔧 Configuration

### Django CORS Settings

The Django backend has been configured to allow Flutter app connections:

**In `FarmBuddy_Backend/settings.py`:**
- `CORS_ALLOW_ALL_ORIGINS = True` - Allows requests from any domain (development only)
- CORS middleware added to MIDDLEWARE list
- REST Framework configured with pagination and permissions

### API Endpoints

All endpoints are accessible at `http://localhost:8000/api/`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/crops/` | GET | Get all crops |
| `/api/crops/{id}/` | GET | Get crop details |
| `/api/crop-guides/` | GET | Get crop guides |
| `/api/farmers/` | GET, POST | Get/create farmers |
| `/api/farmers/{id}/` | GET, PUT, PATCH | Get/update farmer |
| `/api/tasks/` | GET, POST | Get/create tasks |
| `/api/tasks/{id}/` | GET, PUT, PATCH | Get/update task |
| `/api/weather-data/` | GET | Get weather data |
| `/api/weather-alerts/` | GET | Get weather alerts |

## 🎨 UI Features

### Home Screen (Dashboard)
- Statistics cards showing total crops, farmers, pending tasks, and active alerts
- Quick action buttons to navigate to different sections
- Pull-to-refresh functionality

### Crops Screen
- List of all crops with filtering by season (Kharif, Rabi, Summer)
- Crop cards showing name, season, soil type, duration, and yield
- Tap on crop to view detailed information
- Refresh button in app bar

### Farmers Screen
- List of all farmers with their profiles
- Shows name, location, phone, land area, and experience level
- Color-coded experience levels (Beginner, Intermediate, Expert)
- Tap to view full farmer details

### Tasks Screen
- List of all tasks with filtering by status
- Shows task name, farmer, crop, due date, and priority
- Color-coded status (Pending, In Progress, Completed, Overdue)
- Mark tasks as completed with one tap

### Weather Screen
- Weather alerts with severity levels (Low, Medium, High, Critical)
- Alert types: Rain, Frost, Heat, Wind, Disease, Pest
- Active/expired status indicators
- Detailed alert information

## 🚀 Building for Production

### Android APK
```powershell
flutter build apk --release
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```powershell
flutter build appbundle --release
```

### iOS
```powershell
flutter build ios --release
```

## 🐛 Common Issues

### Issue 1: "Failed to load crops" error

**Solution:**
1. Check if Django backend is running: `http://localhost:8000/api/crops/`
2. Verify API URL in `api_service.dart` matches your setup
3. For Android emulator, use `10.0.2.2` instead of `localhost`
4. For physical device, use your computer's IP address

### Issue 2: CORS errors

**Solution:**
1. Ensure `corsheaders` is installed in Django: `pip install django-cors-headers`
2. Check `settings.py` has `CORS_ALLOW_ALL_ORIGINS = True`
3. Verify `corsheaders` is in `INSTALLED_APPS` and middleware

### Issue 3: "flutter: command not found"

**Solution:**
1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Add Flutter to PATH
3. Run: `flutter doctor` to verify installation

### Issue 4: Android SDK not found

**Solution:**
1. Install Android Studio
2. Open Android Studio → Settings → Android SDK
3. Install SDK Platform and SDK Tools
4. Run: `flutter doctor --android-licenses`

## 📚 Learning Resources

### Flutter
- Official Docs: https://flutter.dev/docs
- Flutter Codelabs: https://flutter.dev/docs/codelabs
- Widget Catalog: https://flutter.dev/docs/development/ui/widgets

### Dart
- Dart Language Tour: https://dart.dev/guides/language/language-tour
- Effective Dart: https://dart.dev/guides/language/effective-dart

### API Integration
- http package: https://pub.dev/packages/http
- JSON serialization: https://flutter.dev/docs/development/data-and-backend/json

## 🤝 Contributing

This is a student project for learning Django and Flutter development. Feel free to:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is for educational purposes as part of CSE(DS) coursework at tier 3 college in Maharashtra.

## 👨‍💻 Developer

**Satryam Patel**
- Second Year Engineering Student
- CSE(DS) Department
- Learning Full Stack Development (Django + Flutter)

## 📞 Support

If you have questions or need help:
1. Check the "Common Issues" section above
2. Review Django logs: `python manage.py runserver`
3. Review Flutter logs: `flutter run` output
4. Check API endpoints in browser: `http://localhost:8000/api/`

---

**Happy Coding! 🌾📱**
