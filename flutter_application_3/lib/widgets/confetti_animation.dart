import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiAnimation extends StatefulWidget {
  const ConfettiAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.particleCount = 50,
  });

  final Widget child;
  final Duration duration;
  final int particleCount;

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(widget.particleCount, (index) {
      return ConfettiParticle(
        color: _randomColor(),
        startX: _random.nextDouble() * 2 - 1,
        startY: -0.1,
        endX: _random.nextDouble() * 2 - 1,
        endY: 1.2 + _random.nextDouble() * 0.3,
        rotation: _random.nextDouble() * 4 * pi,
        size: 4 + _random.nextDouble() * 8,
      );
    });

    _controller.forward();
  }

  Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ConfettiPainter(
                particles: _particles,
                progress: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      // Calculate position with some randomness
      final x = size.width / 2 +
          (particle.startX + (particle.endX - particle.startX) * progress) *
              size.width /
              2;
      final y = (particle.startY + (particle.endY - particle.startY) * progress) *
          size.height;

      // Add wobble effect
      final wobble = sin(progress * 4 * pi) * 20;

      canvas.save();
      canvas.translate(x + wobble, y);
      canvas.rotate(particle.rotation * progress);

      // Draw confetti piece (rectangle or circle)
      if (particle.size > 8) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.5,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Helper to show confetti overlay
void showConfettiOverlay(BuildContext context, {Duration duration = const Duration(seconds: 2)}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => ConfettiAnimation(
      duration: duration,
      child: const SizedBox.expand(),
    ),
  );

  overlay.insert(entry);

  Future.delayed(duration, () {
    entry.remove();
  });
}
