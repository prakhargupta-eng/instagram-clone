import 'package:flutter/material.dart';
import '../adaptive_colors.dart';
import '../app.dart';
import '../constants.dart';
import '../models/story.dart';
import '../models/user.dart';
import '../screens/home/story_viewer_screen.dart';
import '../services/feed_service.dart';
import 'avatar.dart';

class StoryBar extends StatelessWidget {
  const StoryBar({
    super.key,
    required this.stories,
    required this.currentUser,
    required this.feedService,
    this.onAddStory,
  });

  final List<Story> stories;
  final AppUser currentUser;
  final FeedService feedService;
  final VoidCallback? onAddStory;

  @override
  Widget build(BuildContext context) {
    final currentUserStories = stories
        .where((s) => s.user.id == currentUser.id)
        .toList();
    final hasStory = currentUserStories.isNotEmpty;
    final hasUnwatched = feedService.hasUnwatchedStories(currentUser.id);
    final isDarkMode = isDark(context);

    return Container(
      color: context.surfaceColor,
      child: Column(
        children: [
          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                _StoryAvatar(
                  label: AppStrings.yourStory,
                  avatar: Avatar(
                    url: currentUser.avatarUrl,
                    radius: 32,
                    showRing: hasStory,
                    gradientRing: hasUnwatched,
                    ringColor: hasUnwatched
                        ? AppColors.storyRingDefault
                        : (isDarkMode
                              ? const Color(0xFF363636)
                              : Colors.grey.shade300),
                    ringWidth: 2.5,
                  ),
                  isAdd: !hasStory,
                  onTap: () {
                    if (hasStory) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen(
                            stories: stories,
                            initialIndex: stories.indexOf(
                              currentUserStories.first,
                            ),
                            feedService: feedService,
                          ),
                        ),
                      );
                    } else {
                      if (onAddStory != null) onAddStory!();
                    }
                  },
                ),
                const SizedBox(width: 4),
                for (final story in stories)
                  if (story.user.id != currentUser.id)
                    _StoryAvatar(
                      label: story.user.username,
                      avatar: Avatar(
                        url: story.user.avatarUrl,
                        radius: 30,
                        showRing: true,
                        gradientRing: feedService.hasUnwatchedStories(
                          story.user.id,
                        ),
                        ringColor:
                            feedService.hasUnwatchedStories(story.user.id)
                            ? AppColors.storyRingDefault
                            : (isDarkMode
                                  ? const Color(0xFF363636)
                                  : Colors.grey.shade300),
                        ringWidth: 2.5,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryViewerScreen(
                              stories: stories,
                              initialIndex: stories.indexOf(story),
                              feedService: feedService,
                            ),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
          Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
        ],
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({
    required this.label,
    required this.avatar,
    required this.onTap,
    this.isAdd = false,
  });

  final String label;
  final Widget avatar;
  final VoidCallback onTap;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                avatar,
                if (isAdd)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: context.surfaceColor, width: 2),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 66,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
