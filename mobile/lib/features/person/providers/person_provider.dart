import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class PersonProvider extends ChangeNotifier {
  final _api = ApiService();

  Map<String, dynamic>? _person;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get person => _person;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(int personId) async {
    _loading = true;
    _person = null;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/person/$personId');
      _person = res['data'] as Map<String, dynamic>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
