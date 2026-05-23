"""
InfluxDB TTN fetch test.

Run from backend folder:
    py -3 airquality_api/utils/test.py
"""
import json
import os
import sys
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BACKEND_DIR))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'airquality_api.core.settings')

import django

django.setup()

from airquality_api.utils.influxdb_service import InfluxDBService


def test_influxdb_service():
    svc = InfluxDBService()
    try:
        devices = svc.list_devices(hours=24)
        print('TTN devices (24h):', devices)

        device_id = devices[0] if devices else 'lands-building'
        latest = svc.query_ttn_latest_reading(device_id)
        print(f'Latest ({device_id}):', json.dumps(latest, default=str, indent=2))

        readings = svc.query_ttn_recent_readings(device_id, hours=6, limit=3)
        print(f'Recent count ({device_id}):', len(readings))

        co2_device = 'lands-building' if 'lands-building' in devices else device_id
        co2 = svc.query_ttn_metric_history(co2_device, 'CO2', hours=6)
        print(f'CO2 points ({co2_device}):', len(co2))
    finally:
        svc.close()


if __name__ == '__main__':
    test_influxdb_service()
