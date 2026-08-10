import 'user.dart';

class Story {
  final String id;
  final AppUser user;
  final String imageUrl;
  final bool isVideo;
  final Duration duration;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.user,
    required this.imageUrl,
    this.isVideo = false,
    this.duration = const Duration(seconds: 5),
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      user: AppUser.fromJson(json['user']),
      imageUrl: json['imageUrl'] ?? '',
      isVideo: json['isVideo'] ?? false,
      duration: Duration(seconds: json['durationSeconds'] ?? 5),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user.toJson(),
        'imageUrl': imageUrl,
        'isVideo': isVideo,
        'durationSeconds': duration.inSeconds,
        'createdAt': createdAt.toIso8601String(),
      };
}
