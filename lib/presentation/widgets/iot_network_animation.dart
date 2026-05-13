import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class IoTNetworkAnimation extends StatefulWidget {
  const IoTNetworkAnimation({super.key});

  @override
  State<IoTNetworkAnimation> createState() => _IoTNetworkAnimationState();
}

class _IoTNetworkAnimationState extends State<IoTNetworkAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _packetController;
  late final AnimationController _driftController;

  final List<_Node> _nodes = [];
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    for (int i = 0; i < 14; i++) {
      _nodes.add(_Node(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 3.0 + _random.nextDouble() * 3,
        phase: _random.nextDouble() * 2 * pi,
        driftX: (_random.nextDouble() - 0.5) * 0.04,
        driftY: (_random.nextDouble() - 0.5) * 0.04,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _packetController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _packetController,
        _driftController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: _NetworkPainter(
            nodes: _nodes,
            pulseProgress: _pulseController.value,
            packetProgress: _packetController.value,
            driftProgress: _driftController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Node {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double driftX;
  final double driftY;

  const _Node({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.driftX,
    required this.driftY,
  });

  Offset position(Size size, double driftProgress) {
    final dx = x + driftX * sin(driftProgress * pi);
    final dy = y + driftY * cos(driftProgress * pi);
    return Offset(dx * size.width, dy * size.height);
  }
}

class _NetworkPainter extends CustomPainter {
  const _NetworkPainter({
    required this.nodes,
    required this.pulseProgress,
    required this.packetProgress,
    required this.driftProgress,
  });

  final List<_Node> nodes;
  final double pulseProgress;
  final double packetProgress;
  final double driftProgress;

  static const double _connectionThreshold = 0.38;
  static const Color _nodeColor = AppColors.secondary;
  static const Color _lineColor = AppColors.secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = nodes.map((n) => n.position(size, driftProgress)).toList();

    _drawConnections(canvas, size, positions);
    _drawNodes(canvas, positions);
  }

  void _drawConnections(Canvas canvas, Size size, List<Offset> positions) {
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final a = positions[i];
        final b = positions[j];
        final dist = (a - b).distance;
        final maxDist = size.width * _connectionThreshold;

        if (dist < maxDist) {
          final strength = 1 - (dist / maxDist);

          final linePaint = Paint()
            ..color = _lineColor.withValues(alpha: strength * 0.25)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

          canvas.drawLine(a, b, linePaint);

          _drawPacket(canvas, a, b, i, j, strength);
        }
      }
    }
  }

  void _drawPacket(Canvas canvas, Offset a, Offset b, int i, int j, double strength) {
    final offset = ((i * 7 + j * 13) % 100) / 100.0;
    final t = (packetProgress + offset) % 1.0;
    final pos = Offset.lerp(a, b, t)!;

    final packetPaint = Paint()
      ..color = _lineColor.withValues(alpha: strength * 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 2.0, packetPaint);
  }

  void _drawNodes(Canvas canvas, List<Offset> positions) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final pos = positions[i];
      final pulse = sin(pulseProgress * 2 * pi + node.phase);
      final glowRadius = node.size + 6 + pulse * 4;

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            _nodeColor.withValues(alpha: 0.35),
            _nodeColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: glowRadius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, glowRadius, glowPaint);

      final ringPaint = Paint()
        ..color = _nodeColor.withValues(alpha: 0.5 + pulse * 0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(pos, node.size + 3, ringPaint);

      final corePaint = Paint()
        ..color = _nodeColor.withValues(alpha: 0.85 + pulse * 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, node.size, corePaint);
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter old) =>
      old.pulseProgress != pulseProgress ||
      old.packetProgress != packetProgress ||
      old.driftProgress != driftProgress;
}
