import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/Data/air_quality_data.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _prefNotificationsEnabled = 'notifications_enabled';
  static const _prefAqiThreshold = 'aqi_alert_threshold';
  static const _prefNotifyOnLevelChange = 'notify_on_level_change';
  static const _prefLastLevelIndex = 'last_aqi_level_index';
  static const _prefWasAboveThreshold = 'was_above_aqi_threshold';
  static const _prefHasBaseline = 'aqi_notification_baseline_set';

  static const _thresholdNotificationId = 1001;
  static const _levelChangeNotificationId = 1002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool? _notificationsEnabled;
  bool? _notifyOnLevelChange;
  int _aqiThreshold = 150;
  int? _lastLevelIndex;
  bool? _wasAboveThreshold;
  bool? _hasBaseline;

  bool get enabled => _notificationsEnabled ?? true;
  bool get notifyOnLevelChange => _notifyOnLevelChange ?? true;
  int get aqiThreshold => _aqiThreshold;
  String get thresholdLabel =>
      '$_aqiThreshold — ${_thresholdName(_aqiThreshold)}';

  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    await _createChannel();
    await _requestPermissions();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_prefNotificationsEnabled) ?? true;
    _notifyOnLevelChange = prefs.getBool(_prefNotifyOnLevelChange) ?? true;
    _aqiThreshold = prefs.getInt(_prefAqiThreshold) ?? 150;
    _lastLevelIndex = prefs.getInt(_prefLastLevelIndex);
    _wasAboveThreshold = prefs.getBool(_prefWasAboveThreshold) ?? false;
    _hasBaseline = prefs.getBool(_prefHasBaseline) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (enabled == value) return;
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setNotifyOnLevelChange(bool value) async {
    if (notifyOnLevelChange == value) return;
    _notifyOnLevelChange = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifyOnLevelChange, value);
    notifyListeners();
  }

  Future<void> setAqiThreshold(int threshold) async {
    if (_aqiThreshold == threshold) return;
    _aqiThreshold = threshold;
    _wasAboveThreshold = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefAqiThreshold, threshold);
    await prefs.setBool(_prefWasAboveThreshold, false);
    notifyListeners();
  }

  /// Evaluates current AQI and sends alerts for threshold breach or level change.
  Future<void> evaluateAqi(int aqi, {String? location}) async {
    if (!enabled || kIsWeb) return;

    final station = location ?? 'your station';
    final level = getAqiLevel(aqi);
    final levelIndex = _levelIndexForAqi(aqi);
    final isAboveThreshold = aqi > _aqiThreshold;
    final hasBaseline = _hasBaseline ?? false;
    final wasAbove = _wasAboveThreshold ?? false;

    if (!hasBaseline) {
      await _persistState(
        levelIndex: levelIndex,
        wasAboveThreshold: isAboveThreshold,
        hasBaseline: true,
      );
      return;
    }

    if (notifyOnLevelChange &&
        _lastLevelIndex != null &&
        levelIndex != _lastLevelIndex) {
      final previous = getAqiLevel(_aqiForLevelIndex(_lastLevelIndex!));
      final improved = levelIndex < _lastLevelIndex!;
      await _showNotification(
        id: _levelChangeNotificationId,
        title: improved ? 'AQI improved' : 'AQI level changed',
        body: improved
            ? 'Air quality at $station improved from ${previous.name} to '
                '${level.name} (AQI $aqi). ${level.advice}'
            : 'Air quality at $station changed from ${previous.name} to '
                '${level.name} (AQI $aqi). ${level.advice}',
      );
    }

    if (isAboveThreshold && !wasAbove) {
      await _showNotification(
        id: _thresholdNotificationId,
        title: 'AQI above threshold',
        body: 'AQI at $station is $aqi (your alert threshold is '
            '$_aqiThreshold). ${level.name}: ${level.advice}',
      );
    }

    await _persistState(
      levelIndex: levelIndex,
      wasAboveThreshold: isAboveThreshold,
    );
  }

  /// Backward-compatible entry point used by existing screens.
  Future<void> maybeNotifyAqiAlert(int aqi, {String? location}) =>
      evaluateAqi(aqi, location: location);

  Future<void> _persistState({
    required int levelIndex,
    required bool wasAboveThreshold,
    bool? hasBaseline,
  }) async {
    _lastLevelIndex = levelIndex;
    _wasAboveThreshold = wasAboveThreshold;
    if (hasBaseline != null) {
      _hasBaseline = hasBaseline;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefLastLevelIndex, levelIndex);
    await prefs.setBool(_prefWasAboveThreshold, wasAboveThreshold);
    if (hasBaseline != null) {
      await prefs.setBool(_prefHasBaseline, hasBaseline);
    }
  }

  int _levelIndexForAqi(int aqi) {
    if (aqi <= 50) return 0;
    if (aqi <= 100) return 1;
    if (aqi <= 150) return 2;
    if (aqi <= 200) return 3;
    if (aqi <= 300) return 4;
    return 5;
  }

  int _aqiForLevelIndex(int index) {
    switch (index) {
      case 0:
        return 40;
      case 1:
        return 75;
      case 2:
        return 125;
      case 3:
        return 175;
      case 4:
        return 250;
      default:
        return 350;
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'aqi_alerts',
      'AQI Alerts',
      channelDescription: 'Air quality alert notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _createChannel() async {
    if (kIsWeb) return;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    const channel = AndroidNotificationChannel(
      'aqi_alerts',
      'AQI Alerts',
      description: 'Air quality alert notifications',
      importance: Importance.high,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  String _thresholdName(int threshold) {
    switch (threshold) {
      case 50:
        return 'Good';
      case 100:
        return 'Moderate';
      case 150:
        return 'Sensitive';
      case 200:
        return 'Unhealthy';
      case 300:
        return 'Very Unhealthy';
      default:
        return 'Alert';
    }
  }
}

final notificationService = NotificationService.instance;
