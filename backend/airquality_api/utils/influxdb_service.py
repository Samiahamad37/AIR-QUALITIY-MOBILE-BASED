import logging
import re
from datetime import datetime

from django.conf import settings
from influxdb_client import InfluxDBClient
from influxdb_client.client.write_api import SYNCHRONOUS

logger = logging.getLogger(__name__)

# TTN uplink topic: v3/{app}@ttn/devices/{device_id}/up
_TTN_TOPIC_DEVICE_RE = re.compile(r'/devices/([^/]+)/up$')

# Map TTN payload "name" tags to stable API keys (snake_case).
METRIC_ALIASES = {
    'temperature': 'temperature',
    'rawtemperature': 'raw_temperature',
    'humidity': 'humidity',
    'pressure': 'pressure',
    'co2': 'co2',
    'nox': 'nox',
    'voc': 'voc',
    'pm2.5': 'pm25',
    'pm10': 'pm10',
    'mq135_raw': 'mq135_raw',
    'airqualityscore': 'air_quality_score',
    'absolutehumidity': 'absolute_humidity',
    'batteryvoltage': 'battery_voltage',
    'batterypercentage': 'battery_percentage',
    'weathervibes': 'weather_vibes',
    'runinstatus': 'run_in_status',
}

# Pollutant query param -> TTN name tag (first match wins).
POLLUTANT_TO_TTN_NAME = {
    'co': 'CO',
    'co2': 'CO2',
    'no2': 'NOx',
    'nox': 'NOx',
    'benzene': 'VOC',
    'voc': 'VOC',
    'pm25': 'PM2.5',
    'pm2.5': 'PM2.5',
    'pm10': 'PM10',
    'aqi': 'AirQualityScore',
    'temperature': 'Temperature',
    'humidity': 'Humidity',
    'pressure': 'Pressure',
}


def extract_device_id_from_topic(topic: str) -> str | None:
    """Parse TTN device id from an uplink topic path."""
    if not topic:
        return None
    match = _TTN_TOPIC_DEVICE_RE.search(topic)
    return match.group(1) if match else None


def normalize_metric_key(name: str) -> str:
    """Convert a TTN metric name tag to a stable snake_case key."""
    if not name:
        return name
    lowered = name.strip().lower().replace(' ', '_')
    return METRIC_ALIASES.get(lowered, lowered)


def _flux_string_literal(value: str) -> str:
    """Escape a string for use inside a Flux double-quoted literal."""
    return value.replace('\\', '\\\\').replace('"', '\\"')


class InfluxDBService:
    """Service for InfluxDB operations (legacy writes + TTN line-protocol reads)."""

    MEASUREMENT = 'air_quality'

    def __init__(self):
        config = settings.INFLUXDB_CONFIG
        self.client = InfluxDBClient(
            url=config['url'],
            token=config['token'],
            org=config['org'],
        )
        self.bucket = config['bucket']
        self.org = config['org']
        self._write_api = self.client.write_api(write_options=SYNCHRONOUS)

    # --- TTN topic helpers ---

    @staticmethod
    def device_topic_substr(device_id: str) -> str:
        """Substring that identifies a TTN device's uplink topic."""
        return f'/devices/{device_id}/up'

    def _flux_strings_import(self) -> str:
        return 'import "strings"\n\n'

    def _device_topic_filter(self, device_id: str) -> str:
        # Avoid Flux /regex/ literals — paths contain slashes and break parsing.
        substr = _flux_string_literal(self.device_topic_substr(device_id))
        return (
            f'|> filter(fn: (r) => exists r.topic and '
            f'strings.containsStr(v: r.topic, substr: "{substr}"))'
        )

    # --- Write (legacy flat schema with sensor_id tag) ---

    def write_sensor_reading(
        self,
        sensor_id,
        co=None,
        no2=None,
        benzene=None,
        temperature=None,
        humidity=None,
        pressure=None,
        wind_speed=None,
        aqi=None,
        timestamp=None,
    ):
        """Write sensor reading using the legacy sensor_id-tagged schema."""
        try:
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
                'measurement': self.MEASUREMENT,
                'tags': {'sensor_id': str(sensor_id)},
                'fields': fields,
                'time': timestamp or datetime.utcnow(),
            }

            self._write_api.write(bucket=self.bucket, org=self.org, record=point)
            logger.info('Wrote reading for sensor %s to InfluxDB', sensor_id)

        except Exception as e:
            logger.error('Error writing to InfluxDB: %s', e)
            raise

    # --- Query primitives ---

    def _run_flux(self, flux_query):
        """Execute a Flux query and return raw tables."""
        query_api = self.client.query_api()
        return query_api.query(org=self.org, query=flux_query)

    def _pivot_legacy_readings(self, result):
        """Turn pivoted legacy Flux tables into reading dicts (sensor_id tag)."""
        readings = []
        for table in result:
            for record in table.records:
                row = {'timestamp': record.get_time()}
                for key, value in record.values.items():
                    if key in ('result', 'table', '_start', '_stop', '_time', '_measurement'):
                        continue
                    if key.startswith('_') or key == 'sensor_id':
                        continue
                    row[key] = value
                if len(row) > 1:
                    readings.append(row)
        return readings

    def _pivot_ttn_readings(self, result, device_id=None):
        """Turn TTN pivoted tables (columns = metric names) into reading dicts."""
        readings = []
        skip = {
            'result', 'table', '_start', '_stop', '_time', '_measurement',
            'topic', 'name', 'sensor_id',
        }
        for table in result:
            for record in table.records:
                row = {
                    'timestamp': record.get_time(),
                    'device_id': device_id,
                }
                units = {}
                for key, value in record.values.items():
                    if key in skip or key.startswith('_'):
                        continue
                    if key.endswith('_unit'):
                        units[key[:-5]] = value
                        continue
                    row[normalize_metric_key(key)] = value
                if units:
                    row['units'] = {normalize_metric_key(k): v for k, v in units.items()}
                if len(row) > 2 or (len(row) == 2 and 'device_id' not in row):
                    readings.append(row)
                elif len(row) == 2 and device_id:
                    readings.append(row)
        return readings

    def list_devices(self, hours=24 * 7):
        """List TTN device ids seen in the bucket (from topic tags)."""
        try:
            flux_query = f'''
                from(bucket: "{self.bucket}")
                  |> range(start: -{int(hours)}h)
                  |> filter(fn: (r) => r._measurement == "{self.MEASUREMENT}")
                  |> keep(columns: ["topic"])
                  |> distinct(column: "topic")
            '''
            devices = set()
            for table in self._run_flux(flux_query):
                for record in table.records:
                    topic = record.values.get('topic')
                    device_id = extract_device_id_from_topic(topic)
                    if device_id:
                        devices.add(device_id)
            return sorted(devices)
        except Exception as e:
            logger.error('Error listing TTN devices: %s', e)
            return []

    def query_ttn_recent_readings(self, device_id, hours=24, limit=None):
        """
        Fetch recent TTN uplinks for a device.

        Each row is one uplink timestamp with metrics pivoted from the ``name`` tag
        (Temperature, PM2.5, CO2, etc.).
        """
        try:
            limit_clause = f'\n  |> limit(n: {int(limit)})' if limit else ''
            flux_query = f'''{self._flux_strings_import()}from(bucket: "{self.bucket}")
                  |> range(start: -{int(hours)}h)
                  |> filter(fn: (r) => r._measurement == "{self.MEASUREMENT}")
                  {self._device_topic_filter(device_id)}
                  |> filter(fn: (r) => r._field == "value")
                  |> pivot(rowKey: ["_time"], columnKey: ["name"], valueColumn: "_value")
                  |> sort(columns: ["_time"], desc: true){limit_clause}
            '''
            return self._pivot_ttn_readings(self._run_flux(flux_query), device_id=device_id)
        except Exception as e:
            logger.error('Error querying TTN readings for %s: %s', device_id, e)
            return []

    def query_ttn_latest_reading(self, device_id, hours=24):
        """Most recent TTN uplink for a device."""
        readings = self.query_ttn_recent_readings(device_id, hours=hours, limit=1)
        return readings[0] if readings else None

    def query_ttn_metric_history(self, device_id, metric_name, hours=168):
        """Time series for one TTN metric (by ``name`` tag)."""
        name_literal = _flux_string_literal(metric_name)
        try:
            flux_query = f'''{self._flux_strings_import()}from(bucket: "{self.bucket}")
                  |> range(start: -{int(hours)}h)
                  |> filter(fn: (r) => r._measurement == "{self.MEASUREMENT}")
                  {self._device_topic_filter(device_id)}
                  |> filter(fn: (r) => r._field == "value")
                  |> filter(fn: (r) => r.name == "{name_literal}")
                  |> sort(columns: ["_time"])
            '''
            history = []
            for table in self._run_flux(flux_query):
                for record in table.records:
                    history.append({
                        'timestamp': record.get_time(),
                        'value': record.get_value(),
                        'metric': metric_name,
                        'device_id': device_id,
                    })
            return history
        except Exception as e:
            logger.error(
                'Error querying TTN metric %s for %s: %s', metric_name, device_id, e
            )
            return []

    # --- Unified API (TTN first, then legacy sensor_id tag) ---

    def query_recent_readings(self, sensor_id, hours=24, limit=None):
        """Recent readings: TTN device id in topic, else legacy sensor_id tag."""
        ttn = self.query_ttn_recent_readings(sensor_id, hours=hours, limit=limit)
        if ttn:
            return ttn
        return self._query_legacy_recent_readings(sensor_id, hours=hours)

    def query_latest_reading(self, sensor_id, hours=24 * 7):
        """Latest reading for a TTN device id or legacy sensor_id."""
        latest = self.query_ttn_latest_reading(sensor_id, hours=hours)
        if latest:
            return latest
        readings = self._query_legacy_recent_readings(sensor_id, hours=hours)
        return readings[0] if readings else None

    def query_aqi_history(self, sensor_id, hours=7 * 24):
        """AQI / air-quality score history (TTN AirQualityScore or legacy aqi field)."""
        ttn_name = POLLUTANT_TO_TTN_NAME.get('aqi', 'AirQualityScore')
        history = self.query_ttn_metric_history(sensor_id, ttn_name, hours=hours)
        if history:
            return [
                {'timestamp': p['timestamp'], 'aqi': p['value']}
                for p in history
            ]
        return self._query_legacy_pollutant_history(sensor_id, 'aqi', hours=hours, key='aqi')

    def query_pollutant_data(self, sensor_id, pollutant, hours=168):
        """Pollutant time series (maps API names to TTN ``name`` tags when possible)."""
        field = pollutant.lower()
        ttn_name = POLLUTANT_TO_TTN_NAME.get(field, pollutant)
        history = self.query_ttn_metric_history(sensor_id, ttn_name, hours=hours)
        if history:
            return [
                {'timestamp': p['timestamp'], 'value': p['value']}
                for p in history
            ]
        return self._query_legacy_pollutant_history(
            sensor_id, field, hours=hours, key='value'
        )

    # --- Legacy query paths ---

    def _query_legacy_recent_readings(self, sensor_id, hours=24):
        try:
            sid = _flux_string_literal(str(sensor_id))
            flux_query = f'''
                from(bucket: "{self.bucket}")
                  |> range(start: -{int(hours)}h)
                  |> filter(fn: (r) => r._measurement == "{self.MEASUREMENT}")
                  |> filter(fn: (r) => r["sensor_id"] == "{sid}")
                  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
                  |> sort(columns: ["_time"], desc: true)
            '''
            return self._pivot_legacy_readings(self._run_flux(flux_query))
        except Exception as e:
            logger.error('Error querying legacy InfluxDB readings: %s', e)
            return []

    def _query_legacy_pollutant_history(self, sensor_id, field, hours=168, key='value'):
        try:
            sid = _flux_string_literal(str(sensor_id))
            field_lit = _flux_string_literal(field)
            flux_query = f'''
                from(bucket: "{self.bucket}")
                  |> range(start: -{int(hours)}h)
                  |> filter(fn: (r) => r._measurement == "{self.MEASUREMENT}")
                  |> filter(fn: (r) => r["sensor_id"] == "{sid}")
                  |> filter(fn: (r) => r._field == "{field_lit}")
                  |> sort(columns: ["_time"])
            '''
            data = []
            for table in self._run_flux(flux_query):
                for record in table.records:
                    data.append({
                        'timestamp': record.get_time(),
                        key: record.get_value(),
                    })
            return data
        except Exception as e:
            logger.error('Error querying legacy %s data: %s', field, e)
            return []

    def close(self):
        """Close InfluxDB connection."""
        if getattr(self, '_write_api', None) is not None:
            self._write_api.close()
            self._write_api = None
        self.client.close()
