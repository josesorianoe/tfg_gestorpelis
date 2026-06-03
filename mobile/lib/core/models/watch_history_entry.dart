class WatchHistoryEntry {
  final int id;
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterPath;
  final DateTime watchedOn;

  const WatchHistoryEntry({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    required this.watchedOn,
  });

  String get fullPosterUrl =>
      posterPath != null && posterPath!.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w185$posterPath'
          : '';

  bool get isMovie => mediaType == 'movie';

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      WatchHistoryEntry(
        id: int.parse(json['id'].toString()),
        tmdbId: int.parse(json['tmdb_id'].toString()),
        mediaType: json['media_type'] as String,
        title: json['title'] as String,
        posterPath: json['poster_path'] as String?,
        watchedOn: DateTime.parse(json['watched_on'] as String),
      );
}
