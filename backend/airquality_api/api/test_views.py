"""
Tests for API endpoints
"""
from django.test import TestCase
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from airquality_api.sensors.models import Sensor, SensorReading
from django.utils import timezone
from datetime import timedelta

User = get_user_model()


class AirQualityAPITestCase(TestCase):
    """Test cases for Air Quality API."""

    def setUp(self):
        """Set up test fixtures."""
        self.client = APIClient()
        
        # Create test sensor
        self.sensor = Sensor.objects.create(
            sensor_id='TEST_SENSOR_001',
            name='Test Sensor',
            location_name='Test Location',
            latitude=40.7128,
            longitude=-74.0060,
            installation_date=timezone.now(),
            is_public=True,
            status='active'
        )

        # Create test reading
        self.reading = SensorReading.objects.create(
            sensor=self.sensor,
            timestamp=timezone.now(),
            co=2.5,
            no2=45,
            benzene=3,
            temperature=20,
            humidity=65,
            aqi=45,
            aqi_category='good',
            is_valid=True
        )

    def test_latest_air_quality(self):
        """Test latest air quality endpoint."""
        response = self.client.get('/api/air-quality/latest/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('data', response.data)

    def test_air_quality_history(self):
        """Test air quality history endpoint."""
        response = self.client.get(f'/api/air-quality/history/?sensor_id={self.sensor.sensor_id}')
        self.assertEqual(response.status_code, 200)
        self.assertIn('data', response.data)

    def test_missing_sensor_id(self):
        """Test history endpoint with missing sensor_id."""
        response = self.client.get('/api/air-quality/history/')
        self.assertEqual(response.status_code, 400)

    def test_invalid_sensor_id(self):
        """Test with invalid sensor ID."""
        response = self.client.get('/api/air-quality/history/?sensor_id=INVALID_SENSOR')
        self.assertEqual(response.status_code, 404)

    def test_nearby_sensors(self):
        """Test nearby sensors endpoint."""
        response = self.client.get(
            f'/api/air-quality/nearby-sensors/?latitude=40.7128&longitude=-74.0060&radius=10'
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn('sensors', response.data)

    def test_alerts_endpoint(self):
        """Test alerts endpoint."""
        response = self.client.get('/api/air-quality/alerts/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('alerts', response.data)
