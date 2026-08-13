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
    final authorJson = json['author'] ?? json['user'];
    final authorMap = (authorJson is Map<String, dynamic>)
        ? authorJson
        : <String, dynamic>{'id': json['userId'] ?? ''};
    return Comment(
      id: (json['id'] ?? '').toString(),
      author: AppUser.fromJson(authorMap),
      text: (json['text'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
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
  final List<AppUser> taggedUsers;
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
    this.taggedUsers = const [],
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
    final authorJson = json['author'] ?? json['user'];
    final parsedAuthor = author ??
        ((authorJson is Map<String, dynamic>)
            ? AppUser.fromJson(authorJson)
            : AppUser(
                id: (json['authorId'] ?? '').toString(),
                username: 'user',
                fullName: 'User',
                email: '',
                bio: '',
                avatarUrl: '',
              ));

    // Handle likes (array of strings OR array of objects like {userId: ...})
    final List<String> likedByList = [];
    if (json['likedBy'] is List) {
      for (final item in (json['likedBy'] as List)) {
        if (item != null) likedByList.add(item.toString());
      }
    } else if (json['likes'] is List) {
      for (final item in (json['likes'] as List)) {
        if (item is Map) {
          final uId = item['userId'] ?? item['id'];
          if (uId != null) likedByList.add(uId.toString());
        } else if (item != null) {
          likedByList.add(item.toString());
        }
      }
    }

    // Handle taggedUsers
    final List<AppUser> tagged = [];
    if (json['taggedUsers'] is List) {
      for (final item in (json['taggedUsers'] as List)) {
        if (item is Map<String, dynamic>) {
          tagged.add(AppUser.fromJson(item));
        }
      }
    }

    return Post(
      id: (json['id'] ?? '').toString(),
      author: parsedAuthor,
      imageUrl: (json['imageUrl'] ?? json['path'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      location: json['location']?.toString(),
      music: json['music']?.toString(),
      musicPreviewUrl: json['musicPreviewUrl']?.toString(),
      taggedUsers: tagged,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      likedBy: likedByList,
      comments: (json['comments'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Comment.fromJson(e))
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
        'taggedUsers': taggedUsers.map((u) => u.toJson()).toList(),
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
    List<AppUser>? taggedUsers,
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
      taggedUsers: taggedUsers ?? this.taggedUsers,
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
