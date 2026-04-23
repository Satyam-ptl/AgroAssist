# Farm Buddy - Flutter + Django Integration Guide

## ðŸ“‹ Project Overview

**Farm Buddy** is a complete Full Stack application with:
- **Backend**: Django 6.0.2 + Django REST Framework (Python)
- **Frontend**: Flutter (Dart) - Mobile App
- **Database**: SQLite3 (can switch to MySQL)
- **API**: RESTful API with JSON responses

## ðŸ—ï¸ Architecture

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                  Flutter Mobile App                  â”‚
â”‚  (Android/iOS - lib/screens, lib/models, etc.)      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
                    â”‚ HTTP Requests (JSON)
                    â”‚ GET, POST, PUT, PATCH, DELETE
                    â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚              Django REST API Backend                 â”‚
â”‚         (ViewSets, Serializers, Models)             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
                    â”‚ ORM Queries
                    â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                  SQLite Database                     â”‚
â”‚     (Crops, Farmers, Tasks, Weather tables)         â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

## ðŸ”Œ How They Connect

### 1. Django Backend Setup

**Location**: `D:\git\AgroAssist\`

**Key Configuration Changes Made:**

**File**: `AgroAssist_Backend/settings.py`
```python
# CORS middleware added to allow Flutter app connections
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Added this line
    # ... other middleware
]

# Allow all origins during development
CORS_ALLOW_ALL_ORIGINS = True  # Flutter can connect from any IP

# Allow all HTTP methods
CORS_ALLOW_METHODS = ['DELETE', 'GET', 'OPTIONS', 'PATCH', 'POST', 'PUT']

# REST Framework configuration
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',  # No authentication required
    ],
}
```

**What this does:**
- CORS (Cross-Origin Resource Sharing) allows Flutter app to make API requests
- Without CORS, browser/mobile apps would be blocked by security policies
- `AllowAny` permission means no login required (change in production)

### 2. Flutter App Setup

**Location**: `D:\git\AgroAssist\agro_assist_app\`

**API Service Configuration:**

**File**: `lib/services/api_service.dart`
```dart
class ApiService {
  // Base URL pointing to Django backend
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // 10.0.2.2 is Android emulator's way to access localhost
  // For iOS simulator: use 'http://localhost:8000/api'
  // For real device: use 'http://YOUR_COMPUTER_IP:8000/api'
}
```

**How API calls work:**

```dart
// Example: Getting crops from Django API
Future<Map<String, dynamic>> getCrops({String? season}) async {
  // 1. Build URL with query parameters
  String url = '$baseUrl/crops/?page_size=20';
  if (season != null) {
    url += '&season=$season';
  }
  
  // 2. Make HTTP GET request
  final response = await http.get(Uri.parse(url), headers: headers);
  
  // 3. Parse JSON response
  if (response.statusCode == 200) {
    return json.decode(response.body);  // Convert JSON string to Dart Map
  } else {
    throw Exception('Failed to load crops');
  }
}
```

## ðŸŒ API Endpoints Used by Flutter

### Crops Endpoints

| Flutter Method | Django Endpoint | Purpose |
|----------------|-----------------|---------|
| `ApiService.getCrops()` | `GET /api/crops/` | Get all crops with optional filtering |
| `ApiService.getCropDetail(id)` | `GET /api/crops/{id}/` | Get specific crop details |
| `ApiService.getCropRecommendations(season)` | `GET /api/crops/recommendations/?season=X` | Get crop recommendations |

### Farmers Endpoints

| Flutter Method | Django Endpoint | Purpose |
|----------------|-----------------|---------|
| `ApiService.getFarmers()` | `GET /api/farmers/` | Get all farmers |
| `ApiService.getFarmerDetail(id)` | `GET /api/farmers/{id}/` | Get farmer profile |
| `ApiService.createFarmer(data)` | `POST /api/farmers/` | Register new farmer |
| `ApiService.updateFarmer(id, data)` | `PUT /api/farmers/{id}/` | Update farmer info |

### Tasks Endpoints

| Flutter Method | Django Endpoint | Purpose |
|----------------|-----------------|---------|
| `ApiService.getTasks()` | `GET /api/tasks/` | Get all tasks |
| `ApiService.createTask(data)` | `POST /api/tasks/` | Create new task |
| `ApiService.updateTaskStatus(id, status)` | `PATCH /api/tasks/{id}/` | Update task status |

### Weather Endpoints

| Flutter Method | Django Endpoint | Purpose |
|----------------|-----------------|---------|
| `ApiService.getWeatherData(location)` | `GET /api/weather-data/?location=X` | Get weather data |
| `ApiService.getWeatherAlerts(farmerId)` | `GET /api/weather-alerts/?farmer=X` | Get alerts for farmer |

## ðŸ“± Flutter Screens â†’ Django APIs

### Home Screen (Dashboard)
**File**: `lib/screens/home_screen.dart`

```dart
loadDashboardData() async {
  // Calls multiple Django APIs in parallel
  final cropsResponse = await ApiService.getCrops(pageSize: 1);
  final farmersResponse = await ApiService.getFarmers(pageSize: 1);
  final tasksResponse = await ApiService.getTasks(status: 'Pending', pageSize: 1);
  
  // Display counts on dashboard
  totalCrops = cropsResponse['count'];
  totalFarmers = farmersResponse['count'];
  pendingTasks = tasksResponse['count'];
}
```

**Django APIs called:**
- `/api/crops/?page_size=1` â†’ Returns `{count: 50, results: [...]}`
- `/api/farmers/?page_size=1` â†’ Returns `{count: 25, results: [...]}`
- `/api/tasks/?status=Pending&page_size=1` â†’ Returns `{count: 10, results: [...]}`

### Crops Screen
**File**: `lib/screens/crops_screen.dart`

```dart
loadCrops() async {
  // Get crops filtered by season
  final response = await ApiService.getCrops(
    season: selectedSeason == 'All' ? null : selectedSeason,
    pageSize: 100,
  );
  
  // Convert JSON to Dart objects
  final List<dynamic> cropsJson = response['results'];
  final List<Crop> loadedCrops = cropsJson
      .map((json) => Crop.fromJson(json))  // Use model's fromJson factory
      .toList();
      
  // Display in UI
  setState(() {
    crops = loadedCrops;
  });
}
```

**Django API response example:**
```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Rice",
      "season": "Kharif",
      "soil_type": "Loamy",
      "growth_duration_days": 120,
      "optimal_temperature_min": 20.0,
      "optimal_temperature_max": 35.0,
      ...
    },
    ...
  ]
}
```

### Tasks Screen - Updating Status
**File**: `lib/screens/tasks_screen.dart`

```dart
// Mark task as completed
await ApiService.updateTaskStatus(task.id, 'Completed');

// Inside api_service.dart:
Future<Map<String, dynamic>> updateTaskStatus(int taskId, String status) async {
  final response = await http.patch(
    Uri.parse('$baseUrl/tasks/$taskId/'),
    headers: headers,
    body: json.encode({'status': status}),  // Send JSON: {"status": "Completed"}
  );
  return json.decode(response.body);
}
```

**Django processes this:**
1. Receives PATCH request at `/api/tasks/5/`
2. DRF deserializes JSON: `{"status": "Completed"}`
3. TaskSerializer validates the data
4. Updates database: `FarmerTask.objects.filter(id=5).update(status='Completed')`
5. Returns updated task as JSON response

## ðŸ”„ Data Flow Example

Let's trace a complete flow: **Creating a new farmer**

### Step 1: User fills form in Flutter app

```dart
// User enters data in a form
Map<String, dynamic> farmerData = {
  'first_name': 'Ramesh',
  'last_name': 'Patil',
  'email': 'ramesh@example.com',
  'phone_number': '9876543210',
  'city': 'Pune',
  'state': 'Maharashtra',
  'land_area_hectares': 5.0,
  'soil_type': 'Loamy',
  'experience_level': 'Intermediate',
  'preferred_language': 'Marathi',
  'contact_method': 'WhatsApp',
};
```

### Step 2: Flutter sends to Django

```dart
// api_service.dart
Future<Map<String, dynamic>> createFarmer(Map<String, dynamic> farmerData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/farmers/'),  // POST to /api/farmers/
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: json.encode(farmerData),  // Convert Map to JSON string
  );
  
  if (response.statusCode == 201) {  // 201 = Created
    return json.decode(response.body);
  }
}
```

**HTTP Request sent:**
```http
POST http://10.0.2.2:8000/api/farmers/
Content-Type: application/json

{
  "first_name": "Ramesh",
  "last_name": "Patil",
  "email": "ramesh@example.com",
  ...
}
```

### Step 3: Django receives and processes

**In Django:**

1. **URL Router** (`urls.py`): Routes to `FarmerViewSet.create()`
2. **Serializer** (`farmers/serializers.py`):
   ```python
   class CreateFarmerSerializer(serializers.ModelSerializer):
       def validate_email(self, value):
           if Farmer.objects.filter(email=value).exists():
               raise ValidationError("Email already exists")
           return value
   ```
3. **ViewSet** (`farmers/views.py`):
   ```python
   class FarmerViewSet(viewsets.ModelViewSet):
       def create(self, request):
           serializer = CreateFarmerSerializer(data=request.data)
           if serializer.is_valid():
               farmer = serializer.save()  # Saves to database
               return Response(serializer.data, status=201)
   ```
4. **Model** (`farmers/models.py`): Saves to database
5. **Response** sent back to Flutter as JSON

**HTTP Response:**
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": 26,
  "first_name": "Ramesh",
  "last_name": "Patil",
  "email": "ramesh@example.com",
  "phone_number": "9876543210",
  "created_at": "2026-02-22T12:30:45Z",
  ...
}
```

### Step 4: Flutter receives and updates UI

```dart
try {
  final newFarmer = await ApiService.createFarmer(farmerData);
  
  // Success! Show message to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Farmer ${newFarmer['first_name']} registered!')),
  );
  
  // Navigate back to farmers list
  Navigator.pop(context);
  
} catch (e) {
  // Error! Show error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

## ðŸš€ Running Both Together

### Terminal 1: Start Django Backend

```powershell
cd D:\git\AgroAssist
python manage.py runserver 0.0.0.0:8000
```

**Output:**
```
Django version 6.0.2, using settings 'AgroAssist_Backend.settings'
Starting development server at http://0.0.0.0:8000/
Quit the server with CTRL-BREAK.
```

**Note:** `0.0.0.0:8000` makes Django accessible from:
- Your computer: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`
- Physical device: `http://YOUR_IP:8000`

### Terminal 2: Start Flutter App

```powershell
cd D:\git\AgroAssist\agro_assist_app
flutter run
```

**Output:**
```
Launching lib\main.dart on Android SDK built for x86 in debug mode...
Running Gradle task 'assembleDebug'...
âœ“ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing build\app\outputs\flutter-apk\app.apk...
Syncing files to device Android SDK built for x86...
```

### Verify Connection

**In Django terminal, you'll see:**
```
[22/Feb/2026 12:35:10] "GET /api/crops/?page_size=5 HTTP/1.1" 200 1234
[22/Feb/2026 12:35:11] "GET /api/farmers/?page_size=5 HTTP/1.1" 200 987
[22/Feb/2026 12:35:12] "GET /api/tasks/?status=Pending&page_size=5 HTTP/1.1" 200 456
```

This shows Flutter app successfully making API requests!

## ðŸ”’ Security Considerations

### Current Setup (Development)

```python
# settings.py
DEBUG = True  âš ï¸ Shows detailed errors
CORS_ALLOW_ALL_ORIGINS = True  âš ï¸ Anyone can access API
ALLOWED_HOSTS = []  âš ï¸ Only localhost
DEFAULT_PERMISSION_CLASSES = ['rest_framework.permissions.AllowAny']  âš ï¸ No login
```

### Production Setup (TODO)

```python
# settings.py for production
DEBUG = False  âœ… Hide error details
CORS_ALLOWED_ORIGINS = [
    'https://your-app.com',  âœ… Only specific domains
]
ALLOWED_HOSTS = ['your-domain.com']  âœ… Only your domain
DEFAULT_PERMISSION_CLASSES = [
    'rest_framework.permissions.IsAuthenticated',  âœ… Login required
]

# Add token authentication
DEFAULT_AUTHENTICATION_CLASSES = [
    'rest_framework.authentication.TokenAuthentication',
]
```

**Also add:**
- HTTPS/SSL certificates
- API rate limiting
- Input validation
- SQL injection protection (Django ORM handles this)
- JWT tokens for mobile apps

## ðŸ“Š Models Schema Mapping

### Django Model â†’ Flutter Model

**Django** (`farmers/models.py`):
```python
class Farmer(models.Model):
    first_name = models.CharField(max_length=100)
    land_area_hectares = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
```

**Flutter** (`lib/models/farmer_model.dart`):
```dart
class Farmer {
  final String firstName;  // Maps to first_name (snake_case â†’ camelCase)
  final double landAreaHectares;  // DecimalField â†’ double
  final DateTime createdAt;  // DateTimeField â†’ DateTime
  
  // Convert JSON from Django to Flutter object
  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      firstName: json['first_name'],  // Convert snake_case
      landAreaHectares: json['land_area_hectares'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),  // Parse ISO string
    );
  }
  
  // Convert Flutter object to JSON for Django
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,  // Convert back to snake_case
      'land_area_hectares': landAreaHectares,
      // created_at is auto-generated by Django, don't send it
    };
  }
}
```

## ðŸ§ª Testing the Integration

### Test 1: Check Django API in Browser

Open: `http://localhost:8000/api/crops/`

**Expected:** JSON response with crops data

### Test 2: Check from Android Emulator perspective

Open: `http://10.0.2.2:8000/api/crops/`

**Expected:** Same JSON response

### Test 3: Flutter API call test

Add to any Flutter screen:
```dart
@override
void initState() {
  super.initState();
  testConnection();
}

Future<void> testConnection() async {
  try {
    final response = await ApiService.getCrops(pageSize: 1);
    print('âœ… Connected to Django! Count: ${response['count']}');
  } catch (e) {
    print('âŒ Connection failed: $e');
  }
}
```

**Check Flutter console for output.**

## ðŸ“± Device-Specific Configuration

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```
**Why:** Android emulator's special IP to access host machine's localhost

### iOS Simulator
```dart
static const String baseUrl = 'http://localhost:8000/api';
```
**Why:** iOS simulator shares network with host machine

### Physical Android Device (WiFi)
```dart
static const String baseUrl = 'http://192.168.1.5:8000/api';
```
**Why:** Use your computer's actual IP address on local network

**Find your IP:**
```powershell
ipconfig  # Windows
```
Look for "IPv4 Address" under your WiFi adapter (e.g., 192.168.1.5)

### Physical iOS Device (WiFi)
Same as Android - use your computer's IP address

## ðŸ“¦ Required Packages

### Django Backend
```bash
pip install django==6.0.2
pip install djangorestframework
pip install django-cors-headers
pip install mysqlclient  # Optional, for MySQL
pip install pillow  # For image handling
```

### Flutter Frontend
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0  # HTTP client
  provider: ^6.1.1  # State management
  intl: ^0.18.1  # Date formatting
  shared_preferences: ^2.2.2  # Local storage
```

Install with:
```bash
flutter pub get
```

## ðŸŽ“ Learning Path

For students learning this integration:

1. **Understand REST APIs**
   - HTTP methods: GET, POST, PUT, PATCH, DELETE
   - Status codes: 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found)
   - JSON format

2. **Django Side**
   - Models define database structure
   - Serializers convert models â†” JSON
   - ViewSets handle API logic
   - URLconf routes requests

3. **Flutter Side**
   - Models represent data structure
   - API Service makes HTTP requests
   - Screens display data
   - State management updates UI

4. **Data Flow**
   - User action â†’ API call â†’ HTTP request â†’ Django processes â†’ Database update â†’ JSON response â†’ Flutter updates UI

## ðŸ› ï¸ Troubleshooting

### Problem: "Connection refused"
**Solution:** Check Django is running on `0.0.0.0:8000`, not `127.0.0.1:8000`

### Problem: "CORS error"
**Solution:** Verify `corsheaders` in INSTALLED_APPS and MIDDLEWARE

### Problem: "404 Not Found"
**Solution:** Check URL in api_service.dart matches Django urls.py

### Problem: "JSON decode error"
**Solution:** Django might be returning HTML error page, check Django logs

---

**ðŸ“š This integration demonstrates:**
- âœ… Full Stack development (Backend + Mobile Frontend)
- âœ… RESTful API design
- âœ… Cross-platform mobile development
- âœ… CRUD operations over HTTP
- âœ… JSON serialization/deserialization
- âœ… State management in Flutter
- âœ… Django ORM and database design

**Happy Learning! ðŸš€**

