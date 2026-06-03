class MediaItem {
  final int id;
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;
  final double? userRating;

  const MediaItem({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
    this.userRating,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: int.parse(json['id'].toString()),
        tmdbId: int.parse(json['tmdb_id'].toString()),
        mediaType: json['media_type'] as String? ?? 'movie',
        title: json['title'] as String? ?? json['name'] as String? ?? '',
        overview: json['overview'] as String?,
        posterPath: json['poster_path'] as String?,
        backdropPath: json['backdrop_path'] as String?,
        releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
        voteAverage: json['vote_average'] != null ? double.tryParse(json['vote_average'].toString()) : null,
        userRating: json['user_rating'] != null ? double.tryParse(json['user_rating'].toString()) : null,
      );

  String get fullPosterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';

  String get fullBackdropUrl =>
      backdropPath != null ? 'https://image.tmdb.org/t/p/w780$backdropPath' : '';

  String get year =>
      (releaseDate != null && releaseDate!.length >= 4) ? releaseDate!.substring(0, 4) : '';
}

class TmdbResult {
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;

  const TmdbResult({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
  });

  factory TmdbResult.fromJson(Map<String, dynamic> json, {String type = 'movie'}) =>
      TmdbResult(
        tmdbId: json['id'] as int,
        mediaType: json['media_type'] as String? ?? type,
        title: json['title'] as String? ?? json['name'] as String? ?? '',
        overview: json['overview'] as String?,
        posterPath: json['poster_path'] as String?,
        backdropPath: json['backdrop_path'] as String?,
        releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
        voteAverage: json['vote_average'] != null ? double.tryParse(json['vote_average'].toString()) : null,
      );

  String get fullPosterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';

  String get year =>
      (releaseDate != null && releaseDate!.length >= 4) ? releaseDate!.substring(0, 4) : '';
}
