from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from datetime import timedelta
from .models import Sensor, SensorReading, AQIPrediction, Alert
from .serializers import SensorSerializer, SensorReadingSerializer, AQIPredictionSerializer, AlertSerializer
import math


class SensorViewSet(viewsets.ReadOnlyModelViewSet):
    """Sensor viewset - read-only for mobile app."""
    queryset = Sensor.objects.filter(is_public=True, status='active')
    serializer_class = SensorSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['status', 'sensor_type', 'location_name']
    search_fields = ['name', 'location_name', 'sensor_id']

    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def latest_reading(self, request, pk=None):
        """Get latest reading from a sensor."""
        sensor = self.get_object()
        # reading = sensor.readings.first()
        reading = sensor.readings.order_by('-timestamp').first()
        if reading:
            serializer = SensorReadingSerializer(reading)
            return Response(serializer.data)
        return Response({'detail': 'No readings available'}, status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def recent_readings(self, request, pk=None):
        """Get recent readings from a sensor (last 24 hours)."""
        sensor = self.get_object()
        hours = int(request.query_params.get('hours', 24))
        start_time = timezone.now() - timedelta(hours=hours)
        
        readings = sensor.readings.filter(timestamp__gte=start_time).order_by('-timestamp')
        serializer = SensorReadingSerializer(readings, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def nearest(self, request):
        """Find nearest sensor based on user's location."""
        lat = request.query_params.get('lat')
        lng = request.query_params.get('lng')
        
        if not lat or not lng:
            return Response(
                {'detail': 'lat and lng parameters are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user_lat = float(lat)
            user_lng = float(lng)
        except ValueError:
            return Response(
                {'detail': 'Invalid latitude or longitude values.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        sensors = self.get_queryset()
        
        def calculate_distance(sensor_lat, sensor_lng):
            """Calculate distance using Haversine formula."""
            R = 6371  # Earth's radius in km
            lat1, lon1 = math.radians(user_lat), math.radians(user_lng)
            lat2, lon2 = math.radians(sensor_lat), math.radians(sensor_lng)
            
            dlat = lat2 - lat1
            dlon = lon2 - lon1
            
            a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            
            return R * c
        
        sensors_with_distance = []
        for sensor in sensors:
            distance = calculate_distance(sensor.latitude, sensor.longitude)
            sensors_with_distance.append({
                'sensor': SensorSerializer(sensor).data,
                'distance_km': round(distance, 2)
            })
        
        sensors_with_distance.sort(key=lambda x: x['distance_km'])
        
        return Response({
            'sensors': sensors_with_distance,
            'nearest': sensors_with_distance[0] if sensors_with_distance else None
        })


class SensorReadingViewSet(viewsets.ReadOnlyModelViewSet):
    """Sensor readings viewset."""
    queryset = SensorReading.objects.all()
    serializer_class = SensorReadingSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['sensor', 'timestamp', 'is_valid']
    ordering_fields = ['timestamp']
    ordering = ['-timestamp']

    def get_queryset(self):
        queryset = super().get_queryset()
        sensor_id = self.request.query_params.get('sensor_id')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')

        if sensor_id:
            queryset = queryset.filter(sensor_id=sensor_id)
        if start_date:
            queryset = queryset.filter(timestamp__gte=start_date)
        if end_date:
            queryset = queryset.filter(timestamp__lte=end_date)

        return queryset


class AQIPredictionViewSet(viewsets.ReadOnlyModelViewSet):
    """AQI predictions viewset."""
    queryset = AQIPrediction.objects.all()
    serializer_class = AQIPredictionSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['sensor', 'model_type']

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def next_predictions(self, request):
        """Get next 12 hour predictions for all sensors."""
        sensor_id = request.query_params.get('sensor_id')
        hours = int(request.query_params.get('hours', 12))
        
        queryset = self.get_queryset()
        if sensor_id:
            queryset = queryset.filter(sensor_id=sensor_id)
        
        now = timezone.now()
        future = now + timedelta(hours=hours)
        queryset = queryset.filter(prediction_time__gte=now, prediction_time__lte=future).order_by('prediction_time')
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class AlertViewSet(viewsets.ReadOnlyModelViewSet):
    """Alerts viewset."""
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['sensor', 'alert_type', 'severity', 'is_active']
    ordering_fields = ['triggered_at']
    ordering = ['-triggered_at']

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def active_alerts(self, request):
        """Get active alerts only."""
        queryset = self.get_queryset().filter(is_active=True)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def critical_alerts(self, request):
        """Get critical alerts."""
        queryset = self.get_queryset().filter(is_active=True, severity='critical')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
