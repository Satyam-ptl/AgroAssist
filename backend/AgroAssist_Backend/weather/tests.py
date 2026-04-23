from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from AgroAssist_Backend.farmers.models import Farmer
from AgroAssist_Backend.farmers.stateless_token_auth import issue_auth_token
from AgroAssist_Backend.weather.models import WeatherData, FarmersWeatherAlert


class WeatherApiTests(TestCase):
	def setUp(self):
		user_model = get_user_model()
		self.admin = user_model.objects.create_superuser(
			username='admin',
			email='admin@example.com',
			password='Admin@12345',
		)
		self.reader = user_model.objects.create_user(
			username='reader',
			email='reader@example.com',
			password='Reader@12345',
		)
		self.farmer = Farmer.objects.create(
			first_name='Weather',
			last_name='User',
			email='reader@example.com',
			phone_number='9345678901',
			address='Village Road',
			city='Solapur',
			state='Maharashtra',
			postal_code=413001,
			preferred_language='English',
			land_area_hectares=2.8,
			soil_type='Loamy',
			experience_level='Beginner',
		)
		self.weather = WeatherData.objects.create(
			location='Pune',
			temperature=29.5,
			humidity=68,
			rainfall=4,
			condition='Sunny',
			wind_speed=12.0,
			recorded_at=timezone.now(),
		)

		self.reader_client = APIClient()
		self.reader_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.reader)}')

		self.admin_client = APIClient()
		self.admin_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.admin)}')

	def test_authenticated_user_can_list_weather_data(self):
		response = self.reader_client.get('/api/weather-data/')
		self.assertEqual(response.status_code, 200)
		self.assertIn('results', response.data)

	def test_admin_can_create_weather_alert(self):
		response = self.admin_client.post(
			'/api/weather-alerts/',
			{
				'farmer': self.farmer.id,
				'alert_title': 'Heavy Rain Warning',
				'alert_message': 'Drain field water quickly.',
				'severity': 'High',
				'alert_type': 'Rain',
				'expires_at': timezone.now() + timedelta(days=1),
				'is_read': False,
				'action_taken': False,
				'farmer_notes': '',
			},
			format='json',
		)
		self.assertEqual(response.status_code, 201)
		self.assertEqual(FarmersWeatherAlert.objects.count(), 1)
