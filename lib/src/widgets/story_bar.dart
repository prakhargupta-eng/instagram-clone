import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'avatar.dart';

class StoryBar extends StatelessWidget {
  const StoryBar({
    super.key,
    required this.stories,
    required this.currentUser,
    this.onAddStory,
  });

  final List<Story> stories;
  final AppUser currentUser;
  final VoidCallback? onAddStory;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                _StoryAvatar(
                  label: AppStrings.yourStory,
                  avatar: Avatar(
                    url: currentUser.avatarUrl,
                    radius: 32,
                    showRing: false,
                  ),
                  isAdd: true,
                  onTap: onAddStory ?? () {},
                ),
                const SizedBox(width: 4),
                for (final story in stories)
                  _StoryAvatar(
                    label: story.user.username,
                    avatar: Avatar(
                      url: story.user.avatarUrl,
                      radius: 30,
                      showRing: true,
                      gradientRing: true,
                      ringWidth: 2.5,
                    ),
                    onTap: () {},
                  ),
              ],
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
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
                style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
