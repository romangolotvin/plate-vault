import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Black + purple vault palette (user-requested brand).
class VaultColors {
  static const voidBg = Color(0xFF050508);
  static const charcoal = Color(0xFF0A0A10);
  static const navy = Color(0xFF120F1A);
  static const slate = Color(0xFF1C1528);
  static const panel = Color(0xFF16101F);
  /// Primary brand purple (replaces former gold).
  static const purple = Color(0xFFB56BFF);
  static const purpleBright = Color(0xFFD4A0FF);
  static const purpleDim = Color(0xFF7C3AED);
  static const magenta = Color(0xFFE879F9);
  static const mist = Color(0xFFC9C0D6);
  static const cream = Color(0xFFF3ECF8);
  static const plateFace = Color(0xFFF7F3E8);
  static const plateInk = Color(0xFF12151C);
  static const plateBlue = Color(0xFF1B3A6B);

  // Compat aliases used across older call sites.
  static const gold = purple;
  static const goldDim = purpleDim;
  static const teal = magenta;

  static const uncommon = Color(0xFF3DBF8F);
  static const rare = Color(0xFF4A8FE8);
  static const epic = Color(0xFFB06BFF);
  static const legendary = Color(0xFFFFB020);
}

class AppTheme {
  static ThemeData dark() {
    final base = ColorScheme.dark(
      surface: VaultColors.charcoal,
      primary: VaultColors.purple,
      onPrimary: VaultColors.voidBg,
      secondary: VaultColors.magenta,
      onSecondary: VaultColors.voidBg,
      tertiary: VaultColors.purpleBright,
      error: const Color(0xFFE57373),
      onSurface: VaultColors.cream,
      onSurfaceVariant: VaultColors.mist,
      outline: const Color(0xFF3D2F55),
      outlineVariant: const Color(0xFF2A1F3D),
      surfaceContainerHighest: VaultColors.slate,
      surfaceContainerHigh: VaultColors.panel,
      surfaceContainer: VaultColors.navy,
      surfaceContainerLow: VaultColors.charcoal,
      inverseSurface: VaultColors.cream,
      onInverseSurface: VaultColors.charcoal,
    );

    final display = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.outfitTextTheme();

    final textTheme = body
        .apply(
          bodyColor: VaultColors.cream,
          displayColor: VaultColors.cream,
        )
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: display.displayMedium?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: display.headlineLarge?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          headlineMedium: display.headlineMedium?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: display.headlineSmall?.copyWith(
            color: VaultColors.cream,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: body.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: body.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
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
        color: VaultColors.panel.withValues(alpha: 0.95),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: VaultColors.purple.withValues(alpha: 0.22),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VaultColors.slate.withValues(alpha: 0.8),
        hintStyle: TextStyle(color: VaultColors.mist.withValues(alpha: 0.55)),
        labelStyle: const TextStyle(color: VaultColors.mist),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: VaultColors.purple.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: VaultColors.purple.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: VaultColors.purple, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VaultColors.slate,
        selectedColor: VaultColors.purple.withValues(alpha: 0.28),
        side: BorderSide(color: VaultColors.purple.withValues(alpha: 0.3)),
        labelStyle: textTheme.labelMedium?.copyWith(color: VaultColors.cream),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: VaultColors.cream),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VaultColors.purple,
          foregroundColor: VaultColors.voidBg,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VaultColors.cream,
          side: BorderSide(color: VaultColors.purple.withValues(alpha: 0.55)),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VaultColors.navy.withValues(alpha: 0.97),
        indicatorColor: VaultColors.purple.withValues(alpha: 0.28),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            height: 1.05,
            color: selected ? VaultColors.purpleBright : VaultColors.mist,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? VaultColors.purpleBright : VaultColors.mist,
            size: selected ? 24 : 22,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: VaultColors.purple.withValues(alpha: 0.14),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VaultColors.panel,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: VaultColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VaultColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? VaultColors.purpleBright
              : VaultColors.mist;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? VaultColors.purple.withValues(alpha: 0.4)
              : VaultColors.slate;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VaultColors.purple,
      ),
    );
  }

  static ThemeData light() => dark();
}
