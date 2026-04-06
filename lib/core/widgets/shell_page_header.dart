import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Kompakte Kopfzeile für Tabs ohne durchgehende Sidebar (unterhalb Fenster-Titelleiste).
class ShellPageHeader extends StatelessWidget {
  const ShellPageHeader({
    super.key,
    required this.sectionTitle,
    required this.onLogout,
  });

  final String sectionTitle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.background,
      elevation: 0,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                'DoorDesk',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' · ',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.45)),
              ),
              Text(
                sectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Metisia',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Abmelden',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 22),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
