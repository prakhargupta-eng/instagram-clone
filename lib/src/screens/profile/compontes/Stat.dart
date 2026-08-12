import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';

class Stat extends StatelessWidget {
  const Stat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.textPrimaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}