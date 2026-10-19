import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'simmas_colors.dart';

/// Radius dasar situs asli: `--radius: .625rem` = 10px.
const double kRadius = 10;

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(SimmasColors.light, Brightness.light);

  static ThemeData _build(SimmasColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: c.primaryForeground,
      surface: c.card,
      onSurface: c.foreground,
      error: c.destructive,
      outline: c.border,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.card,
      dividerColor: c.border,
      extensions: <ThemeExtension<dynamic>>[c],
      // Font referensi desain: Inter.
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: c.foreground,
        displayColor: c.foreground,
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.foreground,
        contentTextStyle: TextStyle(color: c.background, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
    );
  }
}
