import 'package:flutter/material.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/user_list.dart';
import '../../../core/services/api_service.dart';

class DetailProvider extends ChangeNotifier {
  final _api = ApiService();

  Map<String, dynamic>? _detail;
  List<UserList> _userLists = [];
  bool _loading = false;
  bool _addingToList = false;
  String? _error;
  String? _addError;
  bool _isInList = false;
  bool _inNonDefaultList = false;
  String? _currentListName;
  int? _currentListId;
  double? _userRating;
  String _userNote = '';
  bool _savingReview = false;
  String? _reviewError;
  bool _listChanged = false;

  Map<String, dynamic>? get detail => _detail;
  List<UserList> get userLists => _userLists;
  bool get loading => _loading;
  bool get addingToList => _addingToList;
  String? get error => _error;
  String? get addError => _addError;
  bool get isInList => _isInList;
  bool get inNonDefaultList => _inNonDefaultList;
  bool get isOnlyInPending => _isInList && !_inNonDefaultList;
  String? get currentListName => _currentListName;
  int? get currentListId => _currentListId;
  double? get userRating => _userRating;
  String get userNote => _userNote;
  bool get savingReview => _savingReview;
  String? get reviewError => _reviewError;
  bool get listChanged => _listChanged;

  Future<void> loadDetail(int tmdbId, String type) async {
    _loading = true;
    _detail = null;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/media/$tmdbId', params: {'type': type});
      _detail = res['data'] as Map<String, dynamic>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserLists() async {
    notifyListeners();
    try {
      final res = await _api.get('/api/lists');
      final items = res['data'] as List<dynamic>;
      _userLists = items
          .map((e) => UserList.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (_) {
      _userLists = [];
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMediaStatus(int tmdbId, String type) async {
    try {
      final res = await _api.get('/api/user/media/$tmdbId', params: {'type': type});
      final data = res['data'] as Map<String, dynamic>;
      _isInList         = data['in_list'] == true;
      _inNonDefaultList = data['in_non_default_list'] == true;
      _currentListName  = data['current_list_name'] as String?;
      _currentListId    = data['current_list_id'] != null ? int.tryParse(data['current_list_id'].toString()) : null;
      _userRating       = data['user_rating'] != null ? double.tryParse(data['user_rating'].toString()) : null;
      _userNote         = data['user_note'] as String? ?? '';
    } on ApiException catch (_) {
      _isInList = false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> addToList(int listId, int tmdbId, String mediaType, {bool isDefault = false, String listName = ''}) async {
    _addingToList = true;
    _addError = null;
    notifyListeners();
    try {
      await _api.post('/api/lists/$listId/items', data: {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
      });
      _isInList = true;
      _inNonDefaultList = !isDefault;
      _currentListName  = listName;
      _currentListId    = listId;
      _listChanged      = true;
      return true;
    } on ApiException catch (e) {
      _addError = e.message;
      return false;
    } finally {
      _addingToList = false;
      notifyListeners();
    }
  }

  Future<bool> removeFromAllLists(int tmdbId, String type) async {
    _addError = null;
    notifyListeners();
    try {
      await _api.delete('/api/user/media/$tmdbId?type=$type');
      _isInList         = false;
      _inNonDefaultList = false;
      _currentListName  = null;
      _currentListId    = null;
      _listChanged      = true;
      return true;
    } on ApiException catch (e) {
      _addError = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createListAndAdd(String listName, int tmdbId, String mediaType) async {
    _addError = null;
    try {
      final res = await _api.post('/api/lists', data: {'name': listName, 'description': ''});
      final listId = int.parse((res['data'] as Map<String, dynamic>)['id'].toString());
      return await addToList(listId, tmdbId, mediaType, isDefault: false, listName: listName);
    } on ApiException catch (e) {
      _addError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> addToHistory(int tmdbId, String mediaType, DateTime watchedOn) async {
    final d = _detail;
    if (d == null) return;
    final title      = d['title'] as String? ?? d['name'] as String? ?? '';
    final posterPath = d['poster_path'] as String?;
    final dateStr    =
        '${watchedOn.year}-${watchedOn.month.toString().padLeft(2, '0')}-${watchedOn.day.toString().padLeft(2, '0')}';
    try {
      await _api.post('/api/history', data: {
        'tmdb_id':     tmdbId,
        'media_type':  mediaType,
        'title':       title,
        'poster_path': posterPath,
        'watched_on':  dateStr,
      });
    } on ApiException catch (_) {}
  }

  Future<bool> markAllEpisodesWatched(int tmdbId) async {
    try {
      await _api.post('/api/tv/$tmdbId/progress/all', data: {});
      return true;
    } on ApiException catch (e) {
      _addError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveReview(int tmdbId, String type, double? rating, String note) async {
    _savingReview = true;
    _reviewError  = null;
    notifyListeners();
    try {
      await _api.put('/api/user/media/$tmdbId', data: {
        'type':        type,
        'user_rating': rating,
        'user_note':   note,
      });
      _userRating = rating;
      _userNote   = note;
      return true;
    } on ApiException catch (e) {
      _reviewError = e.message;
      return false;
    } finally {
      _savingReview = false;
      notifyListeners();
    }
  }

  TmdbResult? get asResult {
    if (_detail == null) return null;
    return TmdbResult.fromJson(_detail!);
  }
}
