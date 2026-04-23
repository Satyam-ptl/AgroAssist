from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from AgroAssist_Backend.farmers.models import Farmer
from AgroAssist_Backend.farmers.stateless_token_auth import issue_auth_token


class FarmerApiTests(TestCase):
	def setUp(self):
		user_model = get_user_model()
		self.admin = user_model.objects.create_superuser(
			username='admin',
			email='admin@example.com',
			password='Admin@12345',
		)
		self.farmer_user = user_model.objects.create_user(
			username='farmeruser',
			email='farmer@example.com',
			password='Farmer@12345',
		)
		self.linked_farmer = Farmer.objects.create(
			first_name='Farmer',
			last_name='User',
			email='farmer@example.com',
			phone_number='9123456789',
			address='Village Road',
			city='Nashik',
			state='Maharashtra',
			postal_code=422001,
			preferred_language='English',
			land_area_hectares=3.0,
			soil_type='Loamy',
			experience_level='Intermediate',
		)
		self.target_farmer = Farmer.objects.create(
			first_name='Asha',
			last_name='Deshmukh',
			email='asha@example.com',
			phone_number='9988776655',
			address='Farm Road',
			city='Pune',
			state='Maharashtra',
			postal_code=411001,
			preferred_language='English',
			land_area_hectares=4.0,
			soil_type='Clay',
			experience_level='Beginner',
		)
		self.target_farmer_user = user_model.objects.create_user(
			username='ashauser',
			email='asha@example.com',
			password='Farmer@12345',
		)

		self.admin_client = APIClient()
		self.admin_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.admin)}')

		self.farmer_client = APIClient()
		self.farmer_client.credentials(HTTP_AUTHORIZATION=f'Token {issue_auth_token(self.farmer_user)}')

	def test_admin_can_list_farmers(self):
		response = self.admin_client.get('/api/farmers/')
		self.assertEqual(response.status_code, 200)
		self.assertIn('results', response.data)

	def test_admin_can_retrieve_farmer_detail(self):
		response = self.admin_client.get(f'/api/farmers/{self.target_farmer.id}/')
		self.assertEqual(response.status_code, 200)
		self.assertEqual(response.data['first_name'], 'Asha')

	def test_admin_can_create_farmer(self):
		response = self.admin_client.post(
			'/api/farmers/',
			{
				'first_name': 'Neha',
				'last_name': 'Patil',
				'email': 'neha@example.com',
				'phone_number': '9001122233',
				'address': 'Village Center',
				'city': 'Aurangabad',
				'state': 'Maharashtra',
				'postal_code': 431001,
				'preferred_language': 'English',
				'land_area_hectares': 2.2,
				'soil_type': 'Loamy',
				'experience_level': 'Beginner',
			},
			format='json',
		)
		self.assertEqual(response.status_code, 201)
		self.assertTrue(Farmer.objects.filter(email='neha@example.com').exists())

	def test_admin_can_delete_farmer(self):
		response = self.admin_client.delete(f'/api/farmers/{self.target_farmer.id}/')
		self.assertEqual(response.status_code, 204)
		self.assertFalse(Farmer.objects.filter(id=self.target_farmer.id).exists())
		self.assertFalse(
			get_user_model().objects.filter(id=self.target_farmer_user.id).exists()
		)

	def test_non_admin_cannot_delete_farmer(self):
		response = self.farmer_client.delete(f'/api/farmers/{self.target_farmer.id}/')
		self.assertIn(response.status_code, [401, 403])
