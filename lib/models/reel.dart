import 'dart:convert';

class Reel {
  final String id;
  final String videoUrl;
  final String title;
  final String description;
  final String category;
  final String? appLink;
  final int likes;
  final int comments;
  final int views; // NEW
  final DateTime createdAt;
  final bool isLiked;
  final bool isSaved; 
  final String? logoUrl;
  final String? thumbnailUrl;
  final String? userId;
  final bool isPaid;
  final double price;
  final bool isSingleImage;

  Reel({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.category,
    this.appLink,
    this.likes = 0,
    this.comments = 0,
    this.views = 0, // NEW
    required this.createdAt,
    this.isLiked = false,
    this.isSaved = false,
    this.logoUrl,
    this.thumbnailUrl,
    this.userId,
    this.isPaid = false,
    this.price = 0.0,
    this.isSingleImage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'video_url': videoUrl,
      'title': title,
      'description': description,
      'category': category,
      'app_link': appLink,
      'like_count': likes,
      'comment_count': comments,
      'view_count': views, // NEW
      'created_at': createdAt.toIso8601String(),
      'is_liked': isLiked,
      'is_saved': isSaved,
      'logo_url': logoUrl,
      'thumbnail_url': thumbnailUrl,
      'user': userId, 
      'is_paid': isPaid,
      'price': price,
      'is_single_image': isSingleImage,
    };
  }

  factory Reel.fromMap(Map<String, dynamic> map) {
    return Reel(
      id: map['id'] ?? map['_id'] ?? '',
      videoUrl: map['video_url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'All',
      appLink: map['app_link'],
      likes: map['like_count']?.toInt() ?? 0,
      comments: map['comment_count']?.toInt() ?? 0,
      views: map['view_count']?.toInt() ?? 0, // NEW
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isLiked: map['is_liked'] == true,
      isSaved: map['is_saved'] == true,
      logoUrl: map['logo_url'],
      thumbnailUrl: map['thumbnail_url'],
      userId: map['user'] is String ? map['user'] : (map['user'] is Map ? map['user']['_id'] : null),
      isPaid: map['is_paid'] == true,
      price: (map['price'] ?? 0).toDouble(),
      isSingleImage: map['is_single_image'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory Reel.fromJson(String source) => Reel.fromMap(json.decode(source));
}
