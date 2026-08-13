import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';
import '../../../constants.dart';

class HeaderChip extends StatelessWidget {
  const HeaderChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.textPrimaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarSmall extends StatelessWidget {
  const AvatarSmall({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 32,
        height: 32,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const FallbackAvatar(),
              )
            : const FallbackAvatar(),
      ),
    );
  }
}

class FallbackAvatar extends StatelessWidget {
  const FallbackAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppColors.surface, size: 18),
    );
  }
}
