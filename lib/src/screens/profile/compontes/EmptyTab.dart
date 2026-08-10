import 'package:flutter/material.dart';
import '../../../constants.dart';

class EmptyTab extends StatelessWidget {
  const EmptyTab({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}