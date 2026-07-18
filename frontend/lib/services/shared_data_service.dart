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

  String _selectedDevice = defaultDevice;
  List<String> _devices = [];
  AirQualityData? _currentData;
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;
  String _connectionState = 'disconnected';

  String get selectedDevice => _selectedDevice;
  List<String> get devices => _devices;
  AirQualityData? get currentData => _currentData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  String get connectionState => _connectionState;

  SharedDataService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedDevice = prefs.getString(_prefDevice) ?? defaultDevice;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        api.fetchDevices(),
        api.fetchDeviceAqi(deviceId: _selectedDevice),
        api.fetchDeviceReadings(deviceId: _selectedDevice, hours: 24),
      ]);

      _devices = results[0] as List<String>;
      final aqiMap = results[1] as Map<String, dynamic>;
      final readingsList = results[2] as List<Map<String, dynamic>>;

      final pollutants = aqiMap['pollutants'] as Map<String, dynamic>? ?? {};
      final environment = aqiMap['environment'] as Map<String, dynamic>? ?? {};
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
      _isLoading = false;
      await notificationService.evaluateAqi(
        _currentData!.aqi,
        location: deviceDisplayName(_selectedDevice),
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }

    notifyListeners();
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
