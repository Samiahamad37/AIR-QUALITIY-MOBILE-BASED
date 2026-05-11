from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SensorViewSet, SensorReadingViewSet, AQIPredictionViewSet, AlertViewSet

router = DefaultRouter()
router.register(r'sensors', SensorViewSet, basename='sensor')
router.register(r'readings', SensorReadingViewSet, basename='sensor-reading')
router.register(r'predictions', AQIPredictionViewSet, basename='aqi-prediction')
router.register(r'alerts', AlertViewSet, basename='alert')

urlpatterns = [
    path('', include(router.urls)),
]
