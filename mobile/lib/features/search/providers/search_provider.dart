import 'package:flutter/material.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/person_result.dart';
import '../../../core/services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  final _api = ApiService();

  List<TmdbResult> _results = [];
  List<PersonResult> _personResults = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  String _type = 'movie';
  int _page = 1;
  int _totalPages = 1;

  List<TmdbResult> get results => _results;
  List<PersonResult> get personResults => _personResults;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  String get type => _type;
  bool get hasMore => _page < _totalPages;

  void setType(String type) {
    _type = type;
    notifyListeners();
    if (_query.isNotEmpty) search(_query, reset: true);
  }

  Future<void> search(String query, {bool reset = false}) async {
    if (query.trim().isEmpty) {
      _results = [];
      _personResults = [];
      _query = '';
      notifyListeners();
      return;
    }

    if (reset || query != _query) {
      _results = [];
      _personResults = [];
      _page = 1;
      _totalPages = 1;
    }

    _query = query;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get('/api/search', params: {
        'q': query.trim(),
        'type': _type,
        'page': _page,
      });
      final data = res['data'] as Map<String, dynamic>;
      final items = data['results'] as List<dynamic>;
      _totalPages = data['total_pages'] as int? ?? 1;

      if (_type == 'person') {
        final parsed = items
            .map((e) => PersonResult.fromJson(e as Map<String, dynamic>))
            .toList();
        if (_page == 1) {
          _personResults = parsed;
        } else {
          _personResults = [..._personResults, ...parsed];
        }
      } else {
        final parsed = items
            .map((e) => TmdbResult.fromJson(e as Map<String, dynamic>, type: _type))
            .toList();
        if (_page == 1) {
          _results = parsed;
        } else {
          _results = [..._results, ...parsed];
        }
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    _page++;
    await search(_query);
  }

  void clear() {
    _results = [];
    _personResults = [];
    _query = '';
    _page = 1;
    _totalPages = 1;
    _error = null;
    notifyListeners();
  }
}
