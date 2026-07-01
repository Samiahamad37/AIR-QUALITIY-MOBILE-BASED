import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Config ───────────────────────────────────────────────────────────────────
// Android emulator  → 10.0.2.2:8000
// iOS simulator     → 127.0.0.1:8000
// Real device       → your machine's local IP e.g. 192.168.1.x:8000

const String _baseUrl = 'http://localhost:8000/api/air-quality';
const Duration _timeout = Duration(seconds: 30);

const List<String> allowedDevices = ['lands-building', 'planing-building'];
const String defaultDevice = 'planing-building';

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
  print('>>> Requesting: $uri');
  
  try {
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(_timeout);

    print('>>> Response status: ${res.statusCode}');
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }

    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = {'error': res.reasonPhrase ?? 'Unknown error'};
    }
    throw ApiException(res.statusCode, body['detail'] ?? body['error'] ?? 'Unknown error');
  } catch (e) {
    print('>>> Request failed: $e');
    rethrow;
  }
}

// ─── API Service ──────────────────────────────────────────────────────────────

class AirQualityApiService {
  AirQualityApiService._();
  static final instance = AirQualityApiService._();

  // ── Devices ────────────────────────────────────────────────────

  /// GET /api/air-quality/devices/
  /// Returns list of available TTN device IDs.
  Future<List<String>> fetchDevices() async {
    final data = await _get('/devices/');
    final devices = List<String>.from(data['devices'] as List);
    return devices.where(allowedDevices.contains).toList();
  }

  // ── AQI ────────────────────────────────────────────────────────

  /// GET /api/air-quality/device/aqi/?device_id=<id>
  /// Latest AQI + recommendations + pollutants + environment.
  /// Response: { device_id, timestamp, aqi, category, color,
  ///             recommendations, pollutants, environment }
  Future<Map<String, dynamic>> fetchDeviceAqi({
    String deviceId = defaultDevice,
  }) async {
    final data = await _get('/device/aqi/', {'device_id': deviceId});
    return Map<String, dynamic>.from(data as Map);
  }

  // ── Latest Reading ─────────────────────────────────────────────

  /// GET /api/air-quality/device/latest/?device_id=<id>
  /// Latest reading with all fields including pollutants + environment.
  Future<Map<String, dynamic>> fetchDeviceLatest({
    String deviceId = defaultDevice,
  }) async {
    final data = await _get('/device/latest/', {'device_id': deviceId});
    return Map<String, dynamic>.from(data as Map);
  }

  // ── Recent Readings ────────────────────────────────────────────

  /// GET /api/air-quality/device/readings/?device_id=<id>&hours=<n>&limit=<n>
  /// Multiple recent readings for a device.
  Future<List<Map<String, dynamic>>> fetchDeviceReadings({
    String deviceId = defaultDevice,
    int hours = 24,
    int? limit,
  }) async {
    final params = <String, String>{
      'device_id': deviceId,
      'hours': '$hours',
      if (limit != null) 'limit': '$limit',
    };
    final data = await _get('/device/readings/', params);
    print('API Response data: $data');
    final readings = List<Map<String, dynamic>>.from(data['readings'] as List);
    print('Parsed ${readings.length} readings');
    return readings;
  }

  // ── Nearest Sensor ──────────────────────────────────────────────

  /// GET /api/sensors/nearest/?lat=<lat>&lng=<lng>
  /// Find nearest sensor based on user's location.
  Future<Map<String, dynamic>> fetchNearestSensor(double lat, double lng) async {
    final params = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
    };
    final data = await _get('/sensors/nearest/', params);
    return data;
  }

  // ── Pollutant History ──────────────────────────────────────────

  /// GET /api/air-quality/device/history/?device_id=<id>&pollutant=<p>&hours=<n>
  /// Time series for a single pollutant.
  /// pollutant: co2 | nox | voc | pm25 | pm10
  Future<List<Map<String, dynamic>>> fetchPollutantHistory({
    String deviceId = defaultDevice,
    required String pollutant,
    int hours = 24,
  }) async {
    final data = await _get('/device/history/', {
      'device_id': deviceId,
      'pollutant': pollutant,
      'hours': '$hours',
    });
    return List<Map<String, dynamic>>.from(data['data'] as List);
  }

  // ── All Pollutants History ─────────────────────────────────────

  /// GET /api/air-quality/device/pollutants/?device_id=<id>&hours=<n>
  /// History of ALL pollutants in one call.
  /// Response: { device_id, hours, pollutants: { co2: [...], nox: [...], ... } }
  Future<Map<String, dynamic>> fetchAllPollutants({
    String deviceId = defaultDevice,
    int hours = 24,
  }) async {
    final data = await _get('/device/pollutants/', {
      'device_id': deviceId,
      'hours': '$hours',
    });
    return Map<String, dynamic>.from(data as Map);
  }
}

// ─── Singleton shorthand ──────────────────────────────────────────────────────
AirQualityApiService get api => AirQualityApiService.instance;