"""
External API Service for Air Quality Predictions and Recommendations

Handles communication with external APIs:
- https://airquality-ai.tlms.live/api/predict/all
- https://airquality-ai.tlms.live/api/recommend/
"""

import requests
from django.conf import settings
from decouple import config
import logging

logger = logging.getLogger(__name__)


class ExternalAPIService:
    """Service to fetch predictions and recommendations from external API."""

    PREDICTION_API_URL = config('EXTERNAL_PREDICTION_URL', default='https://airquality-ai.tlms.live/api/predict/all')
    RECOMMENDATION_API_URL = config('EXTERNAL_RECOMMENDATION_URL', default='https://airquality-ai.tlms.live/api/recommend/')
    TIMEOUT = 10  # seconds

    @classmethod
    def get_predictions(cls):
        """
        Fetch 6-hour air quality predictions from external API.

        Returns:
            dict: Prediction data from external API
            None: If request fails
        """
        try:
            response = requests.get(
                cls.PREDICTION_API_URL,
                timeout=cls.TIMEOUT
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.Timeout:
            logger.error(f"External API timeout: {cls.PREDICTION_API_URL}")
            return None
        except requests.exceptions.RequestException as e:
            logger.error(f"External API request failed: {e}")
            return None
        except ValueError as e:
            logger.error(f"External API response parsing failed: {e}")
            return None

    @classmethod
    def get_recommendations(cls):
        """
        Fetch AI-generated health recommendations from external API.

        Returns:
            dict: Recommendation data from external API
            None: If request fails
        """
        try:
            response = requests.get(
                cls.RECOMMENDATION_API_URL,
                timeout=cls.TIMEOUT
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.Timeout:
            logger.error(f"External API timeout: {cls.RECOMMENDATION_API_URL}")
            return None
        except requests.exceptions.RequestException as e:
            logger.error(f"External API request failed: {e}")
            return None
        except ValueError as e:
            logger.error(f"External API response parsing failed: {e}")
            return None
