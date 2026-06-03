class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? createdAt;
  final String role;
  final bool deletionRequested;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.createdAt,
    this.role = 'user',
    this.deletionRequested = false,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: int.parse(json['id'].toString()),
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] as String?,
        role: json['role'] as String? ?? 'user',
        deletionRequested: json['deletion_requested_at'] != null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'created_at': createdAt,
        'role': role,
        'deletion_requested_at': deletionRequested ? '1' : null,
      };

  User copyWith({String? name, String? email, String? avatarUrl, bool? deletionRequested}) => User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
        role: role,
        deletionRequested: deletionRequested ?? this.deletionRequested,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
