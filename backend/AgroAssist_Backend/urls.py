"""
URL configuration for AgroAssist_Backend project.
Routes all API endpoints and admin interface.
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter  # Router for automatic URL generation

# Import ALL ViewSets from each app
from AgroAssist_Backend.crops.views import (CropViewSet, CropGuideViewSet, 
                                           CropGrowthStageViewSet, CropCareTaskViewSet, 
                                           CropRecommendationViewSet)
from AgroAssist_Backend.farmers.views import FarmerViewSet, FarmerCropViewSet, FarmerInventoryViewSet
from AgroAssist_Backend.weather.views import WeatherDataViewSet, FarmersWeatherAlertViewSet, WeatherForecastViewSet
from AgroAssist_Backend.tasks.views import FarmerTaskViewSet, TaskReminderViewSet, TaskLogViewSet
from AgroAssist_Backend.api.views import dashboard_stats

# CREATE ROUTER - Automatically generates URLs for viewsets
router = DefaultRouter()

# REGISTER CROP APP VIEWSETS - These create URLs like /api/crops/, /api/crops/1/, etc.
router.register(r'crops', CropViewSet, basename='crops')  # /api/crops/ for all crops
router.register(r'crop-guides', CropGuideViewSet, basename='crop-guides')  # /api/crop-guides/
router.register(r'growth-stages', CropGrowthStageViewSet, basename='growth-stages')  # /api/growth-stages/
router.register(r'care-tasks', CropCareTaskViewSet, basename='care-tasks')  # /api/care-tasks/
router.register(r'recommendations', CropRecommendationViewSet, basename='recommendations')  # /api/recommendations/

# REGISTER FARMERS APP VIEWSETS
router.register(r'farmers', FarmerViewSet, basename='farmers')  # /api/farmers/ for farmers
router.register(r'farmer-crops', FarmerCropViewSet, basename='farmer-crops')  # /api/farmer-crops/
router.register(r'inventory', FarmerInventoryViewSet, basename='inventory')  # /api/inventory/

# REGISTER WEATHER APP VIEWSETS
router.register(r'weather-data', WeatherDataViewSet, basename='weather-data')  # /api/weather-data/
router.register(r'weather-alerts', FarmersWeatherAlertViewSet, basename='weather-alerts')  # /api/weather-alerts/
router.register(r'weather', FarmersWeatherAlertViewSet, basename='weather')  # /api/weather/
router.register(r'weather-forecast', WeatherForecastViewSet, basename='weather-forecast')  # /api/weather-forecast/

# REGISTER TASKS APP VIEWSETS
router.register(r'tasks', FarmerTaskViewSet, basename='tasks')  # /api/tasks/
router.register(r'task-reminders', TaskReminderViewSet, basename='task-reminders')  # /api/task-reminders/
router.register(r'task-logs', TaskLogViewSet, basename='task-logs')  # /api/task-logs/

# URL PATTERNS - Connect routes to views
urlpatterns = [
    # Admin interface - /admin/
    path('admin/', admin.site.urls),
    path('api/auth/', include('AgroAssist_Backend.farmers.auth_urls')),
    
    # API ROUTES - All REST API endpoints go under /api/
    # include(router.urls) automatically adds:
    # - /api/crops/ (GET=list, POST=create)
    # - /api/crops/{id}/ (GET=detail, PUT=update, PATCH=partial_update, DELETE=delete)
    # - /api/crops/{id}/by_season/ (custom action)
    # - /api/crops/{id}/recommendations/ (custom action)
    # And same for all other registered viewsets
    path('api/dashboard/stats/', dashboard_stats),
    path('api/', include(router.urls)),]
