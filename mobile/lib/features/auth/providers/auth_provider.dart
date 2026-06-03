import 'package:flutter/material.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && AuthStorage.isLoggedIn;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (AuthStorage.isLoggedIn) {
      _user = AuthStorage.getUser();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/api/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      await _saveAuth(res['data'] as Map<String, dynamic>);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/api/auth/register', data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      });
      await _saveAuth(res['data'] as Map<String, dynamic>);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final rt = AuthStorage.getRefreshToken();
      if (rt != null) {
        await _api.post('/api/auth/logout', data: {'refresh_token': rt});
      }
    } catch (_) {}
    await AuthStorage.clear();
    _user = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    AuthStorage.saveUser(user);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    await AuthStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    await AuthStorage.saveUser(_user!);
  }
}
