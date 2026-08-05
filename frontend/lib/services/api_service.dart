import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '/config/api_config.dart';

// ─── Config ───────────────────────────────────────────────────────────────────
// Debug  → local Django (127.0.0.1:8000, or 10.0.2.2 on Android emulator)
// Release → production VM at 92.5.10.116
// Override: flutter run --dart-define=API_HOST=192.168.x.x

Duration get _timeout => kDebugMode
    ? const Duration(seconds: 30)
    : const Duration(seconds: 20);

const List<String> allowedDevices = ['lands-building', 'planing-building'];
const String defaultDevice = 'lands-building';

// Device name mapping for API compatibility
String _mapDeviceName(String deviceId) {
  if (deviceId == 'lands-building') return 'lands';
  if (deviceId == 'planing-building') return 'planning';
  return deviceId;
}

// ─── Exception ────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─── HTTP helpers ─────────────────────────────────────────────────────────────

Future<dynamic> _get(String path,
    [Map<String, String>? params, String? baseUrl]) async {
  final root = baseUrl ?? airQualityApiBaseUrl;
  final uri = (params != null && params.isNotEmpty)
      ? Uri.parse('$root$path').replace(queryParameters: params)
      : Uri.parse('$root$path');
  print('>>> Requesting: $uri');

  try {
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'}).timeout(_timeout);

    if (kDebugMode) print('>>> Response status: ${res.statusCode}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }

    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = {'error': res.reasonPhrase ?? 'Unknown error'};
    }
    throw ApiException(
        res.statusCode, body['detail'] ?? body['error'] ?? 'Unknown error');
  } catch (e) {
    if (kDebugMode) print('>>> Request failed: $e');
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
  // ── Predictions ───────────────────────────────────────────────────────────────

  /// GET /api/air-quality/predict/all/
  /// Returns 6-hour air quality forecast from backend (proxies to external API).
  /// Response: { sensors: { <sensor_name>: { current_aqi, trend_direction, trend_confidence, forecast_6h, pollutants, timestamp } } }
  Future<Map<String, dynamic>> fetchPredictions({String deviceId = defaultDevice}) async {
    Map<String, dynamic>? data;

    try {
      data = Map<String, dynamic>.from(await _get('/predict/all/') as Map);
    } catch (_) {
      try {
        data = Map<String, dynamic>.from(
          await _get('/predict/all/', null, '$apiOrigin/api') as Map,
        );
      } catch (_) {
        data = await _fetchExternalJson(
          'https://airquality-ai.tlms.live/api/predict/all',
        );
      }
    }

    if (data == null) {
      throw ApiException(503, 'Forecast service unavailable');
    }

    final sensors = data['sensors'] as Map<String, dynamic>?;
    final mappedDevice = _mapDeviceName(deviceId);
    final sensorData = sensors?[mappedDevice] as Map<String, dynamic>?;

    if (sensorData == null) {
      throw ApiException(404, 'Sensor data not found for device: $deviceId');
    }

    return Map<String, dynamic>.from(sensorData);
  }

  // ── Recommendations ───────────────────────────────────────────────────────────

  /// GET /api/air-quality/recommend/
  /// Returns AI-generated health recommendations from backend (proxies to external API).
  /// Response: { advice, aqi, aqi_category, timestamp }
  // Future<Map<String, dynamic>> fetchRecommendations() async {
  //   final data = await _get('/recommend/', {}, false);
  //   return Map<String, dynamic>.from(data as Map);
  // }


// // ✅ AFTER — calls the AI API directly
//  Future<Map<String, dynamic>> fetchRecommendations({int? aqi}) async {
//    const aiUrl = 'https://airquality-ai.tlms.live/api/recommend/';
//    final uri = Uri.parse(aiUrl).replace(
//      queryParameters: aqi != null ? {'aqi': '$aqi'} : null,
//    );
//    final res = await http.get(uri, headers: {'Accept': 'application/json'})
//       .timeout(const Duration(seconds: 15));
//    if (res.statusCode >= 200 && res.statusCode < 300) {
//      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
//     }
//     throw ApiException(res.statusCode, res.reasonPhrase ?? 'Error');
// }
  Future<Map<String, dynamic>> fetchRecommendations({int aqi = 0}) async {
    final params = {'aqi': '$aqi'};

    for (final root in [airQualityApiBaseUrl, '$apiOrigin/api']) {
      try {
        final data = await _get('/recommend/', params, root);
        return Map<String, dynamic>.from(data as Map);
      } catch (_) {
        // try next base URL
      }
    }

    try {
      final uri = Uri.parse('https://airquality-ai.tlms.live/api/recommend/')
          .replace(queryParameters: params);
      final data = await _fetchExternalJson(uri.toString());
      if (data != null) return data;
    } catch (e) {
      debugPrint('>>> Recommend fallback failed: $e');
    }

    return {};
  }

  Future<Map<String, dynamic>?> _fetchExternalJson(String url) async {
    debugPrint('>>> Requesting external: $url');
    final res = await http
        .get(Uri.parse(url), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }

  // ── Sensor History ──────────────────────────────────────────────────────────

  /// GET /api/history/sensor/?device_id=<id>&hours=<n>&limit=<n>
  /// Returns recent raw sensor readings for a device.
  Future<Map<String, dynamic>> fetchSensorHistory({
    String deviceId = defaultDevice,
    int hours = 24,
    int? limit,
  }) async {
    final params = <String, String>{
      'device_id': deviceId,
      'hours': '$hours',
      if (limit != null) 'limit': '$limit',
    };
    final data = await _get('/history/sensor/', params, '$apiOrigin/api');
    return Map<String, dynamic>.from(data as Map);
  }
  // ── Nearest Sensor ──────────────────────────────────────────────

  /// GET /api/sensors/nearest/?lat=<lat>&lng=<lng>
  /// Find nearest sensor based on user's location.
  Future<Map<String, dynamic>> fetchNearestSensor(
      double lat, double lng) async {
    final params = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
    };
    final data = await _get('/sensors/nearest/', params, sensorsApiBaseUrl);
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
