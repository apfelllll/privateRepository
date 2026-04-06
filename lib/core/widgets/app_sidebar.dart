import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Schmale linke Leiste für Master-Detail-Layouts ( z. B. Profil, Aufträge ).
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: child,
    );
  }
}
