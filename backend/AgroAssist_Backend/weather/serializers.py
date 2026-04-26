# Import serializer classes from Django REST Framework
from rest_framework import serializers
from django.utils import timezone

# Import models to serialize
from .models import WeatherData, FarmersWeatherAlert, WeatherForecast


class WeatherAlertValidationMixin:
    def validate_severity(self, value):
        valid_values = {choice[0] for choice in FarmersWeatherAlert.SEVERITY_CHOICES}
        if value not in valid_values:
            raise serializers.ValidationError("Select a valid alert severity level.")
        return value

    def create(self, validated_data):
        validated_data.setdefault('issued_at', timezone.now())
        return super().create(validated_data)


# SERIALIZER 1: WeatherDataSerializer - Convert current weather to/from JSON
class WeatherDataSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields
    formatted_recorded_at = serializers.SerializerMethodField()  # Format date nicely
    
    class Meta:
        model = WeatherData
        fields = ['id', 'location', 'temperature', 'humidity', 'rainfall', 'condition',
                  'wind_speed', 'recorded_at', 'formatted_recorded_at', 'created_at']
        
        read_only_fields = ['created_at', 'recorded_at', 'formatted_recorded_at']  # Can't edit
    
    def get_formatted_recorded_at(self, obj):
        # Format the recorded_at datetime nicely for display
        return obj.recorded_at.strftime('%Y-%m-%d %H:%M')  # Format: "2025-02-22 14:30"


# SERIALIZER 2: FarmersWeatherAlertSerializer - Convert weather alerts to/from JSON
class FarmersWeatherAlertSerializer(WeatherAlertValidationMixin, serializers.ModelSerializer):
    # SerializerMethodField = Custom fields
    farmer_name = serializers.SerializerMethodField()  # Show farmer name
    is_active = serializers.SerializerMethodField()  # Check if alert is still active
    is_expired = serializers.SerializerMethodField()
    time_until_expiry = serializers.SerializerMethodField()  # Days until alert expires
    
    class Meta:
        model = FarmersWeatherAlert
        fields = ['id', 'farmer', 'farmer_name', 'alert_title', 'alert_message', 'severity',
              'alert_type', 'region', 'issued_at', 'expires_at', 'is_active', 'is_expired', 'time_until_expiry',
                  'is_read', 'action_taken', 'farmer_notes', 'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'issued_at', 'farmer_name', 
                           'is_active', 'time_until_expiry']  # Can't edit these
    
    def get_farmer_name(self, obj):
        # Returns farmer's full name
        return f"{obj.farmer.first_name} {obj.farmer.last_name}"
    
    def get_is_active(self, obj):
        # Check if alert is still active (hasn't expired)
        if not obj.expires_at:  # If no expiry set
            return True  # Still active
        
        now = timezone.now()  # Current date/time (timezone-aware)
        return now < obj.expires_at  # True if before expiry
    
    def get_time_until_expiry(self, obj):
        # Calculate hours until alert expires
        if not obj.expires_at:  # If no expiry
            return None  # Unknown
        
        now = timezone.now()  # Current date/time (timezone-aware)
        difference = obj.expires_at - now  # Calculate time remaining
        hours = difference.total_seconds() / 3600  # Convert to hours
        return round(hours, 1)  # Round to 1 decimal place

    def get_is_expired(self, obj):
        if not obj.expires_at:
            return False
        return timezone.now() >= obj.expires_at


# SERIALIZER 3: WeatherForecastSerializer - Convert weather forecast to/from JSON
class WeatherForecastSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields
    temperature_range = serializers.SerializerMethodField()  # Show min-max temp
    rainfall_description = serializers.SerializerMethodField()  # Describe rainfall chance
    
    class Meta:
        model = WeatherForecast
        fields = ['id', 'location', 'forecast_date', 'min_temperature', 'max_temperature',
                  'temperature_range', 'rainfall_probability', 'expected_rainfall_mm',
                  'rainfall_description', 'humidity', 'condition', 'wind_speed',
                  'forecast_issued_at', 'created_at']
        
        read_only_fields = ['created_at', 'forecast_issued_at', 'temperature_range', 'rainfall_description']  # Can't edit
    
    def get_temperature_range(self, obj):
        # Returns formatted temperature range like "18-35°C"
        return f"{obj.min_temperature}°C - {obj.max_temperature}°C"
    
    def get_rainfall_description(self, obj):
        # Convert rainfall probability to readable description
        prob = obj.rainfall_probability  # Get probability percentage
        
        if prob < 20:  # Less than 20%
            return "Very Low (Unlikely)"
        elif prob < 40:  # 20-40%
            return "Low (Possible)"
        elif prob < 60:  # 40-60%
            return "Moderate (Likely)"
        elif prob < 80:  # 60-80%
            return "High (Very Likely)"
        else:  # 80%+
            return "Very High (Almost Certain)"


# SERIALIZER 4: WeatherAlertDetailSerializer - Show alert with all details
class WeatherAlertDetailSerializer(WeatherAlertValidationMixin, serializers.ModelSerializer):
    # SerializerMethodField = Custom fields for additional info
    farmer_name = serializers.SerializerMethodField()  # Farmer name
    farmer_details = serializers.SerializerMethodField()  # Farmer contact info
    is_active = serializers.SerializerMethodField()  # If alert is still valid
    is_expired = serializers.SerializerMethodField()
    recommendation = serializers.SerializerMethodField()  # What farmer should do
    
    class Meta:
        model = FarmersWeatherAlert
        fields = ['id', 'farmer', 'farmer_name', 'farmer_details', 'alert_title',
              'alert_message', 'severity', 'alert_type', 'region', 'issued_at', 'expires_at',
              'is_active', 'is_expired', 'is_read', 'action_taken', 'farmer_notes', 
                  'recommendation', 'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'issued_at', 'farmer_name',
                           'farmer_details', 'is_active', 'recommendation']  # Can't edit
    
    def get_farmer_name(self, obj):
        # Farmer's full name
        return f"{obj.farmer.first_name} {obj.farmer.last_name}"
    
    def get_farmer_details(self, obj):
        # Farmer's contact details for quick reference
        return {
            'phone': obj.farmer.phone_number,
            'email': obj.farmer.email,
            'contact_method': obj.farmer.contact_method,
        }
    
    def get_is_active(self, obj):
        # Check if alert is still active
        if not obj.expires_at:
            return True
        
        now = timezone.now()
        return now < obj.expires_at
    
    def get_recommendation(self, obj):
        # Give farming advice based on alert type
        alert_type = obj.alert_type
        
        # Dictionary of recommendations for each alert type
        recommendations = {
            'Rain': 'Delay watering. Check drainage. Inspect crops for diseases.',
            'Frost': 'Consider covering plants. Reduce watering. Move plants indoors if possible.',
            'Heat': 'Increase watering frequency. Use mulch. Provide shade if possible.',
            'Wind': 'Stake plants. Reduce pruning. Check soil moisture more often.',
            'Disease': 'Inspect crops carefully. Apply fungicide if needed. Improve ventilation.',
            'Pest': 'Check plants for pests visually. Apply appropriate pesticide. Monitor closely.',
        }
        
        return recommendations.get(alert_type, 'Monitor your crops closely.')  # Return recommendation

    def get_is_expired(self, obj):
        if not obj.expires_at:
            return False
        return timezone.now() >= obj.expires_at


# SERIALIZER 5: LocationWeatherSerializer - Weather summary for a location
class LocationWeatherSerializer(serializers.Serializer):
    # This is a custom serializer (not based on model) for location weather summary
    
    # CharField = Location name
    location = serializers.CharField(max_length=100)  # City/region name
    
    # Current weather
    current_weather = WeatherDataSerializer()  # Today's weather
    
    # Forecast
    forecast = WeatherForecastSerializer(many=True)  # Next few days forecast
    
    # Active alerts
    active_alerts = FarmersWeatherAlertSerializer(many=True)  # Active alert for this location
