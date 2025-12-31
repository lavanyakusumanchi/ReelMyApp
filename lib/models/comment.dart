import 'dart:convert';

class Comment {
  final String id;
  final String reelId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String userName; // Added for UI display
  final int likes;
  final bool isLiked;

  Comment({
    required this.id,
    required this.reelId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.userName = 'User', // Default or from backend
    this.likes = 0,
    this.isLiked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reel_id': reelId,
      'user_id': userId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? map['_id'] ?? '',
      reelId: map['reel_id'] ?? '',
      userId: map['user_id'] ?? '',
      text: map['text'] ?? '',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      userName: map['user_name'] ?? 'User',
      likes: map['likes'] ?? 0,
      isLiked: map['is_liked'] ?? false, // Mapped from backend response or manually set
    );
  }

  String toJson() => json.encode(toMap());

  factory Comment.fromJson(dynamic source) {
     if (source is String) {
        return Comment.fromMap(json.decode(source));
     } else {
        return Comment.fromMap(source);
     }
  }
}
