import 'package:flutter/material.dart';

/// Verlauf & Oberflächen für das Dashboard (angelehnt an „Glass“-Dashboards).
abstract final class DashboardTheme {
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8E4F5),
      Color(0xFFF2E8F0),
      Color(0xFFE4E8F7),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static Color get glassFill => Colors.white.withValues(alpha: 0.52);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.65);
  static Color get railGlassFill => Colors.white.withValues(alpha: 0.38);
  static Color get railBorder => Colors.white.withValues(alpha: 0.55);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static const double radiusLg = 22;
  static const double radiusMd = 16;
}
