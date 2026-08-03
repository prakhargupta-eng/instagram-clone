import 'package:flutter/material.dart';

import '../constants.dart';

class Avatar extends StatelessWidget {
  final String? url;
  final double radius;
  final bool showRing;
  final Color ringColor;
  final double ringWidth;
  final bool gradientRing;

  const Avatar({
    super.key,
    this.url,
    this.radius = 24,
    this.showRing = false,
    this.ringColor = AppColors.storyRingDefault,
    this.ringWidth = 2.5,
    this.gradientRing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showRing && gradientRing) {
      return CustomPaint(
        painter: _GradientRingPainter(ringWidth: ringWidth),
        child: Padding(
          padding: EdgeInsets.all(ringWidth + 3),
          child: ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: _image(),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(showRing ? ringWidth : 0),
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: ringWidth),
            )
          : null,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: _image(),
        ),
      ),
    );
  }

  Widget _image() {
    return url != null
        ? Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.avatarFallback,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppColors.white, size: 20),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double ringWidth;

  _GradientRingPainter({required this.ringWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = const SweepGradient(
      colors: [
        Color(0xFFFEDA75),
        Color(0xFFFA7E1E),
        Color(0xFFD62976),
        Color(0xFF962FBF),
        Color(0xFF4F5BD5),
        Color(0xFFFEDA75),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth + 2;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width / 2) - (ringWidth + 2) / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
