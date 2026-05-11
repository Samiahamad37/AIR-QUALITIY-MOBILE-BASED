from rest_framework import serializers
from .models import Sensor, SensorReading, AQIPrediction, Alert


class SensorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sensor
        fields = ['id', 'sensor_id', 'name', 'description', 'location_name', 'latitude', 'longitude', 
                  'altitude', 'status', 'sensor_type', 'is_public', 'created_at', 'updated_at']


class SensorReadingSerializer(serializers.ModelSerializer):
    sensor_name = serializers.CharField(source='sensor.name', read_only=True)

    class Meta:
        model = SensorReading
        fields = ['id', 'sensor', 'sensor_name', 'timestamp', 'co', 'no2', 'benzene', 
                  'temperature', 'humidity', 'pressure', 'wind_speed', 'aqi', 'aqi_category', 'is_valid']


class AQIPredictionSerializer(serializers.ModelSerializer):
    sensor_name = serializers.CharField(source='sensor.name', read_only=True)

    class Meta:
        model = AQIPrediction
        fields = ['id', 'sensor', 'sensor_name', 'prediction_time', 'predicted_aqi', 
                  'predicted_category', 'co_predicted', 'no2_predicted', 'benzene_predicted', 
                  'temperature_predicted', 'model_type', 'confidence']


class AlertSerializer(serializers.ModelSerializer):
    sensor_name = serializers.CharField(source='sensor.name', read_only=True)

    class Meta:
        model = Alert
        fields = ['id', 'sensor', 'sensor_name', 'alert_type', 'severity', 'title', 'message', 
                  'is_active', 'triggered_at', 'resolved_at', 'metadata']
