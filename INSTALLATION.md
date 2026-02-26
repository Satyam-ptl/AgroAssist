# 📥 Complete Installation Guide - Flutter & Requirements

## For Students: Installing Everything from Scratch

This guide walks you through installing all required software for the Farm Buddy Flutter app.

---

## ⏱️ Time Required

- **Windows:** 2-3 hours (includes downloads)
- **macOS:** 1.5-2 hours
- **Linux:** 1-2 hours

---

## 📋 Part 1: Install Flutter SDK

### Windows Installation:

#### Step 1: Download Flutter

1. Go to: https://docs.flutter.dev/get-started/install/windows
2. Click "**Download Flutter SDK**" (about 1.5 GB)
3. Save `flutter_windows_3.x.x-stable.zip` to your Downloads folder

#### Step 2: Extract Flutter

```powershell
# Create a folder for Flutter (DO NOT use Program Files or spaces in path)
New-Item -ItemType Directory -Path "C:\src" -Force

# Extract the ZIP file to C:\src\flutter
# You can use:
# - Windows Explorer: Right-click ZIP → Extract All
# - Or this PowerShell command:
Expand-Archive -Path "$env:USERPROFILE\Downloads\flutter_windows_*.zip" -DestinationPath "C:\src"
```

**Result:** You should have `C:\src\flutter\` folder with `bin`, `packages`, etc.

#### Step 3: Add Flutter to PATH

**Method 1: Using PowerShell (Temporary for current session)**
```powershell
$env:Path += ";C:\src\flutter\bin"
```

**Method 2: Using System Settings (Permanent)**
1. Press `Win + X` → Click "System"
2. Click "**Advanced system settings**"
3. Click "**Environment Variables**"
4. Under "**User variables**", find `Path` → Click "**Edit**"
5. Click "**New**"
6. Type: `C:\src\flutter\bin`
7. Click "**OK**" on all dialogs
8. **Close and reopen PowerShell**

#### Step 4: Verify Installation

```powershell
flutter --version
```

**Expected output:**
```
Flutter 3.x.x • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart 3.x.x • DevTools 2.x.x
```

✅ If you see this, Flutter is installed!

#### Step 5: Run Flutter Doctor

```powershell
flutter doctor
```

**Expected output:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x, on Microsoft Windows...)
[✗] Android toolchain - NOT INSTALLED (we'll fix this next)
[✗] Chrome - NOT INSTALLED
[✗] Visual Studio - NOT INSTALLED
[✗] Android Studio - NOT INSTALLED
[✗] VS Code - NOT INSTALLED
[✗] Connected device - NONE
```

Don't worry about the ✗ marks - we'll fix them!

---

## 📋 Part 2: Install Android Studio (Required for Android Development)

### Windows:

#### Step 1: Download Android Studio

1. Go to: https://developer.android.com/studio
2. Click "**Download Android Studio**"
3. Accept license terms
4. Download `android-studio-xxx-windows.exe` (about 1 GB)

#### Step 2: Install Android Studio

1. Run the installer
2. Click "**Next**" → "**Next**" → "**Install**"
3. Wait for installation (10-15 minutes)
4. Click "**Finish**"

#### Step 3: Android Studio Setup Wizard

1. Android Studio opens → Click "**Next**"
2. Choose "**Standard**" installation → Click "**Next**"
3. Select a theme (Light/Dark) → Click "**Next**"
4. Click "**Finish**" to start downloading:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
   
   **This downloads 3-4 GB - be patient!**

#### Step 4: Accept Android Licenses

```powershell
flutter doctor --android-licenses
```

Press `y` for each license agreement (about 5-6 licenses)

**Expected output:**
```
All SDK package licenses accepted
```

#### Step 5: Verify Android Setup

```powershell
flutter doctor
```

**Expected output:**
```
[✓] Flutter
[✓] Android toolchain - develop for Android devices ← Should be green now!
[✓] Android Studio
```

---

## 📋 Part 3: Install VS Code (Recommended Editor)

### Windows:

#### Step 1: Download VS Code

1. Go to: https://code.visualstudio.com/
2. Click "**Download for Windows**"
3. Download `VSCodeUserSetup-x64-x.x.x.exe`

#### Step 2: Install VS Code

1. Run installer
2. Accept license
3. **Important:** Check these boxes:
   - ✅ Add "Open with Code" to context menu
   - ✅ Add to PATH
   - ✅ Register Code as an editor for supported file types
4. Click "**Install**"

#### Step 3: Install Flutter Extension

1. Open VS Code
2. Click Extensions icon (left sidebar) or press `Ctrl+Shift+X`
3. Search for "**Flutter**"
4. Click "**Install**" on "Flutter" extension by Dart Code
   - This also installs Dart extension automatically

#### Step 4: Verify VS Code Setup

```powershell
flutter doctor
```

**Expected output:**
```
[✓] VS Code (version x.x.x) ← Should be green now!
```

---

## 📋 Part 4: Create Android Emulator

### In Android Studio:

#### Step 1: Open Device Manager

1. Open Android Studio
2. Click "**More Actions**" → "**Virtual Device Manager**"
   - Or: Tools → Device Manager

#### Step 2: Create Virtual Device

1. Click "**Create Device**"
2. Choose a device (recommended: **Pixel 5**)
3. Click "**Next**"

#### Step 3: Download System Image

1. Select "**R**" (Android 11.0 - Recommended)
   - Or latest available version
2. Click "**Download**" next to system image (about 1 GB)
3. Wait for download → Click "**Finish**"
4. Click "**Next**"

#### Step 4: Finalize Creation

1. Keep default settings
2. Click "**Finish**"

#### Step 5: Start Emulator

1. In Device Manager, find your device
2. Click "**▶ Play**" button
3. Wait for emulator to boot (1-2 minutes first time)

✅ You now have a working Android emulator!

---

## 📋 Part 5: Setup Farm Buddy App

### Step 1: Navigate to Project

```powershell
cd D:\git\farm_buddy_app
```

### Step 2: Install Dependencies

```powershell
flutter pub get
```

**This installs:**
- http (API calls)
- provider (state management)
- intl (date formatting)
- shared_preferences (storage)

**Expected output:**
```
Running "flutter pub get" in farm_buddy_app...
Resolving dependencies...
+ async 2.11.0
+ http 1.1.0
+ provider 6.1.1
+ intl 0.18.1
...
Got dependencies!
```

### Step 3: Configure API URL

Open `lib/services/api_service.dart` in VS Code:

```dart
// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For physical device (use your computer's IP):
// static const String baseUrl = 'http://192.168.1.5:8000/api';
```

### Step 4: Start Django Backend

**In separate PowerShell terminal:**
```powershell
cd D:\git\FarmBuddy
python manage.py runserver 0.0.0.0:8000
```

### Step 5: Run Flutter App

```powershell
cd D:\git\farm_buddy_app
flutter run
```

**First build takes 5-10 minutes!**

---

## 📋 Part 6: Final Verification

Run complete check:

```powershell
flutter doctor -v
```

**Expected output (all green ✓):**
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio (version xxx)
[✓] VS Code (version xxx)
[✓] Connected device (2 available)
    • My Emulator (mobile) • emulator-5554 • android-x86
    • Chrome (web) • chrome • web-javascript
[✓] Network resources
```

---

## 🔧 Troubleshooting Installation

### Problem: "flutter: command not found"

**Solution 1:** Add to PATH (see Part 1, Step 3)

**Solution 2:** Restart computer after adding to PATH

**Solution 3:** Use full path temporarily:
```powershell
C:\src\flutter\bin\flutter doctor
```

### Problem: "Android licenses not accepted"

**Solution:**
```powershell
flutter doctor --android-licenses
```
Press `y` for all licenses

### Problem: "Unable to find bundled Java version"

**Solution:**
1. Open Android Studio
2. File → Settings → Appearance & Behavior → System Settings → Android SDK
3. Click "SDK Tools" tab
4. Check "Android SDK Command-line Tools"
5. Click "Apply" → "OK"

### Problem: Emulator won't start

**Solution 1:** Enable hardware acceleration
1. Go to BIOS/UEFI settings (restart PC, press F2/Del)
2. Enable "Virtualization" or "VT-x" or "AMD-V"
3. Save and restart

**Solution 2:** Use x86 image instead of ARM
- When creating emulator, choose x86 system image

### Problem: "Gradle build failed"

**Solution:**
```powershell
cd D:\git\farm_buddy_app\android
.\gradlew clean

cd ..
flutter clean
flutter pub get
flutter run
```

---

## 💾 Disk Space Requirements

Make sure you have enough free space:

| Component | Size |
|-----------|------|
| Flutter SDK | 2 GB |
| Android Studio | 2 GB |
| Android SDK & Tools | 4 GB |
| Emulator System Images | 2 GB each |
| VS Code | 500 MB |
| Project Dependencies | 500 MB |
| **Total** | **~12 GB** |

---

## 🌐 Alternative: Use Physical Device (Saves Disk Space)

### Android Phone:

1. **Enable Developer Options:**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Go back → You'll see "Developer Options"

2. **Enable USB Debugging:**
   - Developer Options → Enable "USB Debugging"

3. **Connect Phone:**
   - Connect via USB cable
   - Allow USB debugging when prompted on phone

4. **Verify:**
   ```powershell
   flutter devices
   ```
   Should show your phone

5. **Run App:**
   ```powershell
   flutter run
   ```

### iOS (Mac only):

1. Connect iPhone/iPad via USB
2. Trust computer on device
3. `flutter run`

---

## 📚 Additional Resources

### Official Documentation:
- **Flutter:** https://docs.flutter.dev/get-started/install
- **Android Studio:** https://developer.android.com/studio/install
- **VS Code:** https://code.visualstudio.com/docs

### Video Tutorials (YouTube):
- "Flutter Installation for Beginners" 
- "Android Studio Setup Guide"
- "Flutter Development Setup"

### Community Help:
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/flutter
- **Flutter Discord:** https://discord.gg/flutter
- **Reddit:** https://reddit.com/r/FlutterDev

---

## ✅ Installation Checklist

Before running the app, verify:

- [ ] Flutter SDK installed and in PATH
- [ ] `flutter --version` works
- [ ] `flutter doctor` shows all green ✓
- [ ] Android Studio installed
- [ ] Android licenses accepted
- [ ] VS Code installed with Flutter extension
- [ ] Android emulator created and boots
- [ ] `flutter pub get` completed successfully
- [ ] Django backend running on port 8000
- [ ] API URL configured correctly in api_service.dart

**If all checked ✅ → You're ready to run the app!**

---

## 🎓 For College Students

### College Computer Lab Setup:

If installing on college computers without admin rights:

1. **Portable Flutter:**
   - Extract Flutter to `D:\flutter\` or external drive
   - Add to PATH for current session only:
     ```powershell
     $env:Path += ";D:\flutter\bin"
     ```

2. **Use Web Version:**
   ```powershell
   flutter run -d chrome
   ```
   No emulator needed!

3. **Use Your Phone:**
   - Enable USB debugging
   - Connect phone
   - Run on physical device

### Low-End PC Tips:

- **Close other apps** while running emulator
- **Use x86 emulator** (faster than ARM)
- **Reduce emulator RAM** to 2048 MB instead of 4096 MB
- **Use physical device** instead of emulator

---

## 🆘 Still Need Help?

1. **Check error message** carefully
2. **Google the error** - usually first result has solution
3. **Run `flutter doctor -v`** for detailed diagnostics
4. **Check Flutter GitHub Issues:** https://github.com/flutter/flutter/issues
5. **Ask in class WhatsApp group**
6. **Show error to professor/TA**

---

**Installation complete! 🎉**

**Next:** Read `QUICKSTART.md` to run the app

---

*Created for: CSE(DS) Students | Tier 3 College, Maharashtra*  
*By: Satryam Patel | February 2026*
