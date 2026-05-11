from rest_framework import serializers


class AirQualitySerializer(serializers.Serializer):
    """Serializer for air quality data."""
    sensor_id = serializers.CharField()
    sensor_name = serializers.CharField()
    location = serializers.CharField()
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    
    timestamp = serializers.DateTimeField()
    aqi = serializers.IntegerField()
    aqi_category = serializers.CharField()
    color = serializers.CharField()
    
    co = serializers.FloatField()
    no2 = serializers.FloatField()
    benzene = serializers.FloatField()
    temperature = serializers.FloatField()
    humidity = serializers.FloatField()
    pressure = serializers.FloatField()


class HealthRecommendationSerializer(serializers.Serializer):
    """Serializer for health recommendations."""
    category = serializers.CharField()
    aqi = serializers.IntegerField()
    general = serializers.CharField()
    personal = serializers.CharField()
    color = serializers.CharField()


class AQIPredictionDataSerializer(serializers.Serializer):
    """Serializer for AQI prediction data."""
    timestamp = serializers.DateTimeField()
    predicted_aqi = serializers.IntegerField()
    category = serializers.CharField()
    confidence = serializers.FloatField()
