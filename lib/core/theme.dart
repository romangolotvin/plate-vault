import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Collector / vault palette: deep charcoal-navy with amber gold + teal sparks.
class VaultColors {
  static const voidBg = Color(0xFF070B12);
  static const charcoal = Color(0xFF0C121C);
  static const navy = Color(0xFF121A2B);
  static const slate = Color(0xFF1A2438);
  static const panel = Color(0xFF162033);
  static const gold = Color(0xFFE0B44A);
  static const goldDim = Color(0xFFB8892E);
  static const teal = Color(0xFF2EC4B6);
  static const mist = Color(0xFFC5CDD9);
  static const cream = Color(0xFFF4F0E4);
  static const plateFace = Color(0xFFF7F3E8);
  static const plateInk = Color(0xFF12151C);
  static const plateBlue = Color(0xFF1B3A6B);

  static const uncommon = Color(0xFF3DBF8F);
  static const rare = Color(0xFF4A8FE8);
  static const epic = Color(0xFFB06BFF);
  static const legendary = Color(0xFFFFB020);
}

class AppTheme {
  static ThemeData dark() {
    final base = ColorScheme.dark(
      surface: VaultColors.charcoal,
      primary: VaultColors.gold,
      onPrimary: VaultColors.charcoal,
      secondary: VaultColors.teal,
      onSecondary: VaultColors.charcoal,
      tertiary: VaultColors.goldDim,
      error: const Color(0xFFE57373),
      onSurface: VaultColors.cream,
      onSurfaceVariant: VaultColors.mist,
      outline: const Color(0xFF3A4660),
      outlineVariant: const Color(0xFF2A354C),
      surfaceContainerHighest: VaultColors.slate,
      surfaceContainerHigh: VaultColors.panel,
      surfaceContainer: VaultColors.navy,
      surfaceContainerLow: VaultColors.charcoal,
      inverseSurface: VaultColors.cream,
      onInverseSurface: VaultColors.charcoal,
    );

    final display = GoogleFonts.cormorantGaramondTextTheme();
    final body = GoogleFonts.manropeTextTheme();

    final textTheme = body
        .apply(
          bodyColor: VaultColors.cream,
          displayColor: VaultColors.cream,
        )
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          displayMedium: display.displayMedium?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: display.headlineLarge?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          headlineMedium: display.headlineMedium?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: display.headlineSmall?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: body.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: body.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      scaffoldBackgroundColor: VaultColors.voidBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: VaultColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: VaultColors.cream,
        ),
      ),
      cardTheme: CardThemeData(
        color: VaultColors.panel.withValues(alpha: 0.92),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: VaultColors.gold.withValues(alpha: 0.14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VaultColors.slate.withValues(alpha: 0.75),
        hintStyle: TextStyle(color: VaultColors.mist.withValues(alpha: 0.55)),
        labelStyle: const TextStyle(color: VaultColors.mist),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: VaultColors.gold.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: VaultColors.gold.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VaultColors.gold, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VaultColors.slate,
        selectedColor: VaultColors.gold.withValues(alpha: 0.22),
        side: BorderSide(color: VaultColors.gold.withValues(alpha: 0.25)),
        labelStyle: textTheme.labelMedium?.copyWith(color: VaultColors.cream),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: VaultColors.cream),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VaultColors.gold,
          foregroundColor: VaultColors.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VaultColors.cream,
          side: BorderSide(color: VaultColors.teal.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VaultColors.navy.withValues(alpha: 0.96),
        indicatorColor: VaultColors.gold.withValues(alpha: 0.22),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? VaultColors.gold : VaultColors.mist,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? VaultColors.gold : VaultColors.mist,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: VaultColors.gold.withValues(alpha: 0.12),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VaultColors.panel,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: VaultColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VaultColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? VaultColors.gold
              : VaultColors.mist;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? VaultColors.gold.withValues(alpha: 0.35)
              : VaultColors.slate;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VaultColors.gold,
      ),
    );
  }

  /// Kept for compatibility; app uses [dark] as the vault look.
  static ThemeData light() => dark();
}
