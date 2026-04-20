import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/mobile/widgets/mobile_menu_list.dart';
import 'package:doordesk/mobile/widgets/mobile_page_scaffold.dart';
import 'package:doordesk/mobile/widgets/mobile_placeholder_sub_page.dart';
import 'package:doordesk/models/user_role.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MobileSettingsPage extends ConsumerWidget {
  const MobileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(doorDeskSessionProvider).value;
    final theme = Theme.of(context);
    final isSuperAdmin = user?.role == UserRole.superAdmin;

    Future<void> logout() async {
      final auth = ref.read(authServiceProvider);
      await auth?.signOut();
    }

    return MobilePageScaffold(
      title: 'Einstellungen',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accentSoft,
                    child: Text(
                      _initials(user.displayName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.role.displayNameDe,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          MobileMenuList(
            leadingPadding: 0,
            sections: [
              MobileMenuSection(
                heading: 'Konto',
                items: [
                  MobileMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Stammdaten',
                    onTap: () => pushMobilePlaceholderPage(
                      context,
                      title: 'Stammdaten',
                      icon: Icons.person_outline_rounded,
                      message:
                          'Name, E-Mail und Telefon bearbeiten — folgt bald.',
                    ),
                  ),
                  MobileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Sicherheit',
                    onTap: () => pushMobilePlaceholderPage(
                      context,
                      title: 'Sicherheit',
                      icon: Icons.lock_outline_rounded,
                      message:
                          'Passwort aendern und Sicherheitsoptionen folgen.',
                    ),
                  ),
                  if (isSuperAdmin)
                    MobileMenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Organisation',
                      onTap: () => pushMobilePlaceholderPage(
                        context,
                        title: 'Organisation',
                        icon: Icons.admin_panel_settings_outlined,
                        message: 'Benutzer und Rollen verwalten.',
                      ),
                    ),
                ],
              ),
              MobileMenuSection(
                heading: 'Auftraege und Kunden',
                items: [
                  MobileMenuItem(
                    icon: Icons.calculate_outlined,
                    label: 'Kalkulation',
                    onTap: () => pushMobilePlaceholderPage(
                      context,
                      title: 'Kalkulation',
                      icon: Icons.calculate_outlined,
                      message:
                          'Stundensaetze und Faktoren fuer die Rechnungsberechnung.',
                    ),
                  ),
                  MobileMenuItem(
                    icon: Icons.numbers_outlined,
                    label: 'Nummern',
                    onTap: () => pushMobilePlaceholderPage(
                      context,
                      title: 'Nummern',
                      icon: Icons.numbers_outlined,
                      message:
                          'Automatische Vergabe fortlaufender Auftrags- und Kundennummern.',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _LogoutTile(onTap: logout),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded, size: 18, color: errorColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Abmelden',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
