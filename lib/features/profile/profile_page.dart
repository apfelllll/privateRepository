import 'package:doordesk/core/widgets/dashboard_detail_chrome.dart';
import 'package:doordesk/core/widgets/dashboard_left_rail.dart'
    show
        DashboardLeftRail,
        DashboardRailItem,
        DashboardRailSection,
        flattenDashboardRailSections;
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/core/widgets/labeled_text_form_field.dart';
import 'package:doordesk/core/widgets/section_header.dart';
import 'package:doordesk/features/shell/shell_navigation_items.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/models/user_role.dart';
import 'package:doordesk/services/calculation_settings.dart';
import 'package:doordesk/services/number_generation_settings.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.selectedShellIndex,
    required this.onShellSelect,
  });

  final DoorDeskUser user;
  final VoidCallback onLogout;
  final int selectedShellIndex;
  final ValueChanged<int> onShellSelect;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _section = 0;

  NumberGenerationSettings _numberSettings = const NumberGenerationSettings(
    autoCustomerNumber: true,
    autoOrderNumber: true,
  );
  CalculationSettings _calculationSettings = CalculationSettings.defaults;

  @override
  void initState() {
    super.initState();
    _loadNumberSettings();
    _loadCalculationSettings();
  }

  Future<void> _loadNumberSettings() async {
    final loaded = await NumberGenerationSettings.load();
    if (!mounted) return;
    setState(() => _numberSettings = loaded);
  }

  Future<void> _setNumberSettings(NumberGenerationSettings next) async {
    setState(() => _numberSettings = next);
    await next.save();
  }

  Future<void> _loadCalculationSettings() async {
    final loaded = await CalculationSettings.load();
    if (!mounted) return;
    setState(() => _calculationSettings = loaded);
  }

  Future<void> _setCalculationSettings(CalculationSettings next) async {
    setState(() => _calculationSettings = next);
    await next.save();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final superUser = user.role == UserRole.superAdmin;

    final detailSections = [
      DashboardRailSection(
        heading: 'Account',
        items: [
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
        ],
      ),
      DashboardRailSection(
        heading: 'Aufträge und Kunden',
        items: const [
          DashboardRailItem(
            icon: Icons.calculate_outlined,
            label: 'Kalkulation',
          ),
          DashboardRailItem(
            icon: Icons.numbers_outlined,
            label: 'Nummern',
          ),
        ],
      ),
    ];

    final flat = flattenDashboardRailSections(detailSections);
    final sel = _section.clamp(0, flat.length - 1);
    final shellCount = flattenDashboardRailSections(shellRailSections).length;
    final selectedRailIndex = shellCount + sel;

    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding: ShellSearchLayout.detailColumnTopPadding(context),
      left: DashboardLeftRail(
        sections: [
          ...shellRailSections,
          ...detailSections,
        ],
        selectedIndex: widget.selectedShellIndex == 5
            ? selectedRailIndex
            : widget.selectedShellIndex,
        onSelect: (i) {
          if (i < shellCount) {
            widget.onShellSelect(shellRailTargetFromIndex(i).tabIndex);
            return;
          }
          setState(() => _section = i - shellCount);
        },
        onLogout: widget.onLogout,
        footerHint: flat[sel].label,
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
                if (superUser && sel == 2) ...[
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
                if (sel == (superUser ? 3 : 2)) ...[
                  const SectionHeader(
                    title: 'Kalkulation',
                    subtitle:
                        'Stundensätze und Faktoren für die Rechnungsberechnung.',
                  ),
                  DoorDeskFormCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _CalculationSettingsSection(
                        settings: _calculationSettings,
                        onSave: _setCalculationSettings,
                      ),
                    ),
                  ),
                ],
                if (sel == (superUser ? 4 : 3)) ...[
                  const SectionHeader(
                    title: 'Nummern',
                    subtitle:
                        'Automatische Vergabe fortlaufender Nummern beim Anlegen.',
                  ),
                  DoorDeskFormCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              'Die automatische Generierung ist fortlaufend: Es wird '
                              'jeweils die nächste Nummer der laufenden Nummernfolge '
                              'vergeben. Feinere Regeln wie Präfixe folgen später.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          CheckboxListTile(
                            value: _numberSettings.autoCustomerNumber,
                            onChanged: (v) {
                              if (v == null) return;
                              _setNumberSettings(
                                _numberSettings.copyWith(
                                  autoCustomerNumber: v,
                                ),
                              );
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: const Text('Kundennummerngenerierung'),
                            subtitle: const Text(
                              'Neuen Kunden fortlaufend eine Kundennummer zuweisen',
                            ),
                          ),
                          CheckboxListTile(
                            value: _numberSettings.autoOrderNumber,
                            onChanged: (v) {
                              if (v == null) return;
                              _setNumberSettings(
                                _numberSettings.copyWith(
                                  autoOrderNumber: v,
                                ),
                              );
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: const Text('Auftragsnummerngenerierung'),
                            subtitle: const Text(
                              'Neuen Aufträgen fortlaufend eine Auftragsnummer zuweisen',
                            ),
                          ),
                        ],
                      ),
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

class _CalculationSettingsSection extends StatefulWidget {
  const _CalculationSettingsSection({
    required this.settings,
    required this.onSave,
  });

  final CalculationSettings settings;
  final Future<void> Function(CalculationSettings) onSave;

  @override
  State<_CalculationSettingsSection> createState() =>
      _CalculationSettingsSectionState();
}

class _CalculationSettingsSectionState extends State<_CalculationSettingsSection> {
  late final TextEditingController _meister;
  late final TextEditingController _geselle;
  late final TextEditingController _bankraum;
  late final TextEditingController _maschinenraum;
  late final TextEditingController _lackierraum;
  late final TextEditingController _planung;
  late final TextEditingController _montage;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _meister = TextEditingController();
    _geselle = TextEditingController();
    _bankraum = TextEditingController();
    _maschinenraum = TextEditingController();
    _lackierraum = TextEditingController();
    _planung = TextEditingController();
    _montage = TextEditingController();
    _syncControllers(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _CalculationSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _syncControllers(widget.settings);
    }
  }

  void _syncControllers(CalculationSettings s) {
    _meister.text = _formatValue(s.meisterHourlyRate);
    _geselle.text = _formatValue(s.geselleHourlyRate);
    _bankraum.text = _formatValue(s.bankraumFactor);
    _maschinenraum.text = _formatValue(s.maschinenraumFactor);
    _lackierraum.text = _formatValue(s.lackierraumFactor);
    _planung.text = _formatValue(s.planungFactor);
    _montage.text = _formatValue(s.montageFactor);
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _save() async {
    final meister = _parseNumber(_meister.text);
    final geselle = _parseNumber(_geselle.text);
    final bankraum = _parseNumber(_bankraum.text);
    final maschinenraum = _parseNumber(_maschinenraum.text);
    final lackierraum = _parseNumber(_lackierraum.text);
    final planung = _parseNumber(_planung.text);
    final montage = _parseNumber(_montage.text);

    if (meister == null ||
        geselle == null ||
        bankraum == null ||
        maschinenraum == null ||
        lackierraum == null ||
        planung == null ||
        montage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte nur gültige Zahlen eingeben.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        widget.settings.copyWith(
          meisterHourlyRate: meister,
          geselleHourlyRate: geselle,
          bankraumFactor: bankraum,
          maschinenraumFactor: maschinenraum,
          lackierraumFactor: lackierraum,
          planungFactor: planung,
          montageFactor: montage,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kalkulation gespeichert.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _meister.dispose();
    _geselle.dispose();
    _bankraum.dispose();
    _maschinenraum.dispose();
    _lackierraum.dispose();
    _planung.dispose();
    _montage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledTextFormField(
          label: 'Meisterstunde (EUR/h)',
          controller: _meister,
          hint: 'z. B. 85',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 16),
        LabeledTextFormField(
          label: 'Gesellenstunde (EUR/h)',
          controller: _geselle,
          hint: 'z. B. 65',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 20),
        LabeledTextFormField(
          label: 'Faktor Bankraum',
          controller: _bankraum,
          hint: 'z. B. 1,00',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 16),
        LabeledTextFormField(
          label: 'Faktor Maschinenraum',
          controller: _maschinenraum,
          hint: 'z. B. 1,10',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 16),
        LabeledTextFormField(
          label: 'Faktor Lackierraum',
          controller: _lackierraum,
          hint: 'z. B. 1,15',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 16),
        LabeledTextFormField(
          label: 'Faktor Planung',
          controller: _planung,
          hint: 'z. B. 1,05',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 16),
        LabeledTextFormField(
          label: 'Faktor Montage',
          controller: _montage,
          hint: 'z. B. 1,00',
          keyboardType: decimalKeyboard,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Kalkulation speichern'),
            ),
          ],
        ),
      ],
    );
  }
}
