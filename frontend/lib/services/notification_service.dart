import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/Data/air_quality_data.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _prefNotificationsEnabled = 'notifications_enabled';
  static const _prefAqiThreshold = 'aqi_alert_threshold';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsEnabled = true;
  int _aqiThreshold = 150;
  int? _lastNotifiedAqi;

  bool get enabled => _notificationsEnabled;
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
    _aqiThreshold = prefs.getInt(_prefAqiThreshold) ?? 150;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setAqiThreshold(int threshold) async {
    if (_aqiThreshold == threshold) return;
    _aqiThreshold = threshold;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefAqiThreshold, threshold);
    notifyListeners();
  }

  Future<void> maybeNotifyAqiAlert(int aqi) async {
    if (!enabled) return;
    if (aqi <= aqiThreshold) {
      _lastNotifiedAqi = null;
      return;
    }

    if (_lastNotifiedAqi == aqi) return;
    _lastNotifiedAqi = aqi;

    await _showNotification(
      title: 'AQI Alert — $aqi',
      body: _notificationBody(aqi),
    );
  }

  Future<void> _showNotification({
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
        android: androidDetails, iOS: iosDetails, macOS: iosDetails);

    await _plugin.show(
      id: 0,
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

  String _notificationBody(int aqi) {
    final level = getAqiLevel(aqi);
    return '${level.name}: ${level.advice}';
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

/// Singleton shorthand.
final notificationService = NotificationService.instance;
