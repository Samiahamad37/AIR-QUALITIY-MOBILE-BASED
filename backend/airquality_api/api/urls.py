from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AirQualityAPIViewSet

router = DefaultRouter()
router.register(r'', AirQualityAPIViewSet, basename='air-quality')

urlpatterns = [
    path('influx/', AirQualityAPIViewSet.as_view({'get': 'influx'}), name='influx-readings'),
    path('latest/', AirQualityAPIViewSet.as_view({'get': 'latest'}), name='latest-air-quality'),
    path('history/', AirQualityAPIViewSet.as_view({'get': 'history'}), name='air-quality-history'),
    path('prediction/', AirQualityAPIViewSet.as_view({'get': 'prediction'}), name='aqi-prediction'),
    path('alerts/', AirQualityAPIViewSet.as_view({'get': 'alerts'}), name='active-alerts'),
    path('recommendations/', AirQualityAPIViewSet.as_view({'get': 'recommendations'}), name='health-recommendations'),
    path('nearby-sensors/', AirQualityAPIViewSet.as_view({'get': 'nearby_sensors'}), name='nearby-sensors'),
    path('subscribe-alerts/', AirQualityAPIViewSet.as_view({'post': 'subscribe_alerts'}), name='subscribe-alerts'),
]
