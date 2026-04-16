import 'dart:ui';

import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:flutter/material.dart';

/// Abgerundete Karte mit Frosted-Glass-Effekt für Bento-Bereiche.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? DashboardTheme.radiusLg;
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            color: DashboardTheme.glassFill,
            border: Border.all(color: DashboardTheme.glassBorder),
            boxShadow: DashboardTheme.cardShadow,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: content,
        ),
      );
    }

    return content;
  }
}
