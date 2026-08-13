import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';

class CaptionOption extends StatelessWidget {
  const CaptionOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: context.textPrimaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: context.textPrimaryColor),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: context.textSecondaryColor,
                ),
          ],
        ),
      ),
    );
  }
}
