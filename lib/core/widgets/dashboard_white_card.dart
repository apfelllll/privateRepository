import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:flutter/material.dart';

/// Weiße Karte im Referenz-Dashboard-Stil (kräftiger als reines Glas ).
class DashboardWhiteCard extends StatelessWidget {
  const DashboardWhiteCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(DashboardTheme.radiusMd);
    Widget inner = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: r,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: DashboardTheme.cardShadow,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      inner = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          splashColor: AppColors.accent.withValues(alpha: 0.08),
          child: inner,
        ),
      );
    }

    return inner;
  }
}
