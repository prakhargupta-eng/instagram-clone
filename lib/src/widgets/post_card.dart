import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/post.dart';
import 'avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    this.onTapMedia,
  });

  final Post post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onTapMedia;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        _media(context),
        _actions(context),
        _likesText(context),
        _caption(context),
        _commentsPreview(context),
        _timestamp(context),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          Avatar(url: post.author.avatarUrl, radius: 18, showRing: false),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              post.author.username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 22, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _media(BuildContext context) {
    return GestureDetector(
      onTap: onTapMedia,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.border,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
              ),
            ),
          ),
          if (post.isVideo)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.white, size: 34),
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final isLiked = post.isLikedBy(currentUserId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          // Like button — use custom PNG asset, tinted red when liked
          GestureDetector(
            onTap: onLike,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/Heart.png',
                width: 26,
                height: 26,
                color: isLiked ? AppColors.error : AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.error : AppColors.textPrimary,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Comment button
          GestureDetector(
            onTap: onComment,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/comments.png',
                width: 24,
                height: 24,
                color: AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Share / Send button
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/forword.png',
                width: 24,
                height: 24,
                color: AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.send_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bookmark button
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'lib/src/asserts/bookmark.png',
                width: 22,
                height: 22,
                color: AppColors.textPrimary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.bookmark_border,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _likesText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: Text(
        '${_formatCount(post.likes)} ${AppStrings.likes}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 13.5,
        ),
      ),
    );
  }

  Widget _caption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.35),
          children: [
            TextSpan(
              text: '${post.author.username} ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: post.caption),
            const TextSpan(
              text: ' more',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentsPreview(BuildContext context) {
    if (post.comments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: GestureDetector(
        onTap: onComment,
        child: Text(
          'View all ${post.comments.length} comments',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _timestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Text(
        _relativeTime(post.createdAt),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final formatted = (count / 1000).toStringAsFixed(
        count % 1000 == 0 ? 0 : 3,
      );
      return '${formatted.replaceAll(RegExp(r'\.?0+$'), '')},${(count % 1000).toString().padLeft(3, '0')}';
    }
    return count.toString();
  }

  String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(time);
  }
}
