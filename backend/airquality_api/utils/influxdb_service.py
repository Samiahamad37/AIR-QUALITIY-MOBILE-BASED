"""
InfluxDB Interface Module

Handles time-series data storage and retrieval from InfluxDB
"""

from influxdb_client import InfluxDBClient
from influxdb_client.client.write_api import SYNCHRONOUS
from django.conf import settings
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class InfluxDBService:
    """Service for InfluxDB operations."""

    def __init__(self):
        config = settings.INFLUXDB_CONFIG
        self.client = InfluxDBClient(
            url=config['url'],
            token=config['token'],
            org=config['org']
        )
        self.bucket = config['bucket']
        self.org = config['org']

    def write_sensor_reading(self, sensor_id, co=None, no2=None, benzene=None, 
                            temperature=None, humidity=None, pressure=None,
                            wind_speed=None, aqi=None, timestamp=None):
        """Write sensor reading to InfluxDB."""
        try:
            write_api = self.client.write_api(write_client=SYNCHRONOUS)

            fields = {}
            if co is not None:
                fields['co'] = float(co)
            if no2 is not None:
                fields['no2'] = float(no2)
            if benzene is not None:
                fields['benzene'] = float(benzene)
            if temperature is not None:
                fields['temperature'] = float(temperature)
            if humidity is not None:
                fields['humidity'] = float(humidity)
            if pressure is not None:
                fields['pressure'] = float(pressure)
            if wind_speed is not None:
                fields['wind_speed'] = float(wind_speed)
            if aqi is not None:
                fields['aqi'] = int(aqi)

            point = {
                'measurement': 'air_quality',
                'tags': {'sensor_id': str(sensor_id)},
                'fields': fields,
                'time': timestamp or datetime.utcnow(),
            }

            write_api.write(bucket=self.bucket, org=self.org, record=point)
            logger.info(f"Wrote reading for sensor {sensor_id} to InfluxDB")

        except Exception as e:
            logger.error(f"Error writing to InfluxDB: {str(e)}")
            raise

    def query_recent_readings(self, sensor_id, hours=24):
        """Query recent readings for a sensor."""
        try:
            query_api = self.client.query_api()
            query = f'''
                from(bucket:"{self.bucket}")
                |> range(start: -{hours}h)
                |> filter(fn: (r) => r._measurement == "air_quality")
                |> filter(fn: (r) => r.sensor_id == "{sensor_id}")
                |> sort(columns: ["_time"], desc: true)
            '''

            result = query_api.query(org=self.org, query=query)

            readings = []
            for table in result:
                for record in table.records:
                    readings.append({
                        'time': record.get_time(),
                        'field': record.get_field(),
                        'value': record.get_value(),
                    })

            return readings

        except Exception as e:
            logger.error(f"Error querying InfluxDB: {str(e)}")
            return []

    def query_aqi_history(self, sensor_id, hours=7*24):
        """Query AQI history for a sensor."""
        try:
            query_api = self.client.query_api()
            query = f'''
                from(bucket:"{self.bucket}")
                |> range(start: -{hours}h)
                |> filter(fn: (r) => r._measurement == "air_quality")
                |> filter(fn: (r) => r.sensor_id == "{sensor_id}")
                |> filter(fn: (r) => r._field == "aqi")
                |> sort(columns: ["_time"])
            '''

            result = query_api.query(org=self.org, query=query)

            history = []
            for table in result:
                for record in table.records:
                    history.append({
                        'timestamp': record.get_time(),
                        'aqi': record.get_value(),
                    })

            return history

        except Exception as e:
            logger.error(f"Error querying AQI history: {str(e)}")
            return []

    def query_pollutant_data(self, sensor_id, pollutant, hours=168):
        """Query specific pollutant data."""
        try:
            query_api = self.client.query_api()
            query = f'''
                from(bucket:"{self.bucket}")
                |> range(start: -{hours}h)
                |> filter(fn: (r) => r._measurement == "air_quality")
                |> filter(fn: (r) => r.sensor_id == "{sensor_id}")
                |> filter(fn: (r) => r._field == "{pollutant.lower()}")
                |> sort(columns: ["_time"])
            '''

            result = query_api.query(org=self.org, query=query)

            data = []
            for table in result:
                for record in table.records:
                    data.append({
                        'timestamp': record.get_time(),
                        'value': record.get_value(),
                    })

            return data

        except Exception as e:
            logger.error(f"Error querying {pollutant} data: {str(e)}")
            return []

    def close(self):
        """Close InfluxDB connection."""
        self.client.close()
