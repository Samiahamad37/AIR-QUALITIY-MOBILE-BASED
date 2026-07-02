"""
Tests for API endpoints
"""
from unittest.mock import patch

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
        self.assertIn('device_id', response.data)
        self.assertIn('pollutants', response.data)

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

    @patch('airquality_api.api.views.InfluxDBService')
    def test_predict_all_endpoint(self, mock_service_cls):
        """Test the predict-all endpoint."""
        mock_service = mock_service_cls.return_value
        mock_service.query_latest_reading.return_value = {
            'timestamp': timezone.now(),
            'co2': 450,
            'nox': 55,
            'pm25': 18,
            'pm10': 22,
        }
        mock_service.query_aqi_history.return_value = [
            {'timestamp': timezone.now() - timedelta(hours=1), 'aqi': 60},
            {'timestamp': timezone.now() - timedelta(hours=2), 'aqi': 58},
        ]

        response = self.client.get('/api/predict/all')

        self.assertEqual(response.status_code, 200)
        self.assertIn('devices', response.data)

    @patch('airquality_api.api.views.InfluxDBService')
    def test_recommend_endpoint(self, mock_service_cls):
        """Test the recommendation endpoint."""
        mock_service = mock_service_cls.return_value
        mock_service.query_latest_reading.return_value = {
            'timestamp': timezone.now(),
            'co2': 450,
            'nox': 55,
            'pm25': 18,
            'pm10': 22,
        }

        response = self.client.get('/api/recommend/?device_id=lands-building')

        self.assertEqual(response.status_code, 200)
        self.assertIn('recommendations', response.data)

    @patch('airquality_api.api.views.InfluxDBService')
    def test_history_sensor_endpoint(self, mock_service_cls):
        """Test the sensor history endpoint."""
        mock_service = mock_service_cls.return_value
        mock_service.query_recent_readings.return_value = [
            {'timestamp': timezone.now(), 'co2': 400, 'nox': 50},
            {'timestamp': timezone.now() - timedelta(hours=1), 'co2': 390, 'nox': 48},
        ]

        response = self.client.get('/api/history/sensor?device_id=lands-building&hours=24')

        self.assertEqual(response.status_code, 200)
        self.assertIn('readings', response.data)
