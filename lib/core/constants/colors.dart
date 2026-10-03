import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color action;
  final Color text;
  final Color textLight;
  final Color accent;
  final Color accentHover;
  final Color border;
  final Color background;
  final Color tableHeader;

  const AppColors({
    required this.primary,
    required this.action,
    required this.text,
    required this.textLight,
    required this.accent,
    required this.accentHover,
    required this.border,
    required this.background,
    required this.tableHeader,
  });

  @override
  AppColors copyWith({
    Color? primary,
    Color? action,
    Color? text,
    Color? textLight,
    Color? accent,
    Color? accentHover,
    Color? border,
    Color? background,
    Color? tableHeader,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      action: action ?? this.action,
      text: text ?? this.text,
      textLight: textLight ?? this.textLight,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      border: border ?? this.border,
      background: background ?? this.background,
      tableHeader: tableHeader ?? this.tableHeader,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      action: Color.lerp(action, other.action, t)!,
      text: Color.lerp(text, other.text, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      background: Color.lerp(background, other.background, t)!,
      tableHeader: Color.lerp(tableHeader, other.tableHeader, t)!,
    );
  }

  static const light = AppColors(
    primary: Color(0xFF001F3F), 
    action: Color(0xFFFFD23F), 
    text: Color(0xFF2C3E50), 
    textLight: Color(0xFF7F8C8D),
    accent: Color(0xFFFFC0CB), 
    accentHover: Color(0xFFFFB7C5),
    border: Color(0xFFE2E8F0), 
    background: Color(0xFFF8F9FA), 
    tableHeader: Color(0xFFF8FAFC), 
  );

  static const dark = AppColors(
    primary: Color(0xFF1E293B), 
    action: Color(0xFFF59E0B), 
    text: Color(0xFFF8FAFC), 
    textLight: Color(0xFF94A3B8), 
    accent: Color(0xFFDB2777), 
    accentHover: Color(0xFFBE185D),
    border: Color(0xFF334155), 
    background: Color(0xFF0F172A), 
    tableHeader: Color(0xFF1E293B), 
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
