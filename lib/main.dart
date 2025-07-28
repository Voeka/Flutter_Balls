import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Слайдовая презентация',
      home: const SlidePresentation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SlidePresentation extends StatefulWidget {
  const SlidePresentation({super.key});

  @override
  State<SlidePresentation> createState() => _SlidePresentationState();
}

class _SlidePresentationState extends State<SlidePresentation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Ball> balls = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 12),
      vsync: this,
    )
      ..addListener(_onAnimationTick)
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final rand = Random();
      final isMobile = size.width < 1000;
      final int ballCount = isMobile ? 50 : 300;

      for (int i = 0; i < ballCount; i++) {
        balls.add(Ball(
          position: Offset(rand.nextDouble() * size.width,
              rand.nextDouble() * size.height),
          radius: 10.0,
        ));
      }
      setState(() {});
    });
  }

  void _onAnimationTick() {
    final size = MediaQuery.of(context).size;
    setState(() {
      for (var ball in balls) {
        ball.move(balls, size);
      }
    });
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ConnectionPainter(
              balls,
              maxDistance: 150, // длина нитей снова 150
            ),
          ),
          ...balls.map((ball) => ball.buildBall()).toList(),
        ],
      ),
    );
  }
}

class Ball {
  Offset position;
  final double radius;
  Offset velocity;
  Color color;

  static const List<Color> colors = [
    Colors.blue,
    Colors.cyan,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Color.fromARGB(255, 68, 180, 255),
    Color.fromARGB(255, 68, 21, 155),
    Color.fromARGB(255, 239, 68, 255),
    Colors.red,
  ];

  Ball({
    required this.position,
    required this.radius,
  })  : velocity = Offset(
          Random().nextDouble() * 2 - 1,
          Random().nextDouble() * 2 - 1,
        ),
        color = colors[Random().nextInt(colors.length)];

  void move(List<Ball> balls, Size screenSize) {
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final center = Offset(screenWidth / 2, screenHeight / 2);

    const edgeThreshold = 50.0;
    const centerForce = 0.05;

    if (position.dx < edgeThreshold ||
        position.dx > screenWidth - edgeThreshold ||
        position.dy < edgeThreshold ||
        position.dy > screenHeight - edgeThreshold) {
      final toCenter = (center - position).normalize();
      velocity += toCenter * centerForce;
    }

    position = position.translate(velocity.dx, velocity.dy);

    if (position.dx < 0 || position.dx > screenWidth) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy < 0 || position.dy > screenHeight) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }

    for (var otherBall in balls) {
      if (otherBall != this &&
          _distance(position, otherBall.position) < radius + otherBall.radius) {
        _handleCollision(otherBall);
      }
    }
  }

  void _handleCollision(Ball otherBall) {
    final dx = position.dx - otherBall.position.dx;
    final dy = position.dy - otherBall.position.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final normal = Offset(dx / distance, dy / distance);
    final relativeVelocity = velocity - otherBall.velocity;
    final speed = relativeVelocity.dot(normal);
    if (speed > 0) return;

    final impulse = normal * speed;
    velocity -= impulse;
    otherBall.velocity += impulse;
  }

  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }

  Widget buildBall() {
    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final List<Ball> balls;
  final double maxDistance;

  ConnectionPainter(this.balls, {this.maxDistance = 150});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;

    for (int i = 0; i < balls.length; i++) {
      for (int j = i + 1; j < balls.length; j++) {
        final a = balls[i].position;
        final b = balls[j].position;
        final dist = (a - b).distance;

        if (dist <= maxDistance) {
          final opacity = 1.0 - (dist / maxDistance);
          paint.color =
              const Color.fromARGB(255, 0, 0, 0).withOpacity(opacity * 0.8);
          canvas.drawLine(a, b, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

extension OffsetExtensions on Offset {
  Offset normalize() {
    final length = distance;
    if (length == 0) return this;
    return this / length;
  }

  double dot(Offset other) {
    return dx * other.dx + dy * other.dy;
  }
}
