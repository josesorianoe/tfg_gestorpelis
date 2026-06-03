import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? createdAt;
  final bool deletionRequested;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.deletionRequested = false,
  });

  bool get isAdmin => role == 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: int.parse(json['id'].toString()),
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'user',
        createdAt: json['created_at'] as String?,
        deletionRequested: json['deletion_requested_at'] != null,
      );
}

class AdminProvider extends ChangeNotifier {
  final _api = ApiService();

  List<AdminUser> _users = [];
  bool _loading = false;
  String? _error;
  bool _loginPopupShown = false;

  List<AdminUser> get users => _users;
  bool get loading => _loading;
  String? get error => _error;
  bool get loginPopupShown => _loginPopupShown;

  int get pendingDeletionCount => _users.where((u) => u.deletionRequested).length;

  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/admin/users');
      final list = res['data'] as List<dynamic>;
      _users = list.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _api.delete('/api/admin/users/$id');
      _users = _users.where((u) => u.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void markLoginPopupShown() {
    _loginPopupShown = true;
  }

  void reset() {
    _users = [];
    _loginPopupShown = false;
    _error = null;
    notifyListeners();
  }
}
