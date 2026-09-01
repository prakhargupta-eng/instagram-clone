import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../adaptive_colors.dart';
import '../../../widgets/avatar.dart';
import '../../../utils/number_helper.dart';
import '../../../utils/share_helper.dart';
import '../../../components/ToastHelper.dart';
import 'Stat.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.displayUser,
    required this.liveUser,
    required this.postsCount,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.onEditProfile,
    required this.onToggleFollow,
  });

  final AppUser displayUser;
  final AppUser liveUser;
  final int postsCount;
  final bool isCurrentUser;
  final bool isFollowing;
  final VoidCallback onEditProfile;
  final VoidCallback onToggleFollow;

  String _buttonLabel(bool following) {
    if (following) return 'Following';
    if (displayUser.followers > 0) return 'Follow Back';
    return 'Follow';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(url: displayUser.avatarUrl, radius: 40),
            const SizedBox(width: 24),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Stat(
                    label: formatCount(
                      liveUser.postsCount > postsCount
                          ? liveUser.postsCount
                          : postsCount,
                    ),
                    value: 'Posts',
                  ),
                  Stat(
                    label: formatCount(liveUser.followers),
                    value: 'Followers',
                  ),
                  Stat(
                    label: formatCount(liveUser.following),
                    value: 'Following',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          displayUser.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (displayUser.bio.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            displayUser.bio,
            style: TextStyle(color: context.textSecondaryColor),
          ),
        ],
        if (displayUser.website.isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              ToastHelper.showToast(
                context,
                "Opening: ${displayUser.website}",
              );
            },
            child: Text(
              displayUser.website,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (isCurrentUser)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onEditProfile,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.borderColor,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Edit profile',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => ShareHelper.copyProfileLink(
                      context,
                      displayUser.username,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.borderColor,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Share profile',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            height: 32,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onToggleFollow,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: context.borderColor,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                _buttonLabel(isFollowing),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
