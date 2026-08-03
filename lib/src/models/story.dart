import 'user.dart';

class Story {
  final String id;
  final AppUser user;
  final String imageUrl;
  final bool isVideo;
  final Duration duration;

  const Story({
    required this.id,
    required this.user,
    required this.imageUrl,
    this.isVideo = false,
    this.duration = const Duration(seconds: 5),
  });
}
