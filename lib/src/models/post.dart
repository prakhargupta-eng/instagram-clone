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

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      author: AppUser.fromJson(json['author']),
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.toJson(),
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Post {
  final String id;
  final AppUser author;
  final String imageUrl;
  final String videoUrl;
  final String caption;
  final String? location;
  final String? music;
  final String? musicPreviewUrl;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<Comment> comments;
  final bool isVideo;
  final int filterIndex;
  final double brightness;
  final double contrast;
  final double saturation;

  const Post({
    required this.id,
    required this.author,
    this.imageUrl = '',
    required this.caption,
    required this.createdAt,
    this.videoUrl = '',
    this.location,
    this.music,
    this.musicPreviewUrl,
    this.likedBy = const [],
    this.comments = const [],
    this.isVideo = false,
    this.filterIndex = 0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  int get likes => likedBy.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

  factory Post.fromJson(Map<String, dynamic> json, {AppUser? author}) {
    return Post(
      id: json['id'],
      author: author ?? AppUser.fromJson(json['author']),
      imageUrl: json['imageUrl'] ?? json['path'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      caption: json['caption'] ?? '',
      location: json['location'],
      music: json['music'],
      musicPreviewUrl: json['musicPreviewUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      likedBy: List<String>.from(json['likedBy'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
      isVideo: json['isVideo'] ?? false,
      filterIndex: json['filterIndex'] ?? 0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.toJson(),
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'caption': caption,
        'location': location,
        'music': music,
        'musicPreviewUrl': musicPreviewUrl,
        'createdAt': createdAt.toIso8601String(),
        'likedBy': likedBy,
        'comments': comments.map((c) => c.toJson()).toList(),
        'isVideo': isVideo,
        'filterIndex': filterIndex,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
      };

  Post copyWith({
    String? imageUrl,
    String? caption,
    String? location,
    String? music,
    String? musicPreviewUrl,
    List<String>? likedBy,
    List<Comment>? comments,
    String? videoUrl,
    bool? isVideo,
    int? filterIndex,
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    return Post(
      id: id,
      author: author,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      music: music ?? this.music,
      musicPreviewUrl: musicPreviewUrl ?? this.musicPreviewUrl,
      createdAt: createdAt,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      isVideo: isVideo ?? this.isVideo,
      filterIndex: filterIndex ?? this.filterIndex,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
    );
  }
}
