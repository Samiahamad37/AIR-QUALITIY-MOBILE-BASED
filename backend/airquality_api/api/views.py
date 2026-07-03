from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from airquality_api.utils.influxdb_service import InfluxDBService
from airquality_api.utils.aqi_calculator import AQICalculator
from airquality_api.utils.prediction import PredictionService
from airquality_api.utils.external_api import ExternalAPIService
from rest_framework.permissions import AllowAny
from airquality_api.sensors.models import Sensor


ALLOWED_DEVICES = ['lands-building', 'planing-building']
ALLOWED_POLLUTANTS = ['aqi', 'co2', 'nox', 'voc', 'pm25', 'pm10']


class AirQualityAPIViewSet(viewsets.ViewSet):
    """Air quality API endpoints for mobile app."""
    permission_classes = [AllowAny]

    @staticmethod
    def _get_device_id(request):
        return request.query_params.get('device_id') or request.query_params.get('sensor_id') or request.query_params.get('id')

    @classmethod
    def _validate_device_id(cls, request):
        device_id = cls._get_device_id(request)
        if not device_id:
            return None, None
        if device_id in ALLOWED_DEVICES:
            return device_id, 'device'
        if Sensor.objects.filter(sensor_id=device_id).exists():
            return device_id, 'sensor'
        return None, None

    @staticmethod
    def _get_aqi_payload(reading):
        no2_value = reading.get('no2') if reading.get('no2') is not None else reading.get('nox')
        aqi, category = AQICalculator.calculate_overall_aqi(
            no2=no2_value,
            pm25=reading.get('pm25'),
        )
        return {
            'aqi': aqi,
            'category': category,
            'color': AQICalculator.get_color_for_aqi(aqi or 0),
            'recommendations': AQICalculator.get_recommendations(aqi or 0),
        }

    @action(detail=False, methods=['get'])
    def devices(self, request):
        """List available TTN devices."""
        return Response({'devices': ALLOWED_DEVICES})

    def _latest_reading_response(self, device_id):
        if not device_id:
            device_id = ALLOWED_DEVICES[0]
        if device_id not in ALLOWED_DEVICES:
            return Response(
                {'detail': 'Device not found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        svc = InfluxDBService()
        try:
            reading = svc.query_latest_reading(device_id)
        finally:
            svc.close()

        if not reading:
            return Response(
                {'detail': 'No data found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        pollutants = {k: reading[k] for k in ALLOWED_POLLUTANTS if k in reading}
        return Response({
            'device_id': device_id,
            'timestamp': reading['timestamp'],
            'pollutants': pollutants,
            'temperature': reading.get('temperature'),
            'humidity': reading.get('humidity'),
            'pressure': reading.get('pressure'),
        })

    @action(detail=False, methods=['get'])
    def device_latest(self, request):
        """Latest reading for a device including all pollutants."""
        device_id = self._get_device_id(request)
        return self._latest_reading_response(device_id)

    @action(detail=False, methods=['get'])
    def latest(self, request):
        """Latest reading for the default device when no device_id is supplied."""
        device_id = self._get_device_id(request) or ALLOWED_DEVICES[0]
        return self._latest_reading_response(device_id)

    @action(detail=False, methods=['get'])
    def device_readings(self, request):
        """Recent readings for a device."""
        device_id = self._get_device_id(request)
        hours = int(request.query_params.get('hours', 24))
        limit = request.query_params.get('limit')
        limit = int(limit) if limit else None

        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if device_id not in ALLOWED_DEVICES and not Sensor.objects.filter(sensor_id=device_id).exists():
            return Response(
                {'detail': 'Device not found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        svc = InfluxDBService()
        try:
            readings = svc.query_recent_readings(device_id, hours=hours, limit=limit)
        finally:
            svc.close()

        return Response({
            'device_id': device_id,
            'hours': hours,
            'count': len(readings),
            'readings': readings,
        })

    @action(detail=False, methods=['get'])
    def device_history(self, request):
        """Time series for a single pollutant."""
        device_id = self._get_device_id(request)
        pollutant = request.query_params.get('pollutant') or 'aqi'
        hours = int(request.query_params.get('hours', 24))

        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if device_id not in ALLOWED_DEVICES and not Sensor.objects.filter(sensor_id=device_id).exists():
            return Response(
                {'detail': 'Device not found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        if pollutant not in ALLOWED_POLLUTANTS:
            return Response(
                {'detail': f'pollutant must be one of {ALLOWED_POLLUTANTS}.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        svc = InfluxDBService()
        try:
            data = svc.query_pollutant_data(device_id, pollutant, hours=hours)
        finally:
            svc.close()

        return Response({'data': data})

    @action(detail=False, methods=['get'])
    def device_all_pollutants(self, request):
        """History of all pollutants for a device in one call."""
        device_id = self._get_device_id(request)
        hours = int(request.query_params.get('hours', 24))

        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if device_id not in ALLOWED_DEVICES and not Sensor.objects.filter(sensor_id=device_id).exists():
            return Response(
                {'detail': 'Device not found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        svc = InfluxDBService()
        try:
            result = {
                p: svc.query_pollutant_data(device_id, p, hours=hours)
                for p in ALLOWED_POLLUTANTS
            }
        finally:
            svc.close()

        return Response({
            'device_id': device_id,
            'hours': hours,
            'pollutants': result,
        })
    @action(detail=False, methods=['get'])
    def device_aqi(self, request):
        """Real-time AQI calculated from latest device reading."""
        device_id = self._get_device_id(request)

        if not device_id:
           return Response({'detail': 'device_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if device_id not in ALLOWED_DEVICES and not Sensor.objects.filter(sensor_id=device_id).exists():
           return Response({'detail': 'Device not found.'}, status=status.HTTP_404_NOT_FOUND)

        svc = InfluxDBService()
        try:
           reading = svc.query_latest_reading(device_id)
        finally:
          svc.close()

        if not reading:
            return Response({'detail': 'No data found.'}, status=status.HTTP_404_NOT_FOUND)

        aqi_payload = self._get_aqi_payload(reading)

        return Response({
            'device_id': device_id,
            'timestamp': reading['timestamp'],
            'aqi': aqi_payload['aqi'],
            'category': aqi_payload['category'],
            'color': aqi_payload['color'],
            'recommendations': aqi_payload['recommendations'],
            'pollutants': {
                'co2': reading.get('co2'),
                'nox': reading.get('nox'),
                'voc': reading.get('voc'),
                'pm25': reading.get('pm25'),
                'pm10': reading.get('pm10'),
            },
            'environment': {
                'temperature': reading.get('temperature'),
                'humidity': reading.get('humidity'),
                'pressure': reading.get('pressure'),
            }
        })

    @action(detail=False, methods=['get'])
    def predict_all(self, request):
        """Return 6-hour air quality predictions from external forecast API."""
        external_data = ExternalAPIService.get_predictions()
        
        if external_data is None:
            return Response(
                {'detail': 'Unable to fetch predictions from external API.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        return Response(external_data)

    @action(detail=False, methods=['get'])
    def recommend(self, request):
        """Return AI-generated health recommendations from external API."""
        external_data = ExternalAPIService.get_recommendations()
        
        if external_data is None:
            return Response(
                {'detail': 'Unable to fetch recommendations from external API.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        return Response(external_data)

    @action(detail=False, methods=['get'])
    def history_sensor(self, request):
        """Return recent sensor readings for a device."""
        device_id = self._get_device_id(request)
        if not device_id:
            return Response({'detail': 'device_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if device_id not in ALLOWED_DEVICES and not Sensor.objects.filter(sensor_id=device_id).exists():
            return Response({'detail': 'Device not found.'}, status=status.HTTP_404_NOT_FOUND)

        hours = int(request.query_params.get('hours', 24))
        limit = request.query_params.get('limit')
        limit = int(limit) if limit else None

        svc = InfluxDBService()
        try:
            readings = svc.query_recent_readings(device_id, hours=hours, limit=limit)
        finally:
            svc.close()

        return Response({
            'device_id': device_id,
            'hours': hours,
            'count': len(readings),
            'readings': readings,
        })

    @action(detail=False, methods=['get'])
    def nearby_sensors(self, request):
        """Compatibility route for nearby-sensors requests."""
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')
        radius = request.query_params.get('radius', 10)

        if not latitude or not longitude:
            return Response({'detail': 'latitude and longitude are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            latitude = float(latitude)
            longitude = float(longitude)
            radius = float(radius)
        except ValueError:
            return Response({'detail': 'Invalid location values.'}, status=status.HTTP_400_BAD_REQUEST)

        sensors = []
        for device_id in ALLOWED_DEVICES:
            sensors.append({
                'device_id': device_id,
                'latitude': latitude,
                'longitude': longitude,
                'distance_km': 0.0,
            })

        return Response({'sensors': sensors, 'nearest': sensors[0] if sensors else None, 'radius_km': radius})

    @action(detail=False, methods=['get'])
    def alerts(self, request):
        """Compatibility route for alerts requests."""
        return Response({'alerts': []})