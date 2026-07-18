from django.urls import path
from .views import AirQualityAPIViewSet

urlpatterns = [
    path('devices/', AirQualityAPIViewSet.as_view({'get': 'devices'}), name='devices'),
    path('device/latest/', AirQualityAPIViewSet.as_view({'get': 'device_latest'}), name='device-latest'),
    path('latest/', AirQualityAPIViewSet.as_view({'get': 'latest'}), name='latest'),
    path('device/readings/', AirQualityAPIViewSet.as_view({'get': 'device_readings'}), name='device-readings'),
    path('device/history/', AirQualityAPIViewSet.as_view({'get': 'device_history'}), name='device-history'),
    path('history/', AirQualityAPIViewSet.as_view({'get': 'device_history'}), name='history'),
    path('device/pollutants/', AirQualityAPIViewSet.as_view({'get': 'device_all_pollutants'}), name='device-all-pollutants'),
    path('device/aqi/', AirQualityAPIViewSet.as_view({'get': 'device_aqi'}), name='device-aqi'),
    path('predict/all/', AirQualityAPIViewSet.as_view({'get': 'predict_all'}), name='predict-all'),
    path('recommend/', AirQualityAPIViewSet.as_view({'get': 'recommend'}), name='recommend'),
    path('nearby-sensors/', AirQualityAPIViewSet.as_view({'get': 'nearby_sensors'}), name='nearby-sensors'),
    path('alerts/', AirQualityAPIViewSet.as_view({'get': 'alerts'}), name='alerts'),
    
]