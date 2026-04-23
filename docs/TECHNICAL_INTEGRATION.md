# AgroAssist - Technical Integration Guide

## System Architecture

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    Flutter Frontend App                      â”‚
â”‚  (iOS, Android, Web, Windows, macOS, Linux)                 â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â”‚ HTTP/HTTPS (REST API)
                       â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                  Django REST Backend                         â”‚
â”‚         (Crops, Tasks, Weather, Authentication)             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                       â”‚
                       â”‚ SQL / ORM
                       â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                   SQLite Database                           â”‚
â”‚         (Development) / PostgreSQL (Production)             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## API Communication Flow

### Example: Fetching Crops

```
1. User navigates to Crops Screen
   â””â”€> CropsScreen widget renders

2. Widget calls ApiService.getCrops()
   â”œâ”€> URL: http://localhost:8000/crops/
   â”œâ”€> Method: GET
   â”œâ”€> Headers:
   â”‚   â”œâ”€ Content-Type: application/json
   â”‚   â””â”€ Authorization: Bearer {token} (future)
   â””â”€> Params: page=1, page_size=20

3. Django receives request
   â”œâ”€> Route: crops/views.py â†’ crop_list()
   â”œâ”€> Database query: Crop.objects.all().paginate()
   â”œâ”€> Data serialization
   â””â”€> Response:
       {
         "success": true,
         "data": {
           "count": 5,
           "next": "http://...",
           "results": [...]
         }
       }

4. Flutter receives response
   â”œâ”€> Parse JSON
   â”œâ”€> Deserialize to Crop objects
   â”œâ”€> Update state with Provider
   â””â”€> Rebuild UI with updated crops
```

---

## Data Flow Diagram

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                      HOME SCREEN                             â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”           â”‚
â”‚  â”‚Dashboardâ”‚ â”‚ Actions â”‚ â”‚ Recent  â”‚ â”‚Activity â”‚           â”‚
â”‚  â”‚  Cards  â”‚ â”‚Buttons  â”‚ â”‚Activity â”‚ â”‚ Panel   â”‚           â”‚
â”‚  â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”˜           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â”‚           â”‚           â”‚           â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚   Provider State      â”‚
        â”‚  (ChangeNotifier)     â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚   API Service         â”‚
        â”‚  - getCrops()         â”‚
        â”‚  - getTasks()         â”‚
        â”‚  - getWeather()       â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚   HTTP Layer          â”‚
        â”‚  (http package)       â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚  Django REST API      â”‚
        â”‚  Port 8000            â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                    â”‚
        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚  Database             â”‚
        â”‚  SQLite / PostgreSQL  â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## Request/Response Examples

### 1. Get Crops

**Request:**
```http
GET /crops/?page=1&page_size=10 HTTP/1.1
Host: localhost:8000
Content-Type: application/json
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Crops retrieved successfully",
  "data": {
    "count": 15,
    "next": "http://localhost:8000/crops/?page=2",
    "previous": null,
    "results": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "name": "Wheat",
        "varietyType": "HD2967",
        "plantedArea": 5.5,
        "soilType": "Loamy",
        "soilPH": 7.2,
        "soilNitrogen": 15.5,
        "dateOfPlanting": "2024-01-15",
        "estimatedHarvestDate": "2024-06-15",
        "harvestArea": 5.3,
        "unitOfMeasurement": "acres",
        "diseasesPests": ["Rust", "Armyworm"],
        "pestControl": ["Fungicide spray", "Neem oil"],
        "createdAt": "2024-01-15T08:00:00Z",
        "updatedAt": "2024-01-20T10:30:00Z"
      }
    ]
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Failed to retrieve crops",
  "data": null,
  "errors": ["Database connection failed"]
}
```

---

### 2. Create Crop

**Request:**
```http
POST /crops/create HTTP/1.1
Host: localhost:8000
Content-Type: application/json

{
  "name": "Rice",
  "varietyType": "Basmati",
  "plantedArea": 3.2,
  "soilType": "Clay",
  "soilPH": 6.8,
  "soilNitrogen": 12.0,
  "dateOfPlanting": "2024-02-01",
  "estimatedHarvestDate": "2024-07-01",
  "harvestArea": 3.0,
  "unitOfMeasurement": "acres",
  "diseasesPests": ["Leaf Blast"],
  "pestControl": ["Triazole fungicide"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Crop created successfully",
  "data": {
    "id": "xyz789abc-def0-1234-5678-9abcdef01234",
    "name": "Rice",
    "varietyType": "Basmati",
    "plantedArea": 3.2,
    ...
  }
}
```

---

### 3. Get Tasks with Filters

**Request:**
```http
GET /tasks/?status=PENDING&priority=HIGH&page=1 HTTP/1.1
Host: localhost:8000
Content-Type: application/json
```

**Response:**
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "id": "task-001",
        "title": "Apply fertilizer to wheat field",
        "description": "Apply nitrogen-rich fertilizer",
        "dueDate": "2024-02-15",
        "status": "PENDING",
        "priority": "HIGH",
        "cropId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "createdAt": "2024-02-01T08:00:00Z"
      }
    ]
  }
}
```

---

## API Error Handling

### Error Response Format
```json
{
  "success": false,
  "message": "Descriptive error message",
  "data": null,
  "errors": [
    "Specific error details"
  ]
}
```

### HTTP Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | OK | Successful GET/POST |
| 201 | Created | New resource created |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid data format |
| 401 | Unauthorized | Missing/invalid auth token |
| 403 | Forbidden | No permission for resource |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Django exception |

---

## Authentication Flow (Future Implementation)

```
1. User registration
   POST /auth/register
   â”œâ”€ Request: {username, email, password}
   â””â”€ Response: {token, user_id}

2. User login
   POST /auth/login
   â”œâ”€ Request: {username, password}
   â”œâ”€ Response: {token, expires_in}
   â””â”€ Store token in SharedPreferences

3. Authenticated requests
   GET /crops/
   â”œâ”€ Header: Authorization: Bearer {token}
   â”œâ”€ Validate token in Django middleware
   â””â”€ Return user-specific data

4. Token refresh
   POST /auth/refresh
   â”œâ”€ Request: {refresh_token}
   â””â”€ Response: {new_token}

5. User logout
   POST /auth/logout
   â”œâ”€ Invalidate token
   â””â”€ Clear local storage
```

---

## State Management Pattern

### Provider Setup

**File**: `agro_assist_app/lib/main.dart`
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CropProvider()),
    ChangeNotifierProvider(create: (_) => TaskProvider()),
    ChangeNotifierProvider(create: (_) => WeatherProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: MyApp(),
)
```

### Provider Patterns Used

**1. ChangeNotifier + Consumer (for simple state)**
```dart
class CropProvider extends ChangeNotifier {
  List<Crop> _crops = [];
  
  get crops => _crops;
  
  Future<void> fetchCrops() async {
    _crops = await ApiService().getCrops();
    notifyListeners();
  }
}

// Usage in Widget
Consumer<CropProvider>(
  builder: (context, provider, _) {
    return ListView(children: provider.crops.map(...).toList());
  }
)
```

**2. Context-based access (for complex operations)**
```dart
context.read<CropProvider>().addCrop(newCrop);
```

**3. Listening to changes**
```dart
context.watch<CropProvider>().crops; // Rebuilds on change
```

---

## Database Schema

### Crops Table
```sql
CREATE TABLE crops (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  variety_type VARCHAR(100),
  planted_area FLOAT,
  soil_type VARCHAR(50),
  soil_ph FLOAT,
  soil_nitrogen FLOAT,
  date_of_planting DATE,
  estimated_harvest_date DATE,
  harvest_area FLOAT,
  unit_of_measurement VARCHAR(20),
  diseases_pests JSON,
  pest_control JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Tasks Table
```sql
CREATE TABLE tasks (
  id VARCHAR(36) PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  due_date DATE,
  status VARCHAR(20), -- PENDING, IN_PROGRESS, COMPLETED
  priority VARCHAR(20), -- LOW, MEDIUM, HIGH
  crop_id VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (crop_id) REFERENCES crops(id)
);
```

---

## Debugging Guide

### 1. Check API Requests
**In ApiService:**
```dart
print('Request: ${response.request.method} ${response.request.url}');
print('Response Status: ${response.statusCode}');
print('Response Body: ${response.body}');
```

### 2. Monitor State Changes
**With Provider DevTools:**
```bash
flutter pub add provider_devtools
```

### 3. Django Debug Mode
Ensure `DEBUG = True` in `settings.py` for detailed error pages.

### 4. Check Network Traffic
Use Chrome DevTools:
1. Run app with `flutter run -d chrome`
2. Open Chrome DevTools (F12)
3. Go to Network tab
4. Monitor HTTP requests/responses

### 5. Database Inspection
```bash
python manage.py dbshell
SELECT * FROM crops_crop;
SELECT * FROM tasks_task;
```

---

## Performance Optimization

### Frontend
- Lazy loading for long lists
- Provider selector to prevent unnecessary rebuilds
- Image caching with `cached_network_image`
- Pagination for large datasets

### Backend
- Database indexing on frequently queried fields
- Pagination limits (default 20 items)
- Query optimization with select_related/prefetch_related
- Response caching for static data

---

## Security Considerations

### Current (Development)
- All endpoints public (no authentication required)
- CORS enabled for localhost

### Future (Production)
- JWT authentication on all endpoints
- HTTPS only
- CSRF token validation
- Rate limiting
- Input validation and sanitization
- SQL injection prevention (Django ORM already handles)

---

## Deployment Checklist

- [ ] Set `DEBUG = False` in Django settings
- [ ] Configure `ALLOWED_HOSTS` with production domain
- [ ] Set secure cookie flags
- [ ] Configure static files serving
- [ ] Set up database backups
- [ ] Configure email for notifications
- [ ] Enable HTTPS/SSL
- [ ] Set up monitoring and logging
- [ ] Create superuser for admin access
- [ ] Test all API endpoints in production

---

## Common Integration Issues

### Issue 1: CORS Error
**Error**: No 'Access-Control-Allow-Origin' header
**Solution**: Check CORS settings in Django settings.py

### Issue 2: 404 on API Call
**Error**: GET /crops/ returns 404
**Solution**: Check URL configuration in urls.py

### Issue 3: JSON Decode Error
**Error**: FormatException: Invalid JSON
**Solution**: Print response body, check API returns valid JSON

### Issue 4: State not updating
**Error**: UI doesn't reflect data changes
**Solution**: Ensure notifyListeners() is called after data update

### Issue 5: Timeout on large requests
**Error**: SocketException: Failed host lookup
**Solution**: Increase request timeout in ApiService

---

## Future API Improvements

- [ ] GraphQL support
- [ ] WebSocket for real-time updates
- [ ] Batch operations endpoint
- [ ] File upload for crop images
- [ ] Advanced search with Elasticsearch
- [ ] API versioning (v1, v2)
- [ ] Rate limiting per user
- [ ] API documentation (Swagger/OpenAPI)

---

This document serves as the technical foundation for understanding and extending the AgroAssist integrated system.

