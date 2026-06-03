import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthStorage {
  static late SharedPreferences _prefs;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _prefs.setString(_accessKey, accessToken),
      _prefs.setString(_refreshKey, refreshToken),
    ]);
  }

  static Future<void> saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static String? getAccessToken() => _prefs.getString(_accessKey);
  static String? getRefreshToken() => _prefs.getString(_refreshKey);

  static User? getUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static bool get isLoggedIn => getAccessToken() != null;

  static Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_accessKey),
      _prefs.remove(_refreshKey),
      _prefs.remove(_userKey),
    ]);
  }
}
