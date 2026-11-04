import 'package:flutter/material.dart';

import '../../core/country_flag.dart';
import '../../core/theme.dart';

/// Countries shown when the user picks «Другая» (not Russia, not the US).
const kOtherPlateCountries = <String>[
  'BY',
  'KZ',
  'UA',
  'DE',
  'FR',
  'PL',
  'GB',
  'IT',
  'ES',
  'TR',
  'NL',
  'CN',
  'JP',
  'XX',
];

enum _CountryMode { ru, us, other }

/// Russia / US / other. Used before a scan and again on an appeal.
class CountrySwitch extends StatelessWidget {
  const CountrySwitch({
    super.key,
    required this.countryCode,
    required this.onChanged,
  });

  final String countryCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final code = countryCode.trim().toUpperCase();
    final mode = code == 'RU'
        ? _CountryMode.ru
        : code == 'US'
            ? _CountryMode.us
            : _CountryMode.other;
    final others = <String>{
      ...kOtherPlateCountries,
      if (mode == _CountryMode.other && code.isNotEmpty) code,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Страна номера',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: VaultColors.mist,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<_CountryMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _CountryMode.ru, label: Text('Россия')),
            ButtonSegment(value: _CountryMode.us, label: Text('США')),
            ButtonSegment(value: _CountryMode.other, label: Text('Другая')),
          ],
          selected: {mode},
          onSelectionChanged: (selected) {
            if (selected.isEmpty) return;
            switch (selected.first) {
              case _CountryMode.ru:
                onChanged('RU');
              case _CountryMode.us:
                onChanged('US');
              case _CountryMode.other:
                onChanged(mode == _CountryMode.other ? code : 'XX');
            }
          },
        ),
        if (mode == _CountryMode.other) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: others.contains(code) ? code : 'XX',
            decoration: const InputDecoration(labelText: 'Какая страна'),
            items: [
              for (final country in others)
                DropdownMenuItem(
                  value: country,
                  child: Text('${countryFlagEmoji(country)} $country'),
                ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ],
    );
  }
}
