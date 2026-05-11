from django.db import models
from django.contrib.gis.db import models as gis_models


class Sensor(models.Model):
    """Sensor model for air quality monitoring."""
    SENSOR_STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Maintenance'),
    ]

    sensor_id = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    location_name = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    altitude = models.FloatField(blank=True, null=True)
    
    status = models.CharField(max_length=20, choices=SENSOR_STATUS_CHOICES, default='active')
    sensor_type = models.CharField(max_length=100, default='air_quality')
    
    installation_date = models.DateTimeField()
    last_maintenance = models.DateTimeField(blank=True, null=True)
    
    manufacturer = models.CharField(max_length=255, blank=True, null=True)
    model = models.CharField(max_length=255, blank=True, null=True)
    
    is_public = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name = 'Sensor'
        verbose_name_plural = 'Sensors'

    def __str__(self):
        return f"{self.name} ({self.sensor_id})"


class SensorReading(models.Model):
    """Historical sensor readings stored in MySQL."""
    sensor = models.ForeignKey(Sensor, on_delete=models.CASCADE, related_name='readings')
    
    timestamp = models.DateTimeField(db_index=True)
    
    co = models.FloatField(null=True, blank=True)  # Carbon Monoxide (μg/m³)
    no2 = models.FloatField(null=True, blank=True)  # Nitrogen Dioxide (μg/m³)
    benzene = models.FloatField(null=True, blank=True)  # Benzene (μg/m³)
    temperature = models.FloatField(null=True, blank=True)  # Temperature (°C)
    humidity = models.FloatField(null=True, blank=True)  # Humidity (%)
    pressure = models.FloatField(null=True, blank=True)  # Atmospheric Pressure (hPa)
    wind_speed = models.FloatField(null=True, blank=True)  # Wind Speed (m/s)
    
    aqi = models.IntegerField(null=True, blank=True)  # Air Quality Index
    aqi_category = models.CharField(max_length=20, null=True, blank=True)
    
    is_valid = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['sensor', '-timestamp']),
            models.Index(fields='-timestamp'),
        ]
        verbose_name = 'Sensor Reading'
        verbose_name_plural = 'Sensor Readings'

    def __str__(self):
        return f"{self.sensor.name} - {self.timestamp}"


class AQIPrediction(models.Model):
    """AQI predictions for locations."""
    sensor = models.ForeignKey(Sensor, on_delete=models.CASCADE, related_name='predictions')
    
    prediction_time = models.DateTimeField()  # Time of prediction
    predicted_aqi = models.IntegerField()
    predicted_category = models.CharField(max_length=20)
    
    co_predicted = models.FloatField(null=True, blank=True)
    no2_predicted = models.FloatField(null=True, blank=True)
    benzene_predicted = models.FloatField(null=True, blank=True)
    temperature_predicted = models.FloatField(null=True, blank=True)
    
    model_type = models.CharField(
        max_length=50,
        choices=[
            ('moving_avg', 'Moving Average'),
            ('linear_regression', 'Linear Regression'),
            ('arima', 'ARIMA'),
        ],
        default='moving_avg'
    )
    confidence = models.FloatField(default=0.0)  # Confidence score (0-1)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-prediction_time']
        verbose_name = 'AQI Prediction'
        verbose_name_plural = 'AQI Predictions'

    def __str__(self):
        return f"{self.sensor.name} - {self.prediction_time}"


class Alert(models.Model):
    """Air quality alerts for users."""
    ALERT_TYPE_CHOICES = [
        ('high_aqi', 'High AQI'),
        ('pollutant_spike', 'Pollutant Spike'),
        ('unusual_pattern', 'Unusual Pattern'),
        ('maintenance_due', 'Maintenance Due'),
    ]

    ALERT_SEVERITY_CHOICES = [
        ('info', 'Information'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
    ]

    sensor = models.ForeignKey(Sensor, on_delete=models.CASCADE, related_name='alerts')
    alert_type = models.CharField(max_length=50, choices=ALERT_TYPE_CHOICES)
    severity = models.CharField(max_length=20, choices=ALERT_SEVERITY_CHOICES)
    
    title = models.CharField(max_length=255)
    message = models.TextField()
    
    is_active = models.BooleanField(default=True)
    triggered_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['-triggered_at']
        verbose_name = 'Alert'
        verbose_name_plural = 'Alerts'

    def __str__(self):
        return f"{self.title} - {self.sensor.name}"
