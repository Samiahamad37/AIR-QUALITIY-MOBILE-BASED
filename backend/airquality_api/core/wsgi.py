"""
WSGI config for airquality_api project.
"""
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'airquality_api.core.settings')
application = get_wsgi_application()
