from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.utils import timezone
from datetime import timedelta
from airquality_api.sensors.models import Sensor, SensorReading, AQIPrediction, Alert
from airquality_api.utils.aqi_calculator import AQICalculator
from airquality_api.utils.prediction import PredictionService
from airquality_api.utils.influxdb_service import InfluxDBService
from .serializers import AirQualitySerializer, HealthRecommendationSerializer, AQIPredictionDataSerializer


class AirQualityAPIViewSet(viewsets.ViewSet):
    """Air quality API endpoints for mobile app."""
    permission_classes = [AllowAny]

    @action(detail=False, methods=['get'])
    def influx(self, request):
        """Fetch sensor readings from InfluxDB (TTN devices or legacy sensor_id)."""
        device_id = (
            request.query_params.get('device_id')
            or request.query_params.get('sensor_id')
            or 'lands-building'
        )
        hours = int(request.query_params.get('hours', 24))
        list_devices = request.query_params.get('list_devices', '').lower() in (
            '1', 'true', 'yes',
        )

        svc = InfluxDBService()
        try:
            payload = {
                'device_id': device_id,
                'hours': hours,
            }
            if list_devices:
                payload['devices'] = svc.list_devices(hours=hours)
            else:
                readings = svc.query_recent_readings(device_id, hours=hours)
                payload.update({
                    'count': len(readings),
                    'latest': svc.query_latest_reading(device_id),
                    'readings': readings,
                })
            return Response(payload)
        finally:
            svc.close()

    @action(detail=False, methods=['get'])
    def latest(self, request):
        """Get latest air quality data from all sensors."""
        sensors = Sensor.objects.filter(is_public=True, status='active')
        data = []

        for sensor in sensors:
            reading = sensor.readings.first()
            if reading:
                aqi_color = AQICalculator.get_color_for_aqi(reading.aqi or 0)
                
                air_quality_data = {
                    'sensor_id': sensor.sensor_id,
                    'sensor_name': sensor.name,
                    'location': sensor.location_name,
                    'latitude': sensor.latitude,
                    'longitude': sensor.longitude,
                    'timestamp': reading.timestamp,
                    'aqi': reading.aqi or 0,
                    'aqi_category': reading.aqi_category or 'unknown',
                    'color': aqi_color,
                    'co': reading.co,
                    'no2': reading.no2,
                    'benzene': reading.benzene,
                    'temperature': reading.temperature,
                    'humidity': reading.humidity,
                    'pressure': reading.pressure,
                }
                data.append(air_quality_data)

        return Response({
            'count': len(data),
            'timestamp': timezone.now(),
            'data': data,
        })

    @action(detail=False, methods=['get'])
    def history(self, request):
        """Get historical air quality data."""
        sensor_id = request.query_params.get('sensor_id')
        hours = int(request.query_params.get('hours', 24))

        if not sensor_id:
            return Response(
                {'detail': 'sensor_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            sensor = Sensor.objects.get(sensor_id=sensor_id)
        except Sensor.DoesNotExist:
            return Response(
                {'detail': 'Sensor not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        start_time = timezone.now() - timedelta(hours=hours)
        readings = sensor.readings.filter(timestamp__gte=start_time).order_by('-timestamp')

        data = []
        for reading in readings:
            aqi_color = AQICalculator.get_color_for_aqi(reading.aqi or 0)
            
            data.append({
                'timestamp': reading.timestamp,
                'aqi': reading.aqi or 0,
                'aqi_category': reading.aqi_category or 'unknown',
                'color': aqi_color,
                'co': reading.co,
                'no2': reading.no2,
                'benzene': reading.benzene,
                'temperature': reading.temperature,
                'humidity': reading.humidity,
            })

        return Response({
            'sensor_id': sensor_id,
            'sensor_name': sensor.name,
            'hours': hours,
            'count': len(data),
            'data': data,
        })

    @action(detail=False, methods=['get'])
    def prediction(self, request):
        """Get AQI prediction for future hours."""
        sensor_id = request.query_params.get('sensor_id')
        hours = int(request.query_params.get('hours', 12))
        model_type = request.query_params.get('model', 'moving_avg')

        if not sensor_id:
            return Response(
                {'detail': 'sensor_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            sensor = Sensor.objects.get(sensor_id=sensor_id)
        except Sensor.DoesNotExist:
            return Response(
                {'detail': 'Sensor not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get recent readings for prediction
        start_time = timezone.now() - timedelta(days=7)
        readings = sensor.readings.filter(
            timestamp__gte=start_time,
            is_valid=True
        ).order_by('timestamp').values_list('timestamp', 'aqi')

        if not readings:
            return Response(
                {'detail': 'Not enough historical data for prediction'},
                status=status.HTTP_204_NO_CONTENT
            )

        # Generate predictions
        predictions = PredictionService.predict_aqi(list(readings), model_type, hours)

        # Convert predictions to proper format
        prediction_data = []
        for pred in predictions:
            from airquality_api.utils.aqi_calculator import AQICalculator
            category = AQICalculator.get_category_from_aqi(pred['value'])
            color = AQICalculator.get_color_for_aqi(pred['value'])

            prediction_data.append({
                'timestamp': pred['timestamp'],
                'predicted_aqi': pred['value'],
                'category': category,
                'confidence': pred['confidence'],
                'color': color,
            })

        return Response({
            'sensor_id': sensor_id,
            'sensor_name': sensor.name,
            'model_type': model_type,
            'hours_ahead': hours,
            'predictions': prediction_data,
        })

    @action(detail=False, methods=['get'])
    def alerts(self, request):
        """Get active alerts."""
        alerts = Alert.objects.filter(is_active=True).order_by('-triggered_at')

        data = []
        for alert in alerts:
            data.append({
                'id': alert.id,
                'sensor_id': alert.sensor.sensor_id,
                'sensor_name': alert.sensor.name,
                'alert_type': alert.alert_type,
                'severity': alert.severity,
                'title': alert.title,
                'message': alert.message,
                'triggered_at': alert.triggered_at,
            })

        return Response({
            'count': len(data),
            'alerts': data,
        })

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def recommendations(self, request):
        """Get health recommendations based on user profile and current AQI."""
        sensor_id = request.query_params.get('sensor_id')

        if not sensor_id:
            return Response(
                {'detail': 'sensor_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            sensor = Sensor.objects.get(sensor_id=sensor_id)
        except Sensor.DoesNotExist:
            return Response(
                {'detail': 'Sensor not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get latest reading
        reading = sensor.readings.first()
        if not reading:
            return Response(
                {'detail': 'No air quality data available'},
                status=status.HTTP_204_NO_CONTENT
            )

        aqi = reading.aqi or 0

        # Get user profile for personalization
        user = request.user
        age_group = 'adult'
        health_conditions = []

        if hasattr(user, 'profile'):
            age_group = user.profile.age_group or 'adult'
            health_conditions = user.profile.health_conditions or []

        # Get recommendations
        recommendations = AQICalculator.get_recommendations(aqi, age_group, health_conditions)

        return Response({
            'sensor_id': sensor_id,
            'aqi': aqi,
            'recommendations': recommendations,
        })

    @action(detail=False, methods=['get'])
    def nearby_sensors(self, request):
        """Get nearby sensors based on coordinates."""
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')
        radius_km = float(request.query_params.get('radius', 5))

        if not latitude or not longitude:
            return Response(
                {'detail': 'latitude and longitude parameters are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            latitude = float(latitude)
            longitude = float(longitude)
        except ValueError:
            return Response(
                {'detail': 'Invalid latitude or longitude'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Simple distance calculation (Haversine formula)
        from math import radians, cos, sin, asin, sqrt

        def haversine(lon1, lat1, lon2, lat2):
            lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            return c * 6371

        sensors = Sensor.objects.filter(is_public=True, status='active')
        nearby = []

        for sensor in sensors:
            distance = haversine(longitude, latitude, sensor.longitude, sensor.latitude)
            if distance <= radius_km:
                reading = sensor.readings.first()
                nearby.append({
                    'sensor_id': sensor.sensor_id,
                    'name': sensor.name,
                    'location': sensor.location_name,
                    'latitude': sensor.latitude,
                    'longitude': sensor.longitude,
                    'distance_km': round(distance, 2),
                    'aqi': reading.aqi if reading else None,
                    'aqi_category': reading.aqi_category if reading else None,
                })

        nearby.sort(key=lambda x: x['distance_km'])

        return Response({
            'user_location': {
                'latitude': latitude,
                'longitude': longitude,
            },
            'radius_km': radius_km,
            'count': len(nearby),
            'sensors': nearby,
        })

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def subscribe_alerts(self, request):
        """Subscribe to alerts for a sensor."""
        sensor_id = request.data.get('sensor_id')
        alert_types = request.data.get('alert_types', ['high_aqi', 'unusual_pattern'])

        if not sensor_id:
            return Response(
                {'detail': 'sensor_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            sensor = Sensor.objects.get(sensor_id=sensor_id)
        except Sensor.DoesNotExist:
            return Response(
                {'detail': 'Sensor not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Store subscription in user profile (implementation depends on your needs)
        if hasattr(request.user, 'profile'):
            subscriptions = request.user.profile.health_conditions or []
            subscriptions.append({
                'sensor_id': sensor_id,
                'alert_types': alert_types,
            })
            request.user.profile.health_conditions = subscriptions
            request.user.profile.save()

        return Response({
            'message': 'Successfully subscribed to alerts',
            'sensor_id': sensor_id,
            'alert_types': alert_types,
        }, status=status.HTTP_201_CREATED)
