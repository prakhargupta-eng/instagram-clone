import 'user.dart';

class Comment {
  final String id;
  final AppUser author;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });
}

class Post {
  final String id;
  final AppUser author;
  final String imageUrl;
  final String videoUrl;
  final String caption;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<Comment> comments;
  final bool isVideo;

  const Post({
    required this.id,
    required this.author,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    this.videoUrl = '',
    this.likedBy = const [],
    this.comments = const [],
    this.isVideo = false,
  });

  int get likes => likedBy.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

  Post copyWith({
    String? imageUrl,
    String? caption,
    List<String>? likedBy,
    List<Comment>? comments,
    String? videoUrl,
    bool? isVideo,
  }) {
    return Post(
      id: id,
      author: author,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}
