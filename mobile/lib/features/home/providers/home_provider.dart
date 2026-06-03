import 'package:flutter/material.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/user_list.dart';
import '../../../core/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  final _api = ApiService();

  List<TmdbResult> _discover = [];
  List<UserList> _listsWithItems = [];
  bool _loading = false;
  String? _error;

  List<TmdbResult> get discover => _discover;
  List<UserList> get listsWithItems => _listsWithItems;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadDiscover(), _loadLists()]);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _discover = [];
    _listsWithItems = [];
    await load();
  }

  Future<void> refreshLists() async {
    try {
      await _loadLists();
    } on ApiException catch (_) {}
    notifyListeners();
  }

  Future<void> _loadDiscover() async {
    final res = await _api.get('/api/catalog/discover', params: {'type': 'movie'});
    final data = res['data'] as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    _discover = results
        .map((e) => TmdbResult.fromJson(e as Map<String, dynamic>, type: 'movie'))
        .toList();
  }

  Future<void> _loadLists() async {
    final res = await _api.get('/api/lists');
    final rawLists = (res['data'] as List<dynamic>)
        .map((e) => UserList.fromJson(e as Map<String, dynamic>))
        .toList();

    const defaultOrder = {'Series que estoy viendo': 0, 'Pendientes por ver': 1};

    final populated = rawLists.where((l) => l.apiItemCount > 0).toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        if (a.isDefault && b.isDefault) {
          final oa = defaultOrder[a.name] ?? 99;
          final ob = defaultOrder[b.name] ?? 99;
          if (oa != ob) return oa.compareTo(ob);
        }
        return a.name.compareTo(b.name);
      });

    if (populated.isEmpty) {
      _listsWithItems = [];
      return;
    }

    final details = await Future.wait(
      populated.map((l) => _api.get('/api/lists/${l.id}')),
    );

    _listsWithItems = details
        .map((r) => UserList.fromJson(r['data'] as Map<String, dynamic>))
        .toList();
  }
}
