import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../compontes/ToastHelper.dart';

class ShareHelper {
  /// Copies the user's profile URL to the system clipboard and shows a toast notification.
  static Future<void> copyProfileLink(
    BuildContext context,
    String username,
  ) async {
    final profileUrl = 'https://instagram.com/$username';
    await Clipboard.setData(ClipboardData(text: profileUrl));
    if (context.mounted) {
      ToastHelper.showToast(context, 'Profile link copied');
    }
  }
}
