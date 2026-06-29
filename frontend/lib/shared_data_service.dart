import 'package:flutter/foundation.dart';
import 'air_quality_data.dart';
import 'api_service.dart';
import 'app_theme.dart';

/// Shared data service that manages device selection and readings for all screens.
/// All screens subscribe to this service to stay in sync.
class SharedDataService extends ChangeNotifier {
  String _selectedDevice = 'lands-building';
  List<String> _devices = [];
  AirQualityData? _currentData;
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  String get selectedDevice => _selectedDevice;
  List<String> get devices => _devices;
  AirQualityData? get currentData => _currentData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  /// Fetch device list and AQI data for the selected device.
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch devices and current AQI data
      final [devices, aqiData, readings] = await Future.wait([
        api.fetchDevices(),
        api.fetchDeviceAqi(deviceId: _selectedDevice),
        api.fetchDeviceReadings(deviceId: _selectedDevice, hours: 24),
      ]);

      _devices = devices as List<String>;
      final aqiMap = aqiData as Map<String, dynamic>;
      final readingsList = readings as List<Map<String, dynamic>>;

      // Build AirQualityData from API response
      final pollutants = aqiMap['pollutants'] as Map<String, dynamic>? ?? {};
      final environment = aqiMap['environment'] as Map<String, dynamic>? ?? {};
      final hourlyData = _buildHourlyData(readingsList);

      _currentData = AirQualityData(
        aqi: (aqiMap['aqi'] as num?)?.toInt() ?? 0,
        city: 'Dar es Salaam',
        district: _selectedDevice,
        updatedAt: DateTime.parse(aqiMap['timestamp']).toLocal(),
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
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  /// Change the selected device and reload data.
  Future<void> setSelectedDevice(String deviceId) async {
    if (deviceId == _selectedDevice) return;
    _selectedDevice = deviceId;
    await loadData();
  }

  /// Build hourly AQI data from readings.
  List<HourlyAqi> _buildHourlyData(List<Map<String, dynamic>> readings) {
    if (readings.isEmpty) return [];
    final sorted = readings.reversed.toList();
    return sorted.take(9).map((r) {
      final ts = DateTime.parse(r['timestamp'].toString()).toLocal();
      final hour = _formatHour(ts);
      final pm25 = (r['pm25'] as num?)?.toDouble() ?? 0;
      final pm10 = (r['pm10'] as num?)?.toDouble() ?? 0;
      final nox = (r['nox'] as num?)?.toDouble() ?? 0;
      final aqi = _quickAqi(pm25, pm10, nox);
      return HourlyAqi(hour: hour, aqi: aqi);
    }).toList();
  }

  /// Format hour for display (e.g., "3pm").
  String _formatHour(DateTime dt) {
    final h = dt.hour;
    final meridiem = h < 12 ? 'am' : 'pm';
    final hourDisplay = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hourDisplay$meridiem';
  }

  /// Quick AQI calculation from pollutants.
  int _quickAqi(double pm25, double pm10, double nox) {
    int a = (pm25 / 35 * 100).round().clamp(0, 500);
    int b = (pm10 / 150 * 100).round().clamp(0, 500);
    int c = (nox / 0.1 * 100).round().clamp(0, 500);
    return [a, b, c].reduce((x, y) => x > y ? x : y);
  }
}

// Singleton instance
final sharedDataService = SharedDataService();
