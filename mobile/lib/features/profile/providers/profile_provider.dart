import 'package:flutter/material.dart';
import '../../../core/models/user.dart';
import '../../../core/models/watch_history_entry.dart';
import '../../../core/services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final _api = ApiService();

  bool _saving = false;
  String? _error;
  String? _success;

  List<WatchHistoryEntry> _history = [];
  bool _historyLoading = false;

  bool get saving => _saving;
  String? get error => _error;
  String? get success => _success;

  List<WatchHistoryEntry> get history => _history;
  bool get historyLoading => _historyLoading;

  // Returns history grouped by "YYYY-MM" key, ordered newest first
  Map<String, List<WatchHistoryEntry>> get historyByMonth {
    final map = <String, List<WatchHistoryEntry>>{};
    for (final e in _history) {
      final key =
          '${e.watchedOn.year}-${e.watchedOn.month.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(e);
    }
    return map;
  }

  Future<void> loadHistory() async {
    _historyLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/history');
      final list = res['data'] as List<dynamic>;
      _history = list
          .map((e) => WatchHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (_) {
      _history = [];
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromHistory(int id) async {
    try {
      await _api.delete('/api/history/$id');
      _history = _history.where((e) => e.id != id).toList();
      notifyListeners();
    } on ApiException catch (_) {}
  }

  Future<bool> updateProfile(
    String name,
    String email, {
    required void Function(User) onSuccess,
  }) async {
    _saving = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      final res = await _api.put('/api/user/me', data: {
        'name': name.trim(),
        'email': email.trim(),
      });
      final user = User.fromJson(res['data'] as Map<String, dynamic>);
      onSuccess(user);
      _success = 'Perfil actualizado correctamente.';
      _saving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String current, String newPass) async {
    _saving = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      await _api.put('/api/user/password', data: {
        'current_password': current,
        'new_password': newPass,
      });
      _success = 'Contraseña cambiada correctamente.';
      _saving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  bool _requestingDeletion = false;
  bool get requestingDeletion => _requestingDeletion;

  Future<bool> requestDeletion({required void Function(User) onSuccess}) async {
    _requestingDeletion = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/api/user/delete-request', data: {});
      final meRes = await _api.get('/api/user/me');
      final user = User.fromJson(meRes['data'] as Map<String, dynamic>);
      onSuccess(user);
      _requestingDeletion = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _requestingDeletion = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
