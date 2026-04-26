# Import Django model classes for database  
from django.db import models

# Import Farmer model to link weather alerts to specific farmers
from AgroAssist_Backend.farmers.models import Farmer

# MODEL 1: WeatherData - Current weather information for a location
class WeatherData(models.Model):
    # CharField = Location name (city, region, etc.)
    location = models.CharField(max_length=100)  # Place name (e.g., "Pune", "Nashik", "Kolhapur")
    
    # FloatField = Temperature in Celsius
    temperature = models.FloatField()  # Current temperature (e.g., 28.5 degrees Celsius)
    
    # IntegerField = Humidity percentage (0-100%)
    humidity = models.IntegerField()  # Air moisture level (e.g., 65% humidity)
    
    # IntegerField = Rainfall in millimeters
    rainfall = models.IntegerField()  # How much rain (e.g., 12 mm fallen)
    
    # CharField with choices = Weather condition description
    CONDITION_CHOICES = [
        ('Sunny', 'Sunny'),  # Clear sky, no clouds
        ('Cloudy', 'Cloudy'),  # Some clouds
        ('Rainy', 'Rainy'),  # Rain falling
        ('Stormy', 'Stormy'),  # Heavy rain and wind
        ('Partly Cloudy', 'Partly Cloudy'),  # Mix of cloud and sun
    ]
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES)  # Current weather condition
    
    # FloatField = Wind speed in km/h
    wind_speed = models.FloatField(default=0)  # Wind speed (e.g., 15 km/h)
    
    # DateTimeField = When this weather data was recorded
    recorded_at = models.DateTimeField()  # When weather was measured
    
    # DateTimeField = Auto-set when record created in database
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Meta class = Configuration for WeatherData model
    class Meta:
        verbose_name = "Weather Data"  # Display name (singular)
        verbose_name_plural = "Weather Data"  # Display name (plural)
        ordering = ['-recorded_at']  # Show most recent weather first
    
    def __str__(self):
        # Shows "Pune - Sunny - 28.5Â°C" when displaying
        return f"{self.location} - {self.condition} - {self.temperature}Â°C"


# MODEL 2: FarmersWeatherAlert - Alerts sent to farmers about dangerous weather
class FarmersWeatherAlert(models.Model):
    # ForeignKey = Link to Farmer model (each alert goes to specific farmer)
    # on_delete=models.CASCADE = Delete alert if farmer account deleted
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='weather_alerts')  # Which farmer
    
    # CharField = Alert title/subject
    alert_title = models.CharField(max_length=200)  # Title (e.g., "Heavy Rain Warning")

    region = models.CharField(max_length=120, blank=True, default='')
    
    # TextField = Detailed alert message
    alert_message = models.TextField()  # Details about the alert (e.g., "Rain expected for 3 days")
    
    # CharField with choices = Alert severity level
    SEVERITY_CHOICES = [
        ('Low', 'Low - Minor'),  # Minimal impact expected
        ('Medium', 'Medium - Moderate'),  # Some farmer action needed
        ('High', 'High - Serious'),  # Farmer should take action immediately
        ('Critical', 'Critical - Severe'),  # Immediate action required
    ]
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)  # How serious is the alert
    
    # CharField with choices = Alert type/category
    ALERT_TYPE_CHOICES = [
        ('Rain', 'Heavy Rain'),  # Too much rain
        ('Frost', 'Frost/Cold'),  # Too cold
        ('Heat', 'Extreme Heat'),  # Too hot
        ('Wind', 'Strong Wind'),  # High wind
        ('Disease', 'Disease Risk'),  # Disease outbreak risk
        ('Pest', 'Pest Alert'),  # Pest outbreak warning
    ]
    alert_type = models.CharField(max_length=20, choices=ALERT_TYPE_CHOICES)  # Type of alert
    
    # DateTimeField = When the alert was issued
    issued_at = models.DateTimeField()  # When alert was created
    
    # DateTimeField = When the dangerous condition ends
    expires_at = models.DateTimeField(blank=True, null=True)  # When alert is no longer valid

    is_active = models.BooleanField(default=True)
    
    # BooleanField = Whether farmer has read this alert
    is_read = models.BooleanField(default=False)  # Has farmer seen this alert? (True = yes, False = no)
    
    # BooleanField = Whether farmer took action on this alert
    action_taken = models.BooleanField(default=False)  # Did farmer do something about it?
    
    # TextField = What action farmer took (optional)
    farmer_notes = models.TextField(blank=True)  # Farmer's notes about what they did
    
    # DateTimeField = Auto-set when record created
    created_at = models.DateTimeField(auto_now_add=True)
    
    # DateTimeField = Auto-update when record modified
    updated_at = models.DateTimeField(auto_now=True)
    
    # Meta class = Configuration for FarmersWeatherAlert model
    class Meta:
        verbose_name = "Weather Alert"  # Display name (singular)
        verbose_name_plural = "Weather Alerts"  # Display name (plural)
        ordering = ['-issued_at']  # Show most recent alerts first
    
    def __str__(self):
        # Shows "Heavy Rain Warning - Rajesh Patil (High)" when displaying
        return f"{self.alert_title} - {self.farmer.first_name} ({self.severity})"


# MODEL 3: WeatherForecast - Predicted weather for next few days
class WeatherForecast(models.Model):
    # CharField = Location name (which area this forecast is for)
    location = models.CharField(max_length=100)  # Area this forecast covers (e.g., "Pune District")
    
    # DateField = Date this forecast is for
    forecast_date = models.DateField()  # Which day is this forecast predicting (e.g., tomorrow)
    
    # FloatField = Predicted minimum temperature
    min_temperature = models.FloatField()  # Lowest temp expected (e.g., 18 degrees)
    
    # FloatField = Predicted maximum temperature
    max_temperature = models.FloatField()  # Highest temp expected (e.g., 35 degrees)
    
    # IntegerField = Chance of rain (percentage 0-100%)
    rainfall_probability = models.IntegerField()  # % chance of rain (e.g., 70%)
    
    # IntegerField = Expected rainfall amount in mm
    expected_rainfall_mm = models.IntegerField(default=0)  # How much rain if it rains (e.g., 25 mm)
    
    # IntegerField = Expected humidity percentage
    humidity = models.IntegerField()  # Air moisture level (e.g., 60%)
    
    # CharField with choices = Predicted weather condition
    CONDITION_CHOICES = [
        ('Sunny', 'Sunny'),  # Clear day predicted
        ('Cloudy', 'Cloudy'),  # Cloudy day predicted
        ('Rainy', 'Rainy'),  # Rain predicted
        ('Stormy', 'Stormy'),  # Severe weather predicted
        ('Partly Cloudy', 'Partly Cloudy'),  # Mix predicted
    ]
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES)  # Weather prediction
    
    # FloatField = Predicted wind speed
    wind_speed = models.FloatField(default=0)  # Expected wind (e.g., 15 km/h)
    
    # DateTimeField = When this forecast was made
    forecast_issued_at = models.DateTimeField()  # When meteorologist made this forecast
    
    # DateTimeField = Auto-set when record created in database
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Meta class = Configuration for WeatherForecast model
    class Meta:
        verbose_name = "Weather Forecast"  # Display name (singular)
        verbose_name_plural = "Weather Forecasts"  # Display name (plural)
        ordering = ['forecast_date']  # Show forecasts in chronological order
        # unique_together = Can't have two forecasts for same location/date
        unique_together = ('location', 'forecast_date')  # One forecast per location per day only
    
    def __str__(self):
        # Shows "Pune - 2025-02-25 - Rainy (18-30Â°C)" when displaying
        return f"{self.location} - {self.forecast_date} - {self.condition} ({self.min_temperature}-{self.max_temperature}Â°C)"

