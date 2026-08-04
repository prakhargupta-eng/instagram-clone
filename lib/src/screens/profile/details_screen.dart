import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/post.dart';
import '../../services/feed_service.dart';
import '../../widgets/media_image.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.post, required this.feedService});

  final Post post;
  final FeedService feedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
            onPressed: () {
              feedService.deletePost(post.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: Hero(
            tag: 'post_image_${post.id}',
            child: MediaImage(
              path: post.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, e, st) => Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}