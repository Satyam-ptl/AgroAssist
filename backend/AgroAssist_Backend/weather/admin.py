from django.contrib import admin
from .models import WeatherData, FarmersWeatherAlert, WeatherForecast

# Register WeatherData model - Current weather
@admin.register(WeatherData)
class WeatherDataAdmin(admin.ModelAdmin):
    list_display = ['location', 'condition', 'temperature', 'recorded_at']  # Show current weather
    list_filter = ['condition', 'location', 'recorded_at']  # Filters
    search_fields = ['location']  # Search by location
    readonly_fields = ['created_at']  # Can't edit

# Register FarmersWeatherAlert model - Weather warnings
@admin.register(FarmersWeatherAlert)
class FarmersWeatherAlertAdmin(admin.ModelAdmin):
    list_display = ['farmer', 'alert_type', 'severity', 'issued_at']  # Show alerts
    list_filter = ['severity', 'alert_type', 'is_read']  # Filters
    search_fields = ['farmer__first_name', 'alert_title']  # Search
    readonly_fields = ['issued_at', 'created_at', 'updated_at']  # Can't edit

# Register WeatherForecast model - Weather predictions
@admin.register(WeatherForecast)
class WeatherForecastAdmin(admin.ModelAdmin):
    list_display = ['location', 'forecast_date', 'condition', 'rainfall_probability']  # Show forecast
    list_filter = ['location', 'forecast_date', 'condition']  # Filters
    search_fields = ['location']  # Search by location
    readonly_fields = ['created_at']  # Can't edit
