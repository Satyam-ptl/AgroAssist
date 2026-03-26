# ðŸš€ Quick Start Guide - AgroAssist Flutter App

## Prerequisites Checklist

Before starting, make sure you have:

- [ ] **Flutter SDK installed** - Run `flutter doctor` to verify
- [ ] **Android Studio or VS Code** with Flutter plugin
- [ ] **Django backend ready** - The AgroAssist Django project should be set up
- [ ] **Python packages installed** - django, djangorestframework, django-cors-headers

## Step-by-Step Setup (10 minutes)

### 1ï¸âƒ£ Install Flutter (First Time Only)

**Windows:**
```powershell
# Download Flutter from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter doctor
```

**Expected output:**
```
Doctor summary (to see all details, run flutter doctor -v):
[âœ“] Flutter (Channel stable, 3.x.x)
[âœ“] Android toolchain
[âœ“] Chrome - develop for the web
[âœ“] Android Studio
```

### 2ï¸âƒ£ Setup Flutter Project

```powershell
# Navigate to Flutter app directory
cd D:\git\AgroAssist\agro_assist_app

# Install all dependencies
flutter pub get
```

**Expected output:**
```
Running "flutter pub get" in agro_assist_app...
Resolving dependencies...
+ http 1.1.0
+ provider 6.1.1
+ intl 0.18.1
+ shared_preferences 2.2.2
Got dependencies!
```

### 3ï¸âƒ£ Configure API Connection

Pass API URL with `--dart-define` while running the app:

```powershell
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Chrome
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api

# Physical device (replace with your IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
```

### 4ï¸âƒ£ Start Django Backend

**Open Terminal 1:**
```powershell
cd D:\git\AgroAssist
python manage.py runserver 0.0.0.0:8000
```

**Expected output:**
```
Django version 6.0.2, using settings 'AgroAssist_Backend.settings'
Starting development server at http://0.0.0.0:8000/
Quit the server with CTRL-BREAK.
```

**âœ… Verify:** Open browser to `http://localhost:8000/api/crops/`
You should see JSON data.

### 5ï¸âƒ£ Start Flutter App

**Open Terminal 2:**
```powershell
cd D:\git\AgroAssist\agro_assist_app
flutter run
```

**First time setup (may take 5-10 minutes):**
```
Launching lib\main.dart on Android SDK built for x86...
Running Gradle task 'assembleDebug'...
Resolving dependencies...
Downloading https://...
Building...
```

**Once built:**
```
âœ“ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing app...
Syncing files to device...

Flutter run key commands:
r Hot reload
R Hot restart
h List all commands
```

**âœ… App is now running on your emulator/device!**

## ðŸŽ¯ Test the Connection

### In Django Terminal (Terminal 1):

When you use the Flutter app, you should see API requests:
```
[22/Feb/2026 12:45:10] "GET /api/crops/?page_size=5 HTTP/1.1" 200 1234
[22/Feb/2026 12:45:11] "GET /api/farmers/?page_size=5 HTTP/1.1" 200 987
[22/Feb/2026 12:45:12] "GET /api/tasks/?status=Pending HTTP/1.1" 200 456
```

**âœ… If you see these logs, Flutter is successfully connected!**

### In Flutter App:

1. **Dashboard** should show:
   - Total Crops count
   - Total Farmers count
   - Pending Tasks count
   - Active Alerts count

2. **Try these:**
   - Tap "Browse Crops" â†’ Should show list of crops
   - Tap "Manage Farmers" â†’ Should show farmer profiles
   - Tap "View Tasks" â†’ Should show tasks list
   - Pull down to refresh any screen

## âŒ Common Problems & Solutions

### Problem 1: "flutter: command not found"

**Solution:**
```powershell
# Add Flutter to PATH
$env:Path += ";C:\src\flutter\bin"

# Or permanently add in System Environment Variables
```

### Problem 2: "Failed to load crops"

**Check 1:** Is Django running?
```powershell
# Should see "Starting development server at http://0.0.0.0:8000/"
```

**Check 2:** Can you access API in browser?
```
http://localhost:8000/api/crops/
```

**Check 3:** Is `--dart-define=API_BASE_URL=...` set correctly?
- Android emulator: `http://10.0.2.2:8000/api` âœ…
- iOS simulator / Chrome: `http://localhost:8000/api` âœ…
- Physical device: `http://YOUR_IP:8000/api` âœ…

**Check 4:** CORS configured in Django?
```python
# settings.py should have:
INSTALLED_APPS = [
    ...
    'corsheaders',  # âœ…
]

MIDDLEWARE = [
    ...
    'corsheaders.middleware.CorsMiddleware',  # âœ…
    ...
]

CORS_ALLOW_ALL_ORIGINS = True  # âœ…
```

### Problem 3: "No connected devices"

**For Android:**
```powershell
# List available devices
flutter devices

# Start emulator from Android Studio:
# Tools â†’ Device Manager â†’ Start emulator

# Or from command line:
flutter emulators
flutter emulators --launch <emulator_name>
```

**For Physical Device:**
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect via USB
4. Allow debugging when prompted on phone

### Problem 4: Gradle build failed

**Solution:**
```powershell
cd D:\git\AgroAssist\agro_assist_app\android
.\gradlew clean

cd ..
flutter clean
flutter pub get
flutter run
```

### Problem 5: "CORS policy error"

**Solution - Update Django settings.py:**
```python
# Make sure corsheaders is BEFORE CommonMiddleware
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',  # â† Must be here
    'django.middleware.common.CommonMiddleware',  # â† After CORS
    ...
]
```

## ðŸ“± Device-Specific URLs

| Device Type | API Base URL | How to Get IP |
|-------------|--------------|---------------|
| Android Emulator | `http://10.0.2.2:8000/api` | Fixed IP |
| iOS Simulator | `http://localhost:8000/api` | Fixed |
| Physical Device (WiFi) | `http://192.168.1.X:8000/api` | Run `ipconfig` |

**Important:** Phone and computer must be on **same WiFi network**!

## ðŸ”„ Development Workflow

### Making Changes to Flutter Code:

1. Edit code in VS Code or Android Studio
2. Press `r` in terminal (hot reload) - changes appear in ~1 second âš¡
3. For major changes, press `R` (hot restart)

### Making Changes to Django Code:

1. Edit Python files
2. Django auto-reloads (you'll see "Performing system checks..." in terminal)
3. Refresh Flutter app to see changes

### Adding New API Endpoints:

**Django side:**
1. Create ViewSet method in `views.py`
2. Register in `urls.py` if needed
3. Create serializer if needed

**Flutter side:**
1. Add method to `api_service.dart`
2. Call from screen where needed
3. Update UI to display data

## ðŸ“š Useful Commands

### Flutter Commands:
```powershell
flutter doctor          # Check setup
flutter devices         # List connected devices
flutter run             # Run app
flutter clean           # Clean build files
flutter pub get         # Install dependencies
flutter pub upgrade     # Upgrade packages
flutter build apk       # Build APK for Android
```

### Django Commands:
```powershell
python manage.py runserver 0.0.0.0:8000  # Start server
python manage.py migrate                  # Run migrations
python manage.py createsuperuser          # Create admin user
python manage.py shell                    # Python shell
```

### Keyboard Shortcuts in Flutter:
```
r   - Hot reload (fast, preserves state)
R   - Hot restart (slower, resets state)
q   - Quit
h   - Help (show all commands)
```

## ðŸŽ“ Next Steps

Once everything is running:

1. **Explore the Code:**
   - `lib/screens/` - All UI screens
   - `lib/models/` - Data models
   - `lib/services/api_service.dart` - API calls
   - `lib/main.dart` - App entry point

2. **Add Sample Data:**
   - Go to Django admin: `http://localhost:8000/admin/`
   - Add crops, farmers, tasks
   - Refresh Flutter app to see them

3. **Customize:**
   - Change colors in `lib/main.dart` theme
   - Add new screens
   - Create new API endpoints
   - Add forms for creating/editing data

4. **Learn More:**
   - Flutter docs: https://flutter.dev/docs
   - Django REST Framework: https://www.django-rest-framework.org/
   - Read `FLUTTER_DJANGO_INTEGRATION.md` for detailed explanation

## âš¡ Quick Reference

**Start both servers:**
```powershell
# Terminal 1 - Django
cd D:\git\AgroAssist ; python manage.py runserver 0.0.0.0:8000

# Terminal 2 - Flutter  
cd D:\git\AgroAssist\agro_assist_app ; flutter run
```

**Check if everything works:**
1. Django running? â†’ `http://localhost:8000/api/crops/`
2. Flutter running? â†’ Check emulator screen
3. Connected? â†’ Check Django terminal for API requests

**Emergency reset:**
```powershell
# Kill all processes
# Close terminals
# Restart computer
# Start fresh
```

---

## âœ… Success Checklist

- [ ] Flutter SDK installed and `flutter doctor` passes
- [ ] Android Studio with emulator OR physical device connected
- [ ] Django server running on `http://0.0.0.0:8000`
- [ ] Can access `http://localhost:8000/api/crops/` in browser
- [ ] Updated `baseUrl` in `api_service.dart` correctly
- [ ] Ran `flutter pub get` successfully
- [ ] Flutter app launches on device/emulator
- [ ] Dashboard shows crop/farmer counts
- [ ] Django terminal shows API requests when using app

**If all checked âœ… - You're ready to go! ðŸŽ‰**

## ðŸ†˜ Still Having Issues?

1. **Check Django logs** - Terminal 1 shows all API requests and errors
2. **Check Flutter logs** - Terminal 2 shows app errors
3. **Test API manually** - Use browser or Postman: `http://localhost:8000/api/crops/`
4. **Review settings:**
   - Django: `settings.py` - CORS configuration
   - Flutter: `api_service.dart` - baseUrl

5. **Read detailed docs:**
   - `README.md` in agro_assist_app folder
   - `FLUTTER_DJANGO_INTEGRATION.md` in AgroAssist folder

---

**Happy Coding! ðŸŒ¾ðŸ“±**

*Made by: Satryam Patel | CSE(DS) Second Year Student*

