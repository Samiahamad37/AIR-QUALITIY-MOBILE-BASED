import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Config ───────────────────────────────────────────────────────────────────
// Android emulator  → 10.0.2.2:8000
// iOS simulator     → 127.0.0.1:8000
// Real device       → your machine's local IP e.g. 192.168.1.x:8000

const String _authBaseUrl = 'http://localhost:8000/api/users';
const Duration _authTimeout = Duration(seconds: 30);

/// Thrown when an authentication request fails. [message] is user-facing.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Holds the signed-in user and exposes login / register / logout.
///
/// Tokens and basic profile are persisted with [SharedPreferences] so the
/// session survives app restarts. Screens listen to this notifier to react to
/// sign-in / sign-out.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUsername = 'auth_username';
  static const _kEmail = 'auth_email';

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  String? _email;
  bool _initialized = false;

  bool get isLoggedIn => _accessToken != null;
  bool get isInitialized => _initialized;
  String? get accessToken => _accessToken;
  String? get username => _username;
  String? get email => _email;

  /// Authorization header for authenticated API calls, or empty when guest.
  Map<String, String> get authHeader =>
      _accessToken != null ? {'Authorization': 'Bearer $_accessToken'} : {};

  /// Restore a persisted session. Call once during app startup.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kAccess);
    _refreshToken = prefs.getString(_kRefresh);
    _username = prefs.getString(_kUsername);
    _email = prefs.getString(_kEmail);
    _initialized = true;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final res = await _post('/login/', {
      'username': username,
      'password': password,
    });
    await _persist(res);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _post('/register/', {
      'username': username,
      'email': email,
      'password': password,
    });
    await _persist(res);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kUsername);
    await prefs.remove(_kEmail);
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    _email = null;
    notifyListeners();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_authBaseUrl$path');
    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_authTimeout);
    } catch (_) {
      throw const AuthException(
          'Network error. Please check your connection and try again.');
    }

    dynamic decoded;
    try {
      decoded = res.body.isNotEmpty ? jsonDecode(res.body) : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw AuthException(_extractError(decoded, res.statusCode));
  }

  String _extractError(dynamic body, int statusCode) {
    if (body is Map && body.isNotEmpty) {
      final detail = body['detail'];
      if (detail != null) return detail.toString();
      for (final entry in body.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return '${entry.key}: ${value.first}';
        }
        if (value is String && value.isNotEmpty) return value;
      }
    }
    if (statusCode == 401) return 'Invalid username or password.';
    return 'Request failed ($statusCode). Please try again.';
  }

  Future<void> _persist(Map<String, dynamic> res) async {
    _accessToken = res['access'] as String?;
    _refreshToken = res['refresh'] as String?;
    final user = res['user'];
    if (user is Map) {
      _username = user['username']?.toString();
      _email = user['email']?.toString();
    }

    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString(_kAccess, _accessToken!);
    if (_refreshToken != null) await prefs.setString(_kRefresh, _refreshToken!);
    if (_username != null) await prefs.setString(_kUsername, _username!);
    if (_email != null) await prefs.setString(_kEmail, _email!);

    notifyListeners();
  }
}

/// Singleton shorthand.
final authService = AuthService.instance;
