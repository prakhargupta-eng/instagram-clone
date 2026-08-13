import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';
import '../../../models/post.dart';
import '../../../routes/app_routes.dart';
import '../../../services/feed_service.dart';
import '../../../widgets/media_image.dart';

class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.feedService,
    required this.post,
    required this.posts,
  });

  final FeedService feedService;
  final Post post;
  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.detail,
          arguments: {
            'post': post,
            'posts': posts,
            'feedService': feedService,
          },
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'post_image_${post.id}',
            child: Material(
              color: Colors.transparent,
              child: MediaImage(
                path: post.imageUrl,
                videoUrl: post.isVideo ? post.videoUrl : null,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: context.borderColor,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
          if (post.isVideo)
             Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.play_circle, color: context.textSecondaryColor, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}