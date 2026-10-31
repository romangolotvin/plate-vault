import 'package:flutter/material.dart';

import '../theme.dart';

/// Atmospheric black/purple gradient for vault screens.
class VaultBackground extends StatelessWidget {
  const VaultBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF030306),
            Color(0xFF0A0612),
            VaultColors.voidBg,
            Color(0xFF12081C),
            Color(0xFF08040E),
          ],
          stops: [0, 0.22, 0.5, 0.78, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _VaultPatternPainter()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Color(0x88000000),
                ],
                stops: [0.5, 1],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class VaultScaffold extends StatelessWidget {
  const VaultScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return VaultBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class _VaultPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final purple = Paint()
      ..color = VaultColors.purple.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    final magenta = Paint()
      ..color = VaultColors.magenta.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const step = 32.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), purple);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), magenta);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          VaultColors.purple.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.06),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final glow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          VaultColors.magenta.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.08, size.height * 0.78),
        radius: size.width * 0.55,
      ));
    canvas.drawRect(Offset.zero & size, glow2);

    final glow3 = Paint()
      ..shader = RadialGradient(
        colors: [
          VaultColors.purpleDim.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.4),
        radius: size.width * 0.45,
      ));
    canvas.drawRect(Offset.zero & size, glow3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
