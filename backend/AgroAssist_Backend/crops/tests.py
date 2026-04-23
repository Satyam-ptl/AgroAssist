from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from AgroAssist_Backend.crops.models import Crop
from AgroAssist_Backend.farmers.models import Farmer
from AgroAssist_Backend.farmers.stateless_token_auth import issue_auth_token


class CropApiTests(TestCase):
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
        Farmer.objects.create(
            first_name='Reader',
            last_name='User',
            email='reader@example.com',
            phone_number='9876543210',
            address='Village Road',
            city='Pune',
            state='Maharashtra',
            postal_code=411001,
            preferred_language='English',
            land_area_hectares=2.5,
            soil_type='Loamy',
            experience_level='Beginner',
        )
        self.crop = Crop.objects.create(
            name='Rice',
            category='Cereal',
            crop_type='Field',
            description='Staple crop for monsoon season.',
            season='Kharif',
            soil_type='Loamy',
            growth_duration_days=120,
            optimal_temperature=28.0,
            optimal_humidity=70.0,
            optimal_soil_moisture=45.0,
            water_required_mm_per_week=35.0,
            fertilizer_required='NPK',
            expected_yield_per_hectare=2500,
        )

        self.reader_client = APIClient()
        self.reader_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.reader)}')

        self.admin_client = APIClient()
        self.admin_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.admin)}')

    def test_list_requires_authentication(self):
        response = APIClient().get('/api/crops/')
        self.assertIn(response.status_code, [401, 403])

    def test_authenticated_user_can_list_crops(self):
        response = self.reader_client.get('/api/crops/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('results', response.data)

    def test_authenticated_user_can_filter_by_category_and_crop_type(self):
        Crop.objects.create(
            name='Tomato',
            category='Vegetable',
            crop_type='Horticulture',
            description='Popular vegetable crop.',
            season='Rabi',
            soil_type='Loamy',
            growth_duration_days=95,
            optimal_temperature=23.0,
            optimal_humidity=60.0,
            optimal_soil_moisture=40.0,
            water_required_mm_per_week=28.0,
            fertilizer_required='Compost',
            expected_yield_per_hectare=2100,
        )

        response = self.reader_client.get('/api/crops/?category=Cereal&crop_type=Field')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data.get('results', [])), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Rice')

    def test_authenticated_user_can_retrieve_crop_detail(self):
        response = self.reader_client.get(f'/api/crops/{self.crop.id}/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['name'], 'Rice')

    def test_admin_can_create_crop(self):
        response = self.admin_client.post(
            '/api/crops/',
            {
                'name': 'Wheat',
                'description': 'Winter crop',
                'season': 'Rabi',
                'soil_type': 'Loamy',
                'growth_duration_days': 110,
                'optimal_temperature': 24.0,
                'optimal_humidity': 55.0,
                'optimal_soil_moisture': 40.0,
                'water_required_mm_per_week': 25.0,
                'fertilizer_required': 'Urea',
                'expected_yield_per_hectare': 1800,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Crop.objects.count(), 2)

    def test_non_admin_cannot_create_crop(self):
        response = self.reader_client.post(
            '/api/crops/',
            {
                'name': 'Maize',
                'description': 'General crop',
                'season': 'Summer',
                'soil_type': 'Loamy',
                'growth_duration_days': 95,
                'optimal_temperature': 26.0,
                'optimal_humidity': 60.0,
                'optimal_soil_moisture': 38.0,
                'water_required_mm_per_week': 30.0,
                'fertilizer_required': 'NPK',
                'expected_yield_per_hectare': 1600,
            },
            format='json',
        )
        self.assertIn(response.status_code, [401, 403])
