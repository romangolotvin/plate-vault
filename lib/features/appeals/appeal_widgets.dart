import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Button shown on each of the signed-in collector's plates.
class AppealBar extends StatelessWidget {
  const AppealBar({super.key, required this.onPressed, this.statusLabel});

  final VoidCallback onPressed;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (statusLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                statusLabel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: VaultColors.purpleBright,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.gavel_outlined, size: 18),
            label: const Text('Обжаловать'),
          ),
        ],
      ),
    );
  }
}

/// The only editable number in the appeal flow.
class AppealCorrectedField extends StatelessWidget {
  const AppealCorrectedField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('appeal-corrected-number'),
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      decoration: const InputDecoration(labelText: 'Скорректировать номер'),
    );
  }
}
