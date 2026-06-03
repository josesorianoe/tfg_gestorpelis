import 'media_item.dart';

class ListItem {
  final int id;
  final int listId;
  final int mediaItemId;
  final bool watched;
  final double? userRating;
  final String? userNote;
  final String? addedAt;
  final MediaItem? mediaItem;

  const ListItem({
    required this.id,
    required this.listId,
    required this.mediaItemId,
    this.watched = false,
    this.userRating,
    this.userNote,
    this.addedAt,
    this.mediaItem,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
        id: int.parse(json['id'].toString()),
        listId: int.parse(json['list_id'].toString()),
        mediaItemId: int.parse(json['media_item_id'].toString()),
        watched: json['watched'] == true || json['watched'] == 1 || json['watched'] == 't',
        userRating: json['user_rating'] != null ? double.tryParse(json['user_rating'].toString()) : null,
        userNote: json['user_note'] as String?,
        addedAt: json['added_at'] as String?,
        mediaItem: json['media_item'] != null
            ? MediaItem.fromJson(json['media_item'] as Map<String, dynamic>)
            : null,
      );

  ListItem copyWith({bool? watched, double? userRating, String? userNote}) => ListItem(
        id: id,
        listId: listId,
        mediaItemId: mediaItemId,
        watched: watched ?? this.watched,
        userRating: userRating ?? this.userRating,
        userNote: userNote ?? this.userNote,
        addedAt: addedAt,
        mediaItem: mediaItem,
      );
}
