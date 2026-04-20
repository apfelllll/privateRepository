import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Scaffold fuer Unterseiten hinter einem Tab — mit Zurueck-Pfeil, klarer Hierarchie.
///
/// Standard-Slide-Animation durch `MaterialPageRoute`; Zurueck-Geste + Hardware-Button
/// funktionieren out of the box.
class MobileSubPage extends StatelessWidget {
  const MobileSubPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: actions,
      ),
      body: child,
    );
  }
}

/// Einfacher Body fuer noch nicht gebaute Unterseiten.
class MobileSubPagePlaceholder extends StatelessWidget {
  const MobileSubPagePlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
