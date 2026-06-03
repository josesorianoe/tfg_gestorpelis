import 'list_item.dart';

class UserList {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final bool isPublic;
  final bool isDefault;
  final String? mediaType;
  final String? createdAt;
  final List<ListItem>? items;
  final int apiItemCount;

  const UserList({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isPublic = false,
    this.isDefault = false,
    this.mediaType,
    this.createdAt,
    this.items,
    this.apiItemCount = 0,
  });

  factory UserList.fromJson(Map<String, dynamic> json) => UserList(
        id: int.parse(json['id'].toString()),
        userId: int.parse(json['user_id'].toString()),
        name: json['name'] as String,
        description: json['description'] as String?,
        isPublic: json['is_public'] == true || json['is_public'] == 1 || json['is_public'] == 't',
        isDefault: json['is_default'] == true || json['is_default'] == 1 || json['is_default'] == 't',
        mediaType: json['media_type'] as String?,
        createdAt: json['created_at'] as String?,
        apiItemCount: json['item_count'] != null ? int.parse(json['item_count'].toString()) : 0,
        items: (json['items'] as List<dynamic>?)
            ?.map((e) => ListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get itemCount => items?.length ?? apiItemCount;
}
