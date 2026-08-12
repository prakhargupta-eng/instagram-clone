import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ShaderFilterWidget extends StatefulWidget {
  const ShaderFilterWidget({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<ShaderFilterWidget> createState() => _ShaderFilterWidgetState();
}

class _ShaderFilterWidgetState extends State<ShaderFilterWidget>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final AnimationController _timeController;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _time = _timeController.value * 10.0;
        });
      });

    if (widget.enabled) {
      _timeController.repeat();
      _loadShader();
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/retro.frag',
      );
      setState(() {
        _program = program;
      });
    } catch (e) {
      debugPrint('Failed to load fragment shader: $e');
    }
  }

  @override
  void didUpdateWidget(ShaderFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _timeController.repeat();
      if (_program == null) {
        _loadShader();
      }
    } else if (!widget.enabled && oldWidget.enabled) {
      _timeController.stop();
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _program == null) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ShaderPainter(
                shader: _program!.fragmentShader(),
                time: _time,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _ShaderPainter({required this.shader, required this.time});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // Pass size uniform (uSize)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // Pass time uniform (uTime)
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
