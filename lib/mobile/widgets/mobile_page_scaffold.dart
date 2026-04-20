import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Einheitlicher Rahmen fuer Mobile-Seiten — grosser Titel, ruhiger Hintergrund.
class MobilePageScaffold extends StatelessWidget {
  const MobilePageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.trailingPadding = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool trailingPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 28,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                  if (actions == null && trailingPadding)
                    const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Neutraler Platzhalter, bis die jeweilige Seite gebaut ist.
class MobileComingSoonBody extends StatelessWidget {
  const MobileComingSoonBody({
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
