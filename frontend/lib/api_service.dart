import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Config ───────────────────────────────────────────────────────────────────
// Android emulator  → 10.0.2.2:8000
// iOS simulator     → 127.0.0.1:8000
// Real device       → your machine's local IP e.g. 192.168.1.5:8000

const String _baseUrl      = 'http://10.0.2.2:8000/api/v1';
const int defaultStationId = 1;
const Duration _timeout    = Duration(seconds: 15);

// ─── Exception ────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─── HTTP helpers ─────────────────────────────────────────────────────────────

Future<dynamic> _get(String path, [Map<String, String>? params]) async {
  final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
  final res = await http
      .get(uri, headers: {'Accept': 'application/json'})
      .timeout(_timeout);

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return jsonDecode(res.body);
  }

  dynamic body;
  try {
    body = jsonDecode(res.body);
  } catch (_) {
    body = {'error': res.reasonPhrase ?? 'Unknown error'};
  }
  throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
}

Future<dynamic> _post(String path, Map<String, dynamic> payload) async {
  final uri = Uri.parse('$_baseUrl$path');
  final res = await http
      .post(uri,
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          body: jsonEncode(payload))
      .timeout(_timeout);

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return jsonDecode(res.body);
  }

  dynamic body;
  try {
    body = jsonDecode(res.body);
  } catch (_) {
    body = {'error': res.reasonPhrase ?? 'Unknown error'};
  }
  throw ApiException(res.statusCode, body['error'] ?? 'Unknown error');
}

// ─── API Service ──────────────────────────────────────────────────────────────

class AirQualityApiService {
  AirQualityApiService._();
  static final instance = AirQualityApiService._();

  // ────────────────────────────────────────────────────────────────────────────
  // SHARED
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/stations/
  /// Returns all active monitoring stations.
  Future<List<Map<String, dynamic>>> fetchStations() async {
    final data = await _get('/stations/');
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// GET /api/v1/current/?station_id=<id>
  /// Latest AQI reading for one station (used by Home + Health).
  Future<Map<String, dynamic>> fetchCurrentAqi({
    int stationId = defaultStationId,
  }) async {
    final data = await _get('/current/', {'station_id': '$stationId'});
    return Map<String, dynamic>.from(data as Map);
  }

  /// GET /api/v1/readings/?station_id=<id>&hours=<n>
  /// Historical readings for the hourly trend chart.
  Future<List<Map<String, dynamic>>> fetchReadings({
    int stationId = defaultStationId,
    int hours = 24,
  }) async {
    final data = await _get('/readings/', {
      'station_id': '$stationId',
      'hours': '$hours',
    });
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FORECAST SCREEN
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/forecast/hourly/?station_id=<id>&hours=<n>
  /// ML-generated hour-by-hour AQI forecast.
  /// Returns: { station: {...}, forecast: [ {hour, timestamp, aqi, temperature, is_current} ] }
  Future<Map<String, dynamic>> fetchHourlyForecast({
    int stationId = defaultStationId,
    int hours = 24,
  }) async {
    final data = await _get('/forecast/hourly/', {
      'station_id': '$stationId',
      'hours': '$hours',
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// GET /api/v1/forecast/daily/?station_id=<id>&days=<n>
  /// ML-generated 7-day AQI forecast.
  /// Returns: { station: {...}, forecast: [ {day_name, date, aqi_avg, aqi_min, aqi_max, condition, is_today} ] }
  Future<Map<String, dynamic>> fetchDailyForecast({
    int stationId = defaultStationId,
    int days = 7,
  }) async {
    final data = await _get('/forecast/daily/', {
      'station_id': '$stationId',
      'days': '$days',
    });
    return Map<String, dynamic>.from(data as Map);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HEALTH SCREEN
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/recommendations/?aqi=<value>&groups=<g1,g2,...>
  ///
  /// [aqi]    — current AQI integer e.g. 142
  /// [groups] — one or more of:
  ///              general | children | elderly | pregnant |
  ///              asthma  | outdoor_workers
  ///
  /// Returns:
  /// {
  ///   "aqi": 142,
  ///   "level": { "name": "Unhealthy for Sensitive Groups", "color": "#FB923C" },
  ///   "recommendations": {
  ///     "general":  ["Reduce outdoor activities.", ...],
  ///     "children": ["Cancel outdoor sports.", ...]
  ///   }
  /// }
  Future<Map<String, dynamic>> fetchRecommendations({
    required int aqi,
    List<String> groups = const ['general'],
  }) async {
    final data = await _get('/recommendations/', {
      'aqi': '$aqi',
      'groups': groups.join(','),
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// Convenience: fetch recommendations for ALL groups at once.
  Future<Map<String, dynamic>> fetchAllGroupRecommendations({
    required int aqi,
  }) async {
    return fetchRecommendations(
      aqi: aqi,
      groups: const [
        'general', 'children', 'elderly',
        'pregnant', 'asthma', 'outdoor_workers',
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // MAP SCREEN
  // ────────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/map/stations/
  ///
  /// Returns every active station with its LATEST AQI reading.
  /// Used to place markers on the OpenStreetMap and colour the heatmap circles.
  ///
  /// Response shape (list):
  /// [
  ///   {
  ///     "station": {
  ///       "id": 1,
  ///       "name": "Kinondoni Station",
  ///       "district": "Kinondoni",
  ///       "city": "Dar es Salaam",
  ///       "latitude": -6.7924,
  ///       "longitude": 39.2083
  ///     },
  ///     "aqi": 142,
  ///     "level": { "name": "Unhealthy for Sensitive Groups", "color": "#FB923C" },
  ///     "pm25": 52.3,
  ///     "updated": "2024-05-14T14:00:00Z"
  ///   },
  ///   ...
  /// ]
  Future<List<Map<String, dynamic>>> fetchMapStations() async {
    final data = await _get('/map/stations/');
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// GET /api/v1/current/?station_id=<id>
  /// Full reading detail for one station — called when user taps a marker
  /// to populate the bottom sheet with PM10, temp, humidity etc.
  Future<Map<String, dynamic>> fetchStationDetail({
    required int stationId,
  }) async {
    final data = await _get('/current/', {'station_id': '$stationId'});
    return Map<String, dynamic>.from(data as Map);
  }

  /// GET /api/v1/readings/?station_id=<id>&hours=6
  /// Mini 6-hour history for the selected station's sparkline in the bottom sheet.
  Future<List<Map<String, dynamic>>> fetchStationHistory({
    required int stationId,
    int hours = 6,
  }) async {
    final data = await _get('/readings/', {
      'station_id': '$stationId',
      'hours': '$hours',
    });
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SENSOR INGEST  (called by your IoT sensor / data pipeline)
  // ────────────────────────────────────────────────────────────────────────────

  /// POST /api/v1/readings/ingest/
  /// Push a new sensor reading to the backend.
  /// The backend stores it AND runs the ML model to return predicted_aqi.
  ///
  /// [stationId] — station FK
  /// [timestamp] — ISO-8601 string, e.g. DateTime.now().toIso8601String()
  Future<Map<String, dynamic>> ingestReading({
    required int stationId,
    required String timestamp,
    required int aqi,
    required double pm25,
    required double pm10,
    required double o3,
    required double no2,
    required double so2,
    required double co,
    required double temperature,
    required double humidity,
    required double windSpeed,
  }) async {
    final data = await _post('/readings/ingest/', {
      'station':     stationId,
      'timestamp':   timestamp,
      'aqi':         aqi,
      'pm25':        pm25,
      'pm10':        pm10,
      'o3':          o3,
      'no2':         no2,
      'so2':         so2,
      'co':          co,
      'temperature': temperature,
      'humidity':    humidity,
      'wind_speed':  windSpeed,
    });
    return Map<String, dynamic>.from(data as Map);
  }
}

// ─── Singleton shorthand ──────────────────────────────────────────────────────
AirQualityApiService get api => AirQualityApiService.instance;