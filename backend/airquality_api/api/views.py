from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from airquality_api.utils.influxdb_service import InfluxDBService
from rest_framework.permissions import AllowAny


ALLOWED_DEVICES = ['lands-building', 'planing-building']
ALLOWED_POLLUTANTS = ['co2', 'nox', 'voc', 'pm25', 'pm10']


class AirQualityAPIViewSet(viewsets.ViewSet):
    """Air quality API endpoints for mobile app."""
    permission_classes = [AllowAny]

    @action(detail=False, methods=['get'])
    def devices(self, request):
        """List available TTN devices."""
        return Response({'devices': ALLOWED_DEVICES})

    @action(detail=False, methods=['get'])
    def device_latest(self, request):
        """Latest reading for a device including all pollutants."""
        device_id = request.query_params.get('device_id')
        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
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
    def device_readings(self, request):
        """Recent readings for a device."""
        device_id = request.query_params.get('device_id')
        hours = int(request.query_params.get('hours', 24))
        limit = request.query_params.get('limit')
        limit = int(limit) if limit else None

        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if device_id not in ALLOWED_DEVICES:
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
        device_id = request.query_params.get('device_id')
        pollutant = request.query_params.get('pollutant')
        hours = int(request.query_params.get('hours', 24))

        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if not pollutant:
            return Response(
                {'detail': 'pollutant is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if device_id not in ALLOWED_DEVICES:
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

        return Response({
            'device_id': device_id,
            'pollutant': pollutant,
            'hours': hours,
            'count': len(data),
            'data': data,
        })

    @action(detail=False, methods=['get'])
    def device_all_pollutants(self, request):
        """History of all pollutants for a device in one call."""
        device_id = request.query_params.get('device_id')
        hours = int(request.query_params.get('hours', 24))

        if not device_id:
            return Response(
                {'detail': 'device_id is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if device_id not in ALLOWED_DEVICES:
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