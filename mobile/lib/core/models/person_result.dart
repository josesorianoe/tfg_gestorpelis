class PersonResult {
  final int id;
  final String name;
  final String? profilePath;
  final String? knownForDepartment;

  const PersonResult({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownForDepartment,
  });

  factory PersonResult.fromJson(Map<String, dynamic> json) => PersonResult(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        profilePath: json['profile_path'] as String?,
        knownForDepartment: json['known_for_department'] as String?,
      );

  String get fullProfileUrl =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : '';

  String get departmentLabel {
    switch (knownForDepartment) {
      case 'Acting':
        return 'Actor/Actriz';
      case 'Directing':
        return 'Director/a';
      case 'Writing':
        return 'Guionista';
      case 'Production':
        return 'Productor/a';
      case 'Camera':
        return 'Fotografía';
      case 'Sound':
        return 'Sonido';
      default:
        return knownForDepartment ?? '';
    }
  }
}
