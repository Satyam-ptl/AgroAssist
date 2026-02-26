# 🚀 Quick Start Guide - Farm Buddy Flutter App

## Prerequisites Checklist

Before starting, make sure you have:

- [ ] **Flutter SDK installed** - Run `flutter doctor` to verify
- [ ] **Android Studio or VS Code** with Flutter plugin
- [ ] **Django backend ready** - The FarmBuddy Django project should be set up
- [ ] **Python packages installed** - django, djangorestframework, django-cors-headers

## Step-by-Step Setup (10 minutes)

### 1️⃣ Install Flutter (First Time Only)

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
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain
[✓] Chrome - develop for the web
[✓] Android Studio
```

### 2️⃣ Setup Flutter Project

```powershell
# Navigate to Flutter app directory
cd D:\git\farm_buddy_app

# Install all dependencies
flutter pub get
```

**Expected output:**
```
Running "flutter pub get" in farm_buddy_app...
Resolving dependencies...
+ http 1.1.0
+ provider 6.1.1
+ intl 0.18.1
+ shared_preferences 2.2.2
Got dependencies!
```

### 3️⃣ Configure API Connection

**Edit:** `lib/services/api_service.dart`

**For Android Emulator (most common):**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**For Physical Device:**
1. Find your computer's IP:
   ```powershell
   ipconfig  # Look for IPv4 Address (e.g., 192.168.1.5)
   ```

2. Update baseUrl:
   ```dart
   static const String baseUrl = 'http://192.168.1.5:8000/api';
   ```

### 4️⃣ Start Django Backend

**Open Terminal 1:**
```powershell
cd D:\git\FarmBuddy
python manage.py runserver 0.0.0.0:8000
```

**Expected output:**
```
Django version 6.0.2, using settings 'FarmBuddy_Backend.settings'
Starting development server at http://0.0.0.0:8000/
Quit the server with CTRL-BREAK.
```

**✅ Verify:** Open browser to `http://localhost:8000/api/crops/`
You should see JSON data.

### 5️⃣ Start Flutter App

**Open Terminal 2:**
```powershell
cd D:\git\farm_buddy_app
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
✓ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing app...
Syncing files to device...

Flutter run key commands:
r Hot reload
R Hot restart
h List all commands
```

**✅ App is now running on your emulator/device!**

## 🎯 Test the Connection

### In Django Terminal (Terminal 1):

When you use the Flutter app, you should see API requests:
```
[22/Feb/2026 12:45:10] "GET /api/crops/?page_size=5 HTTP/1.1" 200 1234
[22/Feb/2026 12:45:11] "GET /api/farmers/?page_size=5 HTTP/1.1" 200 987
[22/Feb/2026 12:45:12] "GET /api/tasks/?status=Pending HTTP/1.1" 200 456
```

**✅ If you see these logs, Flutter is successfully connected!**

### In Flutter App:

1. **Dashboard** should show:
   - Total Crops count
   - Total Farmers count
   - Pending Tasks count
   - Active Alerts count

2. **Try these:**
   - Tap "Browse Crops" → Should show list of crops
   - Tap "Manage Farmers" → Should show farmer profiles
   - Tap "View Tasks" → Should show tasks list
   - Pull down to refresh any screen

## ❌ Common Problems & Solutions

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

**Check 3:** Is baseUrl correct in api_service.dart?
- Android emulator: `http://10.0.2.2:8000/api` ✅
- iOS simulator: `http://localhost:8000/api` ✅
- Physical device: `http://YOUR_IP:8000/api` ✅

**Check 4:** CORS configured in Django?
```python
# settings.py should have:
INSTALLED_APPS = [
    ...
    'corsheaders',  # ✅
]

MIDDLEWARE = [
    ...
    'corsheaders.middleware.CorsMiddleware',  # ✅
    ...
]

CORS_ALLOW_ALL_ORIGINS = True  # ✅
```

### Problem 3: "No connected devices"

**For Android:**
```powershell
# List available devices
flutter devices

# Start emulator from Android Studio:
# Tools → Device Manager → Start emulator

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
cd D:\git\farm_buddy_app\android
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
    'corsheaders.middleware.CorsMiddleware',  # ← Must be here
    'django.middleware.common.CommonMiddleware',  # ← After CORS
    ...
]
```

## 📱 Device-Specific URLs

| Device Type | API Base URL | How to Get IP |
|-------------|--------------|---------------|
| Android Emulator | `http://10.0.2.2:8000/api` | Fixed IP |
| iOS Simulator | `http://localhost:8000/api` | Fixed |
| Physical Device (WiFi) | `http://192.168.1.X:8000/api` | Run `ipconfig` |

**Important:** Phone and computer must be on **same WiFi network**!

## 🔄 Development Workflow

### Making Changes to Flutter Code:

1. Edit code in VS Code or Android Studio
2. Press `r` in terminal (hot reload) - changes appear in ~1 second ⚡
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

## 📚 Useful Commands

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

## 🎓 Next Steps

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

## ⚡ Quick Reference

**Start both servers:**
```powershell
# Terminal 1 - Django
cd D:\git\FarmBuddy ; python manage.py runserver 0.0.0.0:8000

# Terminal 2 - Flutter  
cd D:\git\farm_buddy_app ; flutter run
```

**Check if everything works:**
1. Django running? → `http://localhost:8000/api/crops/`
2. Flutter running? → Check emulator screen
3. Connected? → Check Django terminal for API requests

**Emergency reset:**
```powershell
# Kill all processes
# Close terminals
# Restart computer
# Start fresh
```

---

## ✅ Success Checklist

- [ ] Flutter SDK installed and `flutter doctor` passes
- [ ] Android Studio with emulator OR physical device connected
- [ ] Django server running on `http://0.0.0.0:8000`
- [ ] Can access `http://localhost:8000/api/crops/` in browser
- [ ] Updated `baseUrl` in `api_service.dart` correctly
- [ ] Ran `flutter pub get` successfully
- [ ] Flutter app launches on device/emulator
- [ ] Dashboard shows crop/farmer counts
- [ ] Django terminal shows API requests when using app

**If all checked ✅ - You're ready to go! 🎉**

## 🆘 Still Having Issues?

1. **Check Django logs** - Terminal 1 shows all API requests and errors
2. **Check Flutter logs** - Terminal 2 shows app errors
3. **Test API manually** - Use browser or Postman: `http://localhost:8000/api/crops/`
4. **Review settings:**
   - Django: `settings.py` - CORS configuration
   - Flutter: `api_service.dart` - baseUrl

5. **Read detailed docs:**
   - `README.md` in farm_buddy_app folder
   - `FLUTTER_DJANGO_INTEGRATION.md` in FarmBuddy folder

---

**Happy Coding! 🌾📱**

*Made by: Satryam Patel | CSE(DS) Second Year Student*
