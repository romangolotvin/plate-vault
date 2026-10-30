import 'package:flutter/material.dart';

import '../theme.dart';

/// Atmospheric charcoal/navy gradient + subtle grid for vault screens.
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
            Color(0xFF05080F),
            Color(0xFF0A101C),
            VaultColors.voidBg,
            Color(0xFF0C1A22),
            Color(0xFF081018),
          ],
          stops: [0, 0.22, 0.5, 0.78, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _VaultPatternPainter()),
          // Soft vignette — deeper vault feel.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.15,
                colors: [
                  Colors.transparent,
                  Color(0x66000000),
                ],
                stops: [0.55, 1],
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
    final gold = Paint()
      ..color = VaultColors.gold.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    final teal = Paint()
      ..color = VaultColors.teal.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gold);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), teal);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          VaultColors.gold.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.08),
        radius: size.width * 0.55,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final glow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          VaultColors.teal.withValues(alpha: 0.11),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.75),
        radius: size.width * 0.5,
      ));
    canvas.drawRect(Offset.zero & size, glow2);

    final glow3 = Paint()
      ..shader = RadialGradient(
        colors: [
          VaultColors.legendary.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.35),
        radius: size.width * 0.4,
      ));
    canvas.drawRect(Offset.zero & size, glow3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
