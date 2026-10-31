import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Motion kit: juicy, but NEVER blanks a full screen with Opacity→0.
/// (That bug looked like a white/empty tab.)

/// Press feedback: scale down + light haptic.
class VaultPressable extends StatefulWidget {
  const VaultPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = 0.94,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<VaultPressable> createState() => _VaultPressableState();
}

class _VaultPressableState extends State<VaultPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down && enabled ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Soft enter for sections: slide up + scale. Always fully opaque.
class VaultEnter extends StatelessWidget {
  const VaultEnter({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) {
        final clamped = t.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, (1 - clamped) * 16),
          child: Transform.scale(
            scale: 0.96 + 0.04 * clamped,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Staggered list row enter (scale/slide only).
class VaultStagger extends StatelessWidget {
  const VaultStagger({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayMs = (index.clamp(0, 8) * 45);
    return VaultEnter(
      delay: Duration(milliseconds: delayMs),
      duration: const Duration(milliseconds: 420),
      child: child,
    );
  }
}

/// Tab / page switch without Fade (fade caused blank tabs).
Widget vaultSlideSwitch(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curved),
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
      child: child,
    ),
  );
}

Route<T> vaultRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => vaultSlideSwitch(child, anim),
  );
}
