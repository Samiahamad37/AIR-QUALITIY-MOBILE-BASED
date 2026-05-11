"""
Tests for AQI Calculator utility
"""
from django.test import TestCase
from airquality_api.utils.aqi_calculator import AQICalculator


class AQICalculatorTestCase(TestCase):
    """Test cases for AQI Calculator."""

    def test_co_aqi_calculation(self):
        """Test CO AQI calculation."""
        # CO value of 2.5 should give Good AQI
        aqi = AQICalculator.calculate_pollutant_aqi('co', 2.5)
        self.assertIsNotNone(aqi)
        # Check it's in Good range (0-50)
        self.assertGreaterEqual(aqi, 0)
        self.assertLessEqual(aqi, 50)

    def test_no2_aqi_calculation(self):
        """Test NO2 AQI calculation."""
        aqi = AQICalculator.calculate_pollutant_aqi('no2', 50)
        self.assertIsNotNone(aqi)
        self.assertGreaterEqual(aqi, 0)

    def test_benzene_aqi_calculation(self):
        """Test Benzene AQI calculation."""
        aqi = AQICalculator.calculate_pollutant_aqi('benzene', 3)
        self.assertIsNotNone(aqi)
        self.assertGreaterEqual(aqi, 0)

    def test_overall_aqi_calculation(self):
        """Test overall AQI calculation."""
        aqi, category = AQICalculator.calculate_overall_aqi(
            co=2.5,
            no2=50,
            benzene=3
        )
        self.assertIsNotNone(aqi)
        self.assertIsNotNone(category)
        self.assertIn(category, ['good', 'moderate', 'unhealthy_sensitive', 'unhealthy', 'very_unhealthy', 'hazardous'])

    def test_aqi_category_classification(self):
        """Test AQI category classification."""
        # Good
        self.assertEqual(AQICalculator.get_category_from_aqi(25), 'good')
        # Moderate
        self.assertEqual(AQICalculator.get_category_from_aqi(75), 'moderate')
        # Unhealthy for Sensitive Groups
        self.assertEqual(AQICalculator.get_category_from_aqi(125), 'unhealthy_sensitive')
        # Unhealthy
        self.assertEqual(AQICalculator.get_category_from_aqi(175), 'unhealthy')

    def test_color_coding(self):
        """Test color coding for AQI."""
        color = AQICalculator.get_color_for_aqi(50)
        self.assertIsNotNone(color)
        self.assertTrue(color.startswith('#'))

    def test_recommendations_generation(self):
        """Test health recommendations."""
        recommendations = AQICalculator.get_recommendations(100, 'adult')
        self.assertIn('category', recommendations)
        self.assertIn('aqi', recommendations)
        self.assertIn('general', recommendations)
        self.assertIn('personal', recommendations)

    def test_recommendations_for_sensitive_group(self):
        """Test recommendations for sensitive groups."""
        recommendations_child = AQICalculator.get_recommendations(150, 'child')
        recommendations_senior = AQICalculator.get_recommendations(150, 'senior')
        
        self.assertIsNotNone(recommendations_child)
        self.assertIsNotNone(recommendations_senior)
