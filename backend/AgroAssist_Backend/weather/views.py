# Weather API ViewSets - Readonly access to weather data
from rest_framework import viewsets, filters
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.db.models import Q
from django.utils import timezone
from .models import WeatherData, FarmersWeatherAlert, WeatherForecast
from .serializers import WeatherDataSerializer, FarmersWeatherAlertSerializer, WeatherForecastSerializer
from AgroAssist_Backend.farmers.models import Farmer


def _linked_farmer_for_user(user):
    return Farmer.objects.filter(email__iexact=user.email).first()

class StandardPagination(PageNumberPagination):
    page_size = 20  # Show 20 results per page

# WeatherData ViewSet - Current weather information
class WeatherDataViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = WeatherData.objects.all()  # All current weather records
    serializer_class = WeatherDataSerializer  # Convert to JSON
    pagination_class = StandardPagination  # Paginate results
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Search and sort
    search_fields = ['location']  # Search by location name
    ordering = ['-recorded_at']  # Newest first

    def get_queryset(self):
        queryset = WeatherData.objects.all().order_by('-recorded_at')
        location = self.request.query_params.get('location')
        if location:
            queryset = queryset.filter(location__icontains=location)
        return queryset

# Weather Alert ViewSet - Farmer weather alerts
class FarmersWeatherAlertViewSet(viewsets.ModelViewSet):
    queryset = FarmersWeatherAlert.objects.all()  # All alerts
    serializer_class = FarmersWeatherAlertSerializer  # Convert to JSON
    pagination_class = StandardPagination  # Paginate
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Filter
    search_fields = ['farmer__first_name', 'alert_type']  # Search
    ordering = ['-created_at']  # Newest first
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        queryset = FarmersWeatherAlert.objects.all().order_by('-created_at')
        show_expired = str(self.request.query_params.get('show_expired', '')).lower() == 'true'
        region = (self.request.query_params.get('region') or '').strip()
        now = timezone.now()
        alert_field_names = {field.name for field in FarmersWeatherAlert._meta.fields}

        if not (show_expired and (user.is_staff or user.is_superuser)):
            if 'expires_at' in alert_field_names:
                queryset = queryset.filter(Q(expires_at__isnull=True) | Q(expires_at__gte=now))
            elif 'is_active' in alert_field_names:
                queryset = queryset.filter(is_active=True)

        if 'is_active' in alert_field_names and not (show_expired and (user.is_staff or user.is_superuser)):
            queryset = queryset.filter(is_active=True)

        if region:
            queryset = queryset.filter(region__icontains=region)

        if user.is_staff or user.is_superuser:
            farmer_id = self.request.query_params.get('farmer')
            if farmer_id:
                queryset = queryset.filter(farmer_id=farmer_id)
            return queryset

        farmer = _linked_farmer_for_user(user)
        if farmer:
            return queryset.filter(farmer=farmer)

        return queryset.none()

# Forecast ViewSet - Weather predictions
class WeatherForecastViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = WeatherForecast.objects.all()  # All forecasts
    serializer_class = WeatherForecastSerializer  # Convert to JSON
    pagination_class = StandardPagination  # Paginate
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Filter
    search_fields = ['location']  # Search by location
    ordering = ['forecast_date']  # By date (earliest first)

    def get_queryset(self):
        queryset = WeatherForecast.objects.all().order_by('forecast_date')
        location = self.request.query_params.get('location')
        if location:
            queryset = queryset.filter(location__icontains=location)
        return queryset
