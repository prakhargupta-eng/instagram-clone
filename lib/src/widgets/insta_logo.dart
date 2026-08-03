import 'package:flutter/material.dart';

import '../constants.dart';

class InstaLogo extends StatelessWidget {
  const InstaLogo({super.key, this.size = 80, this.withIcon = true});

  static const String assetPath = 'lib/src/asserts/instagram.png';

  final double size;
  final bool withIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (withIcon)
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
          ),
        SizedBox(height: size * 0.3),
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
