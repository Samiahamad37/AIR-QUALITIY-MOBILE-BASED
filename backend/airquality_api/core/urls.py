"""
URL configuration for airquality_api.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from airquality_api.api.views import AirQualityAPIViewSet

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('airquality_api.users.urls')),
    path('api/sensors/', include('airquality_api.sensors.urls')),
    path('api/air-quality/', include('airquality_api.api.urls')),
    path('api/predict/all', AirQualityAPIViewSet.as_view({'get': 'predict_all'}), name='predict-all'),
    path('api/predict/all/', AirQualityAPIViewSet.as_view({'get': 'predict_all'}), name='predict-all-slash'),
    path('api/recommend', AirQualityAPIViewSet.as_view({'get': 'recommend'}), name='recommend-plain'),
    path('api/recommend/', AirQualityAPIViewSet.as_view({'get': 'recommend'}), name='recommend'),
    path('api/history/sensor', AirQualityAPIViewSet.as_view({'get': 'history_sensor'}), name='history-sensor'),
    path('api/history/sensor/', AirQualityAPIViewSet.as_view({'get': 'history_sensor'}), name='history-sensor-slash'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
