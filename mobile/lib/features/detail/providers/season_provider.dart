import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class SeasonProvider extends ChangeNotifier {
  final _api = ApiService();

  Set<String> _watched = {};
  List<dynamic> _episodes = [];
  int _currentSeason = 0;
  bool _loadingSeason = false;
  String? _error;

  Set<String> get watched => _watched;
  List<dynamic> get episodes => _episodes;
  int get currentSeason => _currentSeason;
  bool get loadingSeason => _loadingSeason;
  String? get error => _error;

  int get watchedTotal => _watched.length;

  bool isWatched(int season, int episode) => _watched.contains('s${season}e$episode');

  int watchedCount(int season) => _episodes
      .where((e) => isWatched(season, (e['episode_number'] as num?)?.toInt() ?? 0))
      .length;

  Future<void> loadProgress(int tmdbId) async {
    try {
      final res = await _api.get('/api/tv/$tmdbId/progress');
      final list = res['data'] as List<dynamic>;
      _watched = list.map((e) {
        final s  = int.parse(e['season_number'].toString());
        final ep = int.parse(e['episode_number'].toString());
        return 's${s}e$ep';
      }).toSet();
      notifyListeners();
    } on ApiException catch (_) {}
  }

  Future<void> loadSeason(int tmdbId, int seasonNumber) async {
    if (_currentSeason == seasonNumber && _episodes.isNotEmpty) return;
    _currentSeason = seasonNumber;
    _loadingSeason = true;
    _episodes = [];
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/tv/$tmdbId/season/$seasonNumber');
      final data = res['data'] as Map<String, dynamic>;
      _episodes = (data['episodes'] as List<dynamic>?) ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loadingSeason = false;
      notifyListeners();
    }
  }

  Future<void> toggleEpisode(int tmdbId, int season, int episode) async {
    final key = 's${season}e$episode';
    final wasWatched = _watched.contains(key);
    _watched = wasWatched
        ? (Set.from(_watched)..remove(key))
        : (Set.from(_watched)..add(key));
    notifyListeners();
    try {
      await _api.post('/api/tv/$tmdbId/progress', data: {
        'season_number': season,
        'episode_number': episode,
      });
    } on ApiException catch (_) {
      _watched = wasWatched
          ? (Set.from(_watched)..add(key))
          : (Set.from(_watched)..remove(key));
      notifyListeners();
    }
  }
}
