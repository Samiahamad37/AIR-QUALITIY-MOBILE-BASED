import 'package:flutter/foundation.dart';

const _productionOrigin = 'http://92.5.10.116';
const _localOrigin = 'http://127.0.0.1:8000';
const _androidEmulatorOrigin = 'http://10.0.2.2:8000';

/// Override at run time:
/// `flutter run --dart-define=API_HOST=192.168.1.10`
/// or `--dart-define=API_HOST=192.168.1.10:8000`
const _hostOverride = String.fromEnvironment('API_HOST');

String _originFromHost(String host) {
  if (host.startsWith('http://') || host.startsWith('https://')) {
    return host;
  }
  if (host.contains(':')) {
    return 'http://$host';
  }
  return 'http://$host:8000';
}

String get apiOrigin {
  if (_hostOverride.isNotEmpty) return _originFromHost(_hostOverride);
  if (kDebugMode) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorOrigin;
    }
    return _localOrigin;
  }
  return _productionOrigin;
}

String get airQualityApiBaseUrl => '$apiOrigin/api/air-quality';
String get usersApiBaseUrl => '$apiOrigin/api/users';
