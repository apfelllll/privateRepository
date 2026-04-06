import 'package:doordesk/core/widgets/dashboard_detail_chrome.dart';
import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/core/widgets/labeled_text_form_field.dart';
import 'package:doordesk/core/widgets/section_header.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/models/user_role.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final DoorDeskUser user;
  final VoidCallback onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final superUser = user.role == UserRole.superAdmin;

    final items = <DashboardRailItem>[
      const DashboardRailItem(
        icon: Icons.person_outline_rounded,
        label: 'Stammdaten',
      ),
      const DashboardRailItem(
        icon: Icons.lock_outline_rounded,
        label: 'Sicherheit',
      ),
      if (superUser)
        const DashboardRailItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Organisation',
        ),
    ];

    final sel = _section.clamp(0, items.length - 1);

    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding: ShellSearchLayout.detailColumnTopPadding(context),
      left: DashboardLeftRail(
        sections: [DashboardRailSection(items: items)],
        selectedIndex: sel,
        onSelect: (i) => setState(() => _section = i),
        onLogout: widget.onLogout,
        footerHint: items[sel].label,
      ),
      detail: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 32, 32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardDetailChrome(
                  greeting: 'Einstellungen',
                  subtitle: '${user.displayName} · ${user.email}',
                  showTopBar: false,
                ),
                if (sel == 0) ...[
                  DoorDeskFormCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _ProfileForm(key: ValueKey(user.id), user: user),
                    ),
                  ),
                ],
                if (sel == 1) ...[
                  const SectionHeader(
                    title: 'Sicherheit',
                    subtitle:
                        'Passwort über Supabase Auth ( Dashboard ) oder später in der App.',
                  ),
                  DoorDeskFormCard(
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _PasswordPlaceholder(),
                    ),
                  ),
                ],
                if (sel == 2 && superUser) ...[
                  const SectionHeader(
                    title: 'Organisation',
                    subtitle: 'Benutzer & Rollen — SuperAdmin.',
                  ),
                  DoorDeskFormCard(
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _SuperAdminSection(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key, required this.user});

  final DoorDeskUser user;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u.displayName);
    _email = TextEditingController(text: u.email);
    _phone = TextEditingController(text: u.phone ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _name.text = widget.user.displayName;
      _email.text = widget.user.email;
      _phone.text = widget.user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledTextFormField(
          label: 'Name',
          subtitle: 'Änderung später über Profil-API',
          controller: _name,
          hint: 'Name',
          readOnly: true,
        ),
        const SizedBox(height: 20),
        LabeledTextFormField(
          label: 'E-Mail',
          controller: _email,
          hint: 'E-Mail',
          readOnly: true,
        ),
        const SizedBox(height: 20),
        LabeledTextFormField(
          label: 'Telefon ( optional )',
          controller: _phone,
          hint: 'Telefon',
          readOnly: true,
        ),
        const SizedBox(height: 20),
        LabeledFormBlock(
          label: 'Firmen-ID ( company_id )',
          subtitle: 'UUID der Firma in Supabase',
          child: doorDeskInputFieldTheme(
            context,
            InputDecorator(
              decoration: doorDeskFormInputDecoration(context),
              child: SelectableText(
                user.companyId,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        LabeledFormBlock(
          label: 'Rolle',
          child: doorDeskInputFieldTheme(
            context,
            InputDecorator(
              decoration: doorDeskFormInputDecoration(context),
              child: Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.role.displayNameDe,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          PermissionService.roleDescriptionDe(user.role),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Synchronisation mit Supabase folgt in einem späteren Schritt.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Profil aktualisieren'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordPlaceholder extends StatelessWidget {
  const _PasswordPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Passwörter werden in Supabase Auth gespeichert. '
      'Zum Ändern: Dashboard → Authentication → User auswählen, '
      'oder später „Passwort zurücksetzen“ in der App.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _SuperAdminSection extends StatelessWidget {
  const _SuperAdminSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benutzerverwaltung',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Nutzer einladen und Rollen vergeben — Einladungsflow folgt.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.group_add_outlined, size: 20),
          label: const Text('Platzhalter: Nutzerliste'),
        ),
      ],
    );
  }
}
