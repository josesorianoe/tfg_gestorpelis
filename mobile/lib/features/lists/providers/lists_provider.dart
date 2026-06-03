import 'package:flutter/material.dart';
import '../../../core/models/user_list.dart';
import '../../../core/services/api_service.dart';

class ListsProvider extends ChangeNotifier {
  final _api = ApiService();

  List<UserList> _lists = [];
  UserList? _current;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<UserList> get lists => _lists;
  UserList? get current => _current;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> loadLists() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/lists');
      final items = res['data'] as List<dynamic>;
      _lists = items.map((e) => UserList.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) {
          if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
          return a.name.compareTo(b.name);
        });
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadListDetail(int listId) async {
    _loading = true;
    _current = null;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/lists/$listId');
      _current = UserList.fromJson(res['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UserList?> createList(String name, String description) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/api/lists', data: {
        'name': name.trim(),
        'description': description.trim(),
      });
      final list = UserList.fromJson(res['data'] as Map<String, dynamic>);
      _lists.insert(0, list);
      _saving = false;
      notifyListeners();
      return list;
    } on ApiException catch (e) {
      _error = e.message;
      _saving = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateList(int listId, String name, String description) async {
    _saving = true;
    notifyListeners();
    try {
      final res = await _api.put('/api/lists/$listId', data: {
        'name': name.trim(),
        'description': description.trim(),
      });
      final updated = UserList.fromJson(res['data'] as Map<String, dynamic>);
      final idx = _lists.indexWhere((l) => l.id == listId);
      if (idx >= 0) _lists[idx] = updated;
      if (_current?.id == listId) _current = updated;
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

  Future<bool> deleteList(int listId) async {
    try {
      await _api.delete('/api/lists/$listId');
      _lists.removeWhere((l) => l.id == listId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(int listId, int itemId, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/lists/$listId/items/$itemId', data: data);
      await loadListDetail(listId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int listId, int itemId) async {
    try {
      await _api.delete('/api/lists/$listId/items/$itemId');
      await loadListDetail(listId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
