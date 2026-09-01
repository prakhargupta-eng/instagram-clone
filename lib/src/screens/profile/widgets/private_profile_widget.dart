import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';

class PrivateProfileWidget extends StatelessWidget {
  const PrivateProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: context.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'This account is private',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow this account to see their photos and videos.',
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
