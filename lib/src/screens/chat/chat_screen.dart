import 'package:flutter/material.dart';
import '../../adaptive_colors.dart';
import '../../constants.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.textPrimaryColor, width: 2),
              ),
              child:  Icon(
                Icons.send_outlined,
                size: 40,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
             Text(
              'Chat Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
             Text(
              'Direct messaging is coming soon!',
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
