"""
Air Quality Prediction Module

Implements multiple prediction models:
- Moving Average
- Linear Regression
- ARIMA (optional)
"""

import numpy as np
from datetime import datetime, timedelta
from django.utils import timezone


class PredictionModel:
    """Base prediction model."""

    def __init__(self, data_points=None):
        self.data_points = data_points or []

    def add_data_point(self, value):
        """Add a data point."""
        self.data_points.append(value)

    def predict(self, hours_ahead=12):
        """Predict AQI for hours ahead. To be implemented by subclasses."""
        raise NotImplementedError


class MovingAveragePrediction(PredictionModel):
    """Simple moving average prediction model."""

    def __init__(self, data_points=None, window_size=6):
        super().__init__(data_points)
        self.window_size = window_size

    def predict(self, hours_ahead=12):
        """Predict using moving average."""
        if len(self.data_points) < self.window_size:
            return []

        predictions = []
        current_avg = np.mean(self.data_points[-self.window_size:])

        for hour in range(1, hours_ahead + 1):
            timestamp = timezone.now() + timedelta(hours=hour)
            predictions.append({
                'timestamp': timestamp,
                'value': round(current_avg),
                'confidence': 0.7,
            })

        return predictions


class LinearRegressionPrediction(PredictionModel):
    """Linear regression prediction model."""

    def predict(self, hours_ahead=12):
        """Predict using linear regression."""
        if len(self.data_points) < 2:
            return []

        # Create time series
        x = np.arange(len(self.data_points))
        y = np.array(self.data_points)

        # Calculate linear regression coefficients
        coefficients = np.polyfit(x, y, 1)
        poly = np.poly1d(coefficients)

        predictions = []
        last_x = len(self.data_points) - 1

        for hour in range(1, hours_ahead + 1):
            predicted_value = poly(last_x + hour)
            confidence = max(0.5, 1 - (abs(hour) * 0.05))  # Decrease confidence over time

            timestamp = timezone.now() + timedelta(hours=hour)
            predictions.append({
                'timestamp': timestamp,
                'value': round(max(0, predicted_value)),  # AQI shouldn't be negative
                'confidence': round(confidence, 2),
            })

        return predictions


class ArimaLikePrediction(PredictionModel):
    """Simple ARIMA-like prediction model."""

    def __init__(self, data_points=None, p=1, d=1, q=1):
        super().__init__(data_points)
        self.p = p
        self.d = d
        self.q = q

    def predict(self, hours_ahead=12):
        """Predict using ARIMA-like approach."""
        if len(self.data_points) < 5:
            return []

        # Simple differencing for trend removal
        differenced = [self.data_points[i] - self.data_points[i-1] for i in range(1, len(self.data_points))]

        predictions = []
        last_value = self.data_points[-1]
        last_diff = differenced[-1] if differenced else 0

        for hour in range(1, hours_ahead + 1):
            # Add accumulated difference
            predicted_value = last_value + (last_diff * hour)
            confidence = max(0.4, 1 - (hour * 0.04))

            timestamp = timezone.now() + timedelta(hours=hour)
            predictions.append({
                'timestamp': timestamp,
                'value': round(max(0, predicted_value)),
                'confidence': round(confidence, 2),
            })

        return predictions


class PredictionService:
    """Service to manage and execute predictions."""

    @staticmethod
    def predict_aqi(historical_readings, model_type='moving_avg', hours_ahead=12):
        """
        Predict AQI for future hours.

        Args:
            historical_readings: List of (timestamp, aqi) tuples
            model_type: Type of model to use ('moving_avg', 'linear_reg', 'arima')
            hours_ahead: Number of hours to predict ahead

        Returns:
            List of predictions with timestamps and values
        """
        # Extract AQI values
        aqi_values = [reading[1] for reading in historical_readings if reading[1] is not None]

        if not aqi_values:
            return []

        if model_type == 'moving_avg':
            model = MovingAveragePrediction(aqi_values, window_size=min(6, len(aqi_values)))
        elif model_type == 'linear_reg':
            model = LinearRegressionPrediction(aqi_values)
        elif model_type == 'arima':
            model = ArimaLikePrediction(aqi_values)
        else:
            model = MovingAveragePrediction(aqi_values)

        return model.predict(hours_ahead)

    @staticmethod
    def predict_pollutant(historical_values, pollutant_name, model_type='linear_reg', hours_ahead=12):
        """
        Predict specific pollutant concentration.

        Args:
            historical_values: List of concentration values
            pollutant_name: Name of pollutant (CO, NO2, Benzene, etc.)
            model_type: Type of model to use
            hours_ahead: Number of hours to predict

        Returns:
            List of predictions
        """
        values = [v for v in historical_values if v is not None]

        if not values:
            return []

        if model_type == 'linear_reg':
            model = LinearRegressionPrediction(values)
        else:
            model = MovingAveragePrediction(values)

        predictions = model.predict(hours_ahead)

        for pred in predictions:
            pred['pollutant'] = pollutant_name

        return predictions
