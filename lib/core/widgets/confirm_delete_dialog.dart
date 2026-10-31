import 'package:flutter/material.dart';

import '../theme.dart';

/// Returns true only if the user confirms permanent delete.
Future<bool> confirmDeletePlate(
  BuildContext context, {
  required String plateText,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: VaultColors.panel,
        title: const Text('Удалить номер?'),
        content: Text(
          'Вы правда хотите удалить номер «$plateText» безвозвратно?\n\n'
          'Он исчезнет из вашей коллекции.',
          style: const TextStyle(color: VaultColors.mist, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VaultColors.magenta,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, удалить'),
          ),
        ],
      );
    },
  );
  return result == true;
}
