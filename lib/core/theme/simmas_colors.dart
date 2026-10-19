import 'package:flutter/material.dart';

/// Design token hasil ekstraksi dari CSS situs asli (`:root` dan `.dark`).
@immutable
class SimmasColors extends ThemeExtension<SimmasColors> {
  const SimmasColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.success,
    required this.warning,
    required this.warningForeground,
    required this.destructive,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color primary;
  final Color primaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color success;
  final Color warning;
  final Color warningForeground;
  final Color destructive;

  /// Warna logo (bg-blue-600) selalu tetap, baik light maupun dark.
  static const logoBlue = Color(0xFF2563EB);

  static const light = SimmasColors(
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF0F172A),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    primaryForeground: Color(0xFFF8FAFC),
    muted: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    success: Color(0xFF16A260),
    warning: Color(0xFFF59F0A),
    warningForeground: Color(0xFF321501),
    destructive: Color(0xFFEC2734),
  );

  @override
  SimmasColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? primary,
    Color? primaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? success,
    Color? warning,
    Color? warningForeground,
    Color? destructive,
  }) {
    return SimmasColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningForeground: warningForeground ?? this.warningForeground,
      destructive: destructive ?? this.destructive,
    );
  }

  @override
  SimmasColors lerp(ThemeExtension<SimmasColors>? other, double t) {
    if (other is! SimmasColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SimmasColors(
      background: l(background, other.background),
      foreground: l(foreground, other.foreground),
      card: l(card, other.card),
      primary: l(primary, other.primary),
      primaryForeground: l(primaryForeground, other.primaryForeground),
      muted: l(muted, other.muted),
      mutedForeground: l(mutedForeground, other.mutedForeground),
      border: l(border, other.border),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      warningForeground: l(warningForeground, other.warningForeground),
      destructive: l(destructive, other.destructive),
    );
  }
}

extension SimmasColorsX on BuildContext {
  SimmasColors get sc => Theme.of(this).extension<SimmasColors>()!;
}
