import 'package:flutter/material.dart';

import '../theme.dart';
import 'vault_anim.dart';

/// Big expressive gradient CTA — not a default Material rectangle.
class VaultCta extends StatelessWidget {
  const VaultCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.secondary = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool secondary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: secondary
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? const [
                        Color(0xFFD4A0FF),
                        VaultColors.purple,
                        VaultColors.purpleDim,
                      ]
                    : [
                        VaultColors.slate,
                        VaultColors.panel,
                      ],
              ),
        color: secondary ? VaultColors.slate.withValues(alpha: 0.85) : null,
        border: Border.all(
          color: secondary
              ? VaultColors.purple.withValues(alpha: 0.55)
              : VaultColors.purpleBright.withValues(alpha: 0.35),
          width: secondary ? 1.4 : 1,
        ),
        boxShadow: secondary || !enabled
            ? null
            : [
                BoxShadow(
                  color: VaultColors.purple.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Center(
        child: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: VaultColors.cream,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: secondary
                          ? VaultColors.purpleBright
                          : VaultColors.voidBg,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          letterSpacing: 0.4,
                          color: secondary
                              ? VaultColors.cream
                              : VaultColors.voidBg,
                        ),
                  ),
                ],
              ),
      ),
    );

    final child = VaultPressable(
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(22),
      child: face,
    );

    if (!expand) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}

/// Soft atmospheric panel that fills empty space with brand feel.
class VaultHeroPanel extends StatelessWidget {
  const VaultHeroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: VaultColors.purple.withValues(alpha: 0.35),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.slate,
            VaultColors.panel,
            VaultColors.purpleDim.withValues(alpha: 0.35),
            VaultColors.magenta.withValues(alpha: 0.12),
          ],
          stops: const [0, 0.35, 0.75, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: VaultColors.purple.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
