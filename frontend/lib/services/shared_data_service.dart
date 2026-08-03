import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/Data/air_quality_data.dart';
import '/utils/device_labels.dart';
import '/utils/time_utils.dart';
import '/services/api_service.dart';
import '/services/notification_service.dart';
import '/screens/app_theme.dart';

/// Shared data service that manages device selection and readings for all screens.
/// All screens subscribe to this service to stay in sync.
class SharedDataService extends ChangeNotifier {
  static const _prefDevice = 'default_sensor_device';
  static const _refreshInterval = Duration(seconds: 60);

  String _selectedDevice = defaultDevice;
  List<String> _devices = [];
  AirQualityData? _currentData;
  bool? _isLoading;
  bool? _isRefreshing;
  String? _error;
  DateTime? _lastUpdated;
  String _connectionState = 'disconnected';
  Map<String, Map<String, dynamic>>? _deviceAqiCache;
  Timer? _refreshTimer;
  Future<void>? _loadInFlight;

  String get selectedDevice => _selectedDevice;
  List<String> get devices => _devices;
  AirQualityData? get currentData => _currentData;
  bool get isLoading => _isLoading ?? true;
  bool get isRefreshing => _isRefreshing ?? false;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  String get connectionState => _connectionState;

  Map<String, Map<String, dynamic>> get deviceAqiById =>
      Map.unmodifiable(_cache);

  Map<String, Map<String, dynamic>> get _cache =>
      _deviceAqiCache ??= <String, Map<String, dynamic>>{};

  SharedDataService() {
    _loadPreferences();
    _startAutoRefresh();
  }

  Map<String, dynamic>? aqiDataFor(String deviceId) => _cache[deviceId];

  int aqiForDevice(String deviceId) =>
      (aqiDataFor(deviceId)?['aqi'] as num?)?.toInt() ?? 0;

  DateTime? aqiUpdatedAtFor(String deviceId) {
    final ts = aqiDataFor(deviceId)?['timestamp'];
    return ts == null ? null : parseApiTimestamp(ts);
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      loadData(background: true);
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedDevice = prefs.getString(_prefDevice) ?? defaultDevice;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshDeviceAqiCache(List<String> deviceIds) async {
    final ids = deviceIds.isEmpty ? allowedDevices : deviceIds;
    final entries = await Future.wait(
      ids.map((id) async {
        try {
          final data = await api.fetchDeviceAqi(deviceId: id);
          return MapEntry(id, data);
        } catch (_) {
          return null;
        }
      }),
    );

    for (final entry in entries) {
      if (entry != null) {
        _cache[entry.key] = entry.value;
      }
    }
  }

  /// Fetch device list and AQI data for the selected device.
  Future<void> loadData({bool background = false}) async {
    if (_loadInFlight != null) {
      await _loadInFlight;
      if (background) return;
    }

    final load = _performLoad(background: background);
    _loadInFlight = load;
    try {
      await load;
    } finally {
      if (identical(_loadInFlight, load)) {
        _loadInFlight = null;
      }
    }
  }

  /// Lightweight refresh for the map screen — device list + AQI only (no 24h readings).
  Future<void> loadMapData({bool background = false}) async {
    if (!background) {
      _isLoading = true;
      _error = null;
    } else if (!isLoading) {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final devices = await api.fetchDevices();
      _devices = devices;
      await _refreshDeviceAqiCache(devices);
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      if (_cache.isEmpty && (!background || _currentData == null)) {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _performLoad({required bool background}) async {
    if (!background) {
      _isLoading = true;
      _error = null;
    } else if (!isLoading) {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final devices = await api.fetchDevices();
      _devices = devices;

      await _refreshDeviceAqiCache(devices);

      final results = await Future.wait([
        api.fetchDeviceAqi(deviceId: _selectedDevice),
        api.fetchDeviceReadings(deviceId: _selectedDevice, hours: 24),
      ]);
      final aqiMap = Map<String, dynamic>.from(results[0] as Map);
      final readingsList =
          List<Map<String, dynamic>>.from(results[1] as List);

      _cache[_selectedDevice] = aqiMap;

      final pollutants =
          Map<String, dynamic>.from(aqiMap['pollutants'] as Map? ?? {});
      final environment =
          Map<String, dynamic>.from(aqiMap['environment'] as Map? ?? {});
      final hourlyData = _buildHourlyData(readingsList);

      var updatedAt = parseApiTimestamp(aqiMap['timestamp']);
      if (readingsList.isNotEmpty) {
        final latestReadingTs =
            parseApiTimestamp(readingsList.first['timestamp']);
        if (latestReadingTs.isAfter(updatedAt)) {
          updatedAt = latestReadingTs;
        }
      }

      _currentData = AirQualityData(
        aqi: (aqiMap['aqi'] as num?)?.toInt() ?? 0,
        city: 'Dar es Salaam',
        district: deviceDisplayName(_selectedDevice),
        updatedAt: updatedAt,
        temperature: (environment['temperature'] as num?)?.toDouble() ?? 0,
        humidity: (environment['humidity'] as num?)?.toDouble() ?? 0,
        windSpeed: 0,
        pollutants: [
          Pollutant(
            name: 'PM2.5',
            unit: 'µg/m³',
            value: (pollutants['pm25'] as num?)?.toDouble() ?? 0,
            maxSafe: 35,
            color: AppColors.pm25Color,
          ),
          Pollutant(
            name: 'PM10',
            unit: 'µg/m³',
            value: (pollutants['pm10'] as num?)?.toDouble() ?? 0,
            maxSafe: 150,
            color: AppColors.pm10Color,
          ),
          Pollutant(
            name: 'CO2',
            unit: 'PPM',
            value: (pollutants['co2'] as num?)?.toDouble() ?? 0,
            maxSafe: 1000,
            color: AppColors.o3Color,
          ),
          Pollutant(
            name: 'NOx',
            unit: 'PPM',
            value: (pollutants['nox'] as num?)?.toDouble() ?? 0,
            maxSafe: 0.1,
            color: AppColors.no2Color,
          ),
          Pollutant(
            name: 'VOC',
            unit: 'PPM',
            value: (pollutants['voc'] as num?)?.toDouble() ?? 0,
            maxSafe: 1.0,
            color: AppColors.so2Color,
          ),
        ],
        hourlyData: hourlyData,
      );
      _lastUpdated = DateTime.now();
      _error = null;
      await notificationService.evaluateAqi(
        _currentData!.aqi,
        location: deviceDisplayName(_selectedDevice),
      );
    } catch (e) {
      if (_cache.isEmpty && (!background || _currentData == null)) {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedDevice(String deviceId) async {
    if (deviceId == _selectedDevice) return;
    _selectedDevice = deviceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDevice, deviceId);
    await loadData();
  }

  Future<void> detectNearestSensor() async {
    _connectionState = 'searching';
    notifyListeners();

    Future<void> fallbackToDefault() async {
      _selectedDevice = 'lands-building';
      await loadData();
      _connectionState = 'connected';
      _error = null;
      notifyListeners();
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await fallbackToDefault();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await fallbackToDefault();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await fallbackToDefault();
        return;
      }

      _connectionState = 'locating';
      notifyListeners();

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        await fallbackToDefault();
        return;
      }

      _connectionState = 'detecting';
      notifyListeners();

      final result = await api
          .fetchNearestSensor(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 4));

      if (result['nearest'] != null) {
        final nearest = result['nearest'] as Map<String, dynamic>;
        final sensor = nearest['sensor'] as Map<String, dynamic>;
        final sensorId = sensor['sensor_id'] as String;

        _connectionState = 'connecting';
        notifyListeners();

        if (sensorId != _selectedDevice) {
          _selectedDevice = sensorId;
          await loadData();
        } else {
          await loadData(background: true);
        }

        _connectionState = 'connected';
        notifyListeners();
      } else {
        await fallbackToDefault();
      }
    } catch (e) {
      await fallbackToDefault();
    }
  }

  List<HourlyAqi> _buildHourlyData(List<Map<String, dynamic>> readings) {
    if (readings.isEmpty) return [];
    final sorted = readings.reversed.toList();
    return sorted.take(9).map((r) {
      final ts = parseApiTimestamp(r['timestamp']);
      final hour = _formatHour(ts);
      final pm25 = (r['pm25'] as num?)?.toDouble() ?? 0;
      final pm10 = (r['pm10'] as num?)?.toDouble() ?? 0;
      final nox = (r['nox'] as num?)?.toDouble() ?? 0;
      final aqi = _quickAqi(pm25, pm10, nox);
      return HourlyAqi(hour: hour, aqi: aqi);
    }).toList();
  }

  String _formatHour(DateTime dt) {
    final h = dt.hour;
    final meridiem = h < 12 ? 'am' : 'pm';
    final hourDisplay = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hourDisplay$meridiem';
  }

  int _quickAqi(double pm25, double pm10, double nox) {
    int a = (pm25 / 35 * 100).round().clamp(0, 500);
    int b = (pm10 / 150 * 100).round().clamp(0, 500);
    int c = (nox / 0.1 * 100).round().clamp(0, 500);
    return [a, b, c].reduce((x, y) => x > y ? x : y);
  }
}

final sharedDataService = SharedDataService();
