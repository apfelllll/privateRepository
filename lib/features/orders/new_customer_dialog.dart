import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/core/widgets/labeled_text_form_field.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:flutter/material.dart';

/// Ziel-Feld beim Öffnen des Bearbeiten-Dialogs (Scroll + Fokus).
enum CustomerFormFocusField {
  customerNumber,
  companyName,
  contactName,
  email,
  phone,
  street,
  houseNumber,
  zip,
  city,
  billingStreet,
  billingHouseNumber,
  billingZip,
  billingCity,
  billingEmail,
  vatId,
  taxNumber,
  paymentTerms,
  notes,
}

/// Öffnet den Vollbild-Dialog „Neuer Kunde“ / „Kunde bearbeiten“.
/// Mit [initial] sind alle Felder vorausgefüllt; [createdAt] bleibt beim Speichern erhalten.
/// [focusField]: zugeklappte Bereiche werden geöffnet, Feld wird sichtbar geschoben und fokussiert.
Future<CustomerDraft?> showNewCustomerDialog(
  BuildContext context, {
  CustomerDraft? initial,
  CustomerFormFocusField? focusField,
}) {
  return showDialog<CustomerDraft>(
    context: context,
    builder: (ctx) =>
        _NewCustomerDialog(initial: initial, focusField: focusField),
  );
}

/// Etwas breiter als die Zeiterfassung, damit die Scrollbar nicht in die Felder ragt.
const double _kNewCustomerFormWidth = 780;

/// Zusätzlicher rechter Innenrand im Scrollbereich (Abstand zur Scrollbar).
const double _kFormScrollGutter = 16;

class _NewCustomerDialog extends StatefulWidget {
  const _NewCustomerDialog({this.initial, this.focusField});

  final CustomerDraft? initial;
  final CustomerFormFocusField? focusField;

  @override
  State<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends State<_NewCustomerDialog> {
  CustomerKind _kind = CustomerKind.privat;

  bool _kontaktExpanded = true;
  bool _adresseExpanded = true;
  bool _rechnungsadresseExpanded = true;
  bool _rechnungsinfoExpanded = true;

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _companyName;
  late final TextEditingController _contactName;
  late final TextEditingController _customerNumber;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _houseNumber;
  late final TextEditingController _zip;
  late final TextEditingController _city;
  late final TextEditingController _billingStreet;
  late final TextEditingController _billingHouseNumber;
  late final TextEditingController _billingZip;
  late final TextEditingController _billingCity;
  late final TextEditingController _vatId;
  late final TextEditingController _taxNumber;
  late final TextEditingController _billingEmail;
  late final TextEditingController _paymentTerms;
  late final TextEditingController _notes;

  late final Map<CustomerFormFocusField, GlobalKey> _fieldKeys;
  late final Map<CustomerFormFocusField, FocusNode> _fieldFocusNodes;

  @override
  void initState() {
    super.initState();
    _fieldKeys = {
      for (final f in CustomerFormFocusField.values) f: GlobalKey(),
    };
    _fieldFocusNodes = {
      for (final f in CustomerFormFocusField.values) f: FocusNode(),
    };
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _companyName = TextEditingController();
    _contactName = TextEditingController();
    _customerNumber = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _street = TextEditingController();
    _houseNumber = TextEditingController();
    _zip = TextEditingController();
    _city = TextEditingController();
    _billingStreet = TextEditingController();
    _billingHouseNumber = TextEditingController();
    _billingZip = TextEditingController();
    _billingCity = TextEditingController();
    _vatId = TextEditingController();
    _taxNumber = TextEditingController();
    _billingEmail = TextEditingController();
    _paymentTerms = TextEditingController();
    _notes = TextEditingController();

    final d = widget.initial;
    if (d != null) {
      _kind = d.kind;
      _customerNumber.text = d.customerNumber;
      _firstName.text = d.firstName;
      _lastName.text = d.lastName;
      _companyName.text = d.companyName;
      _contactName.text = d.contactName;
      _email.text = d.email;
      _phone.text = d.phone;
      _street.text = d.street;
      _houseNumber.text = d.houseNumber;
      _zip.text = d.zip;
      _city.text = d.city;
      _billingStreet.text = d.billingStreet;
      _billingHouseNumber.text = d.billingHouseNumber;
      _billingZip.text = d.billingZip;
      _billingCity.text = d.billingCity;
      _billingEmail.text = d.billingEmail;
      _vatId.text = d.vatId;
      _taxNumber.text = d.taxNumber;
      _paymentTerms.text = d.paymentTerms;
      _notes.text = d.notes;
    }
    final target = widget.focusField;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToField(target);
      });
    }
  }

  void _scrollToField(CustomerFormFocusField f) {
    setState(() {
      if (_fieldInKontakt(f)) _kontaktExpanded = true;
      if (_fieldInLieferadresse(f)) _adresseExpanded = true;
      if (_fieldInRechnungsadresse(f)) _rechnungsadresseExpanded = true;
      if (_fieldInRechnungsinfo(f)) _rechnungsinfoExpanded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _fieldKeys[f]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.15,
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
          );
        }
        _fieldFocusNodes[f]?.requestFocus();
      });
    });
  }

  bool _fieldInKontakt(CustomerFormFocusField f) {
    return f == CustomerFormFocusField.customerNumber ||
        f == CustomerFormFocusField.companyName ||
        f == CustomerFormFocusField.contactName ||
        f == CustomerFormFocusField.email ||
        f == CustomerFormFocusField.phone;
  }

  bool _fieldInLieferadresse(CustomerFormFocusField f) {
    return f == CustomerFormFocusField.street ||
        f == CustomerFormFocusField.houseNumber ||
        f == CustomerFormFocusField.zip ||
        f == CustomerFormFocusField.city;
  }

  bool _fieldInRechnungsadresse(CustomerFormFocusField f) {
    return f == CustomerFormFocusField.billingStreet ||
        f == CustomerFormFocusField.billingHouseNumber ||
        f == CustomerFormFocusField.billingZip ||
        f == CustomerFormFocusField.billingCity ||
        f == CustomerFormFocusField.billingEmail;
  }

  bool _fieldInRechnungsinfo(CustomerFormFocusField f) {
    return f == CustomerFormFocusField.vatId ||
        f == CustomerFormFocusField.taxNumber ||
        f == CustomerFormFocusField.paymentTerms;
  }

  Widget _focusWrap(CustomerFormFocusField f, Widget child) {
    return KeyedSubtree(key: _fieldKeys[f], child: child);
  }

  FocusNode _fn(CustomerFormFocusField f) => _fieldFocusNodes[f]!;

  @override
  void dispose() {
    for (final n in _fieldFocusNodes.values) {
      n.dispose();
    }
    _firstName.dispose();
    _lastName.dispose();
    _companyName.dispose();
    _contactName.dispose();
    _customerNumber.dispose();
    _email.dispose();
    _phone.dispose();
    _street.dispose();
    _houseNumber.dispose();
    _zip.dispose();
    _city.dispose();
    _billingStreet.dispose();
    _billingHouseNumber.dispose();
    _billingZip.dispose();
    _billingCity.dispose();
    _vatId.dispose();
    _taxNumber.dispose();
    _billingEmail.dispose();
    _paymentTerms.dispose();
    _notes.dispose();
    super.dispose();
  }

  CustomerDraft _createDraft() {
    return CustomerDraft(
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
      kind: _kind,
      customerNumber: _customerNumber.text,
      firstName: _firstName.text,
      lastName: _lastName.text,
      companyName: _companyName.text,
      contactName: _contactName.text,
      email: _email.text,
      phone: _phone.text,
      street: _street.text,
      houseNumber: _houseNumber.text,
      zip: _zip.text,
      city: _city.text,
      billingStreet: _billingStreet.text,
      billingHouseNumber: _billingHouseNumber.text,
      billingZip: _billingZip.text,
      billingCity: _billingCity.text,
      billingEmail: _billingEmail.text,
      vatId: _vatId.text,
      taxNumber: _taxNumber.text,
      paymentTerms: _paymentTerms.text,
      notes: _notes.text,
    );
  }

  static const Duration _kCollapseDuration = Duration(milliseconds: 220);

  /// Auf-/zuklappbarer Formular-Block mit Überschrift und [AnimatedSize].
  Widget _buildCollapsibleBlock({
    required ThemeData theme,
    required String title,
    required String semanticsHint,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final accent = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: Semantics(
            button: true,
            expanded: expanded,
            label: title,
            hint: semanticsHint,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: _kCollapseDuration,
                      curve: Curves.easeInOut,
                      turns: expanded ? 0 : -0.25,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _kCollapseDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildKindSelector(ThemeData theme) {
    final active = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kundentyp',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KindOptionTile(
                label: 'Privatkunde',
                selected: _kind == CustomerKind.privat,
                activeColor: active,
                onTap: () => setState(() => _kind = CustomerKind.privat),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KindOptionTile(
                label: 'Firmenkunde',
                selected: _kind == CustomerKind.firma,
                activeColor: active,
                onTap: () => setState(() => _kind = CustomerKind.firma),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;
    final contentHeight = (screenH * 0.62).clamp(420.0, 620.0);
    final formCardWidth = _kNewCustomerFormWidth > screenW - 32
        ? screenW - 32
        : _kNewCustomerFormWidth;

    final formCard = DoorDeskFormCard(
      child: SizedBox(
        width: formCardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                widget.initial == null ? 'Neuer Kunde' : 'Kunde bearbeiten',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: SizedBox(
                height: contentHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: _kFormScrollGutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildKindSelector(theme),
                      const SizedBox(height: 24),
                      _buildCollapsibleBlock(
                        theme: theme,
                        title: 'Kontaktdaten',
                        semanticsHint:
                            'Kontaktfelder anzeigen oder ausblenden',
                        expanded: _kontaktExpanded,
                        onToggle: () => setState(
                          () => _kontaktExpanded = !_kontaktExpanded,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _focusWrap(
                              CustomerFormFocusField.customerNumber,
                              LabeledTextFormField(
                                label: 'Kundennummer',
                                controller: _customerNumber,
                                hint: 'optional',
                                focusNode:
                                    _fn(CustomerFormFocusField.customerNumber),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_kind == CustomerKind.privat) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: LabeledTextFormField(
                                      label: 'Vorname',
                                      controller: _firstName,
                                      hint: 'Vorname',
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: LabeledTextFormField(
                                      label: 'Nachname',
                                      controller: _lastName,
                                      hint: 'Nachname',
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              _focusWrap(
                                CustomerFormFocusField.companyName,
                                LabeledTextFormField(
                                  label: 'Firmenname',
                                  controller: _companyName,
                                  hint: 'Name eingeben',
                                  focusNode:
                                      _fn(CustomerFormFocusField.companyName),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _focusWrap(
                                CustomerFormFocusField.contactName,
                                LabeledTextFormField(
                                  label: 'Ansprechpartner',
                                  controller: _contactName,
                                  hint: 'Name eingeben',
                                  focusNode:
                                      _fn(CustomerFormFocusField.contactName),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _focusWrap(
                                    CustomerFormFocusField.email,
                                    LabeledTextFormField(
                                      label: 'E-Mail',
                                      controller: _email,
                                      hint: 'E-Mail eingeben',
                                      keyboardType: TextInputType.emailAddress,
                                      focusNode:
                                          _fn(CustomerFormFocusField.email),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _focusWrap(
                                    CustomerFormFocusField.phone,
                                    LabeledTextFormField(
                                      label: 'Telefon',
                                      controller: _phone,
                                      hint: 'Nummer eingeben',
                                      keyboardType: TextInputType.phone,
                                      focusNode:
                                          _fn(CustomerFormFocusField.phone),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCollapsibleBlock(
                        theme: theme,
                        title: 'Adresse',
                        semanticsHint:
                            'Adressfelder anzeigen oder ausblenden',
                        expanded: _adresseExpanded,
                        onToggle: () => setState(
                          () => _adresseExpanded = !_adresseExpanded,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _focusWrap(
                                    CustomerFormFocusField.street,
                                    LabeledTextFormField(
                                      label: 'Straße',
                                      controller: _street,
                                      hint: 'Straße',
                                      focusNode:
                                          _fn(CustomerFormFocusField.street),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _focusWrap(
                                    CustomerFormFocusField.houseNumber,
                                    LabeledTextFormField(
                                      label: 'Hausnummer',
                                      controller: _houseNumber,
                                      hint: 'Nr.',
                                      focusNode: _fn(
                                          CustomerFormFocusField.houseNumber),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _focusWrap(
                                    CustomerFormFocusField.zip,
                                    LabeledTextFormField(
                                      label: 'PLZ',
                                      controller: _zip,
                                      hint: 'PLZ',
                                      keyboardType: TextInputType.text,
                                      focusNode: _fn(CustomerFormFocusField.zip),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _focusWrap(
                                    CustomerFormFocusField.city,
                                    LabeledTextFormField(
                                      label: 'Ort',
                                      controller: _city,
                                      hint: 'Ort',
                                      focusNode:
                                          _fn(CustomerFormFocusField.city),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCollapsibleBlock(
                        theme: theme,
                        title: 'Rechnungsadresse',
                        semanticsHint:
                            'Rechnungsadresse anzeigen oder ausblenden',
                        expanded: _rechnungsadresseExpanded,
                        onToggle: () => setState(
                          () => _rechnungsadresseExpanded =
                              !_rechnungsadresseExpanded,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _focusWrap(
                                    CustomerFormFocusField.billingStreet,
                                    LabeledTextFormField(
                                      label: 'Straße',
                                      controller: _billingStreet,
                                      hint: 'Straße',
                                      focusNode: _fn(
                                          CustomerFormFocusField.billingStreet),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _focusWrap(
                                    CustomerFormFocusField.billingHouseNumber,
                                    LabeledTextFormField(
                                      label: 'Hausnummer',
                                      controller: _billingHouseNumber,
                                      hint: 'Nr.',
                                      focusNode: _fn(CustomerFormFocusField
                                          .billingHouseNumber),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _focusWrap(
                                    CustomerFormFocusField.billingZip,
                                    LabeledTextFormField(
                                      label: 'PLZ',
                                      controller: _billingZip,
                                      hint: 'PLZ',
                                      keyboardType: TextInputType.text,
                                      focusNode: _fn(
                                          CustomerFormFocusField.billingZip),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _focusWrap(
                                    CustomerFormFocusField.billingCity,
                                    LabeledTextFormField(
                                      label: 'Ort',
                                      controller: _billingCity,
                                      hint: 'Ort',
                                      focusNode: _fn(
                                          CustomerFormFocusField.billingCity),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _focusWrap(
                              CustomerFormFocusField.billingEmail,
                              LabeledTextFormField(
                                label: 'Rechnungs-E-Mail',
                                controller: _billingEmail,
                                hint: 'optional',
                                keyboardType: TextInputType.emailAddress,
                                focusNode:
                                    _fn(CustomerFormFocusField.billingEmail),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCollapsibleBlock(
                        theme: theme,
                        title: 'Rechnungsinformationen',
                        semanticsHint:
                            'Rechnungsinformationen anzeigen oder ausblenden',
                        expanded: _rechnungsinfoExpanded,
                        onToggle: () => setState(
                          () =>
                              _rechnungsinfoExpanded = !_rechnungsinfoExpanded,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _focusWrap(
                                    CustomerFormFocusField.vatId,
                                    LabeledTextFormField(
                                      label: 'Umsatzsteuer-ID',
                                      controller: _vatId,
                                      hint: 'z. B. DE123456789',
                                      focusNode:
                                          _fn(CustomerFormFocusField.vatId),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _focusWrap(
                                    CustomerFormFocusField.taxNumber,
                                    LabeledTextFormField(
                                      label: 'Steuernummer',
                                      controller: _taxNumber,
                                      hint: 'optional',
                                      focusNode:
                                          _fn(CustomerFormFocusField.taxNumber),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _focusWrap(
                              CustomerFormFocusField.paymentTerms,
                              LabeledTextFormField(
                                label: 'Zahlungsbedingungen',
                                controller: _paymentTerms,
                                hint: 'z. B. 14 Tage netto',
                                focusNode:
                                    _fn(CustomerFormFocusField.paymentTerms),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _focusWrap(
                        CustomerFormFocusField.notes,
                        LabeledTextFormField(
                          label: 'Notizen',
                          subtitle:
                              'Zusätzliche Informationen zum Kunden',
                          controller: _notes,
                          hint: 'Optional',
                          maxLines: 4,
                          focusNode: _fn(CustomerFormFocusField.notes),
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_createDraft()),
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: screenW,
        height: screenH,
        child: Center(child: formCard),
      ),
    );
  }
}

class _KindOptionTile extends StatelessWidget {
  const _KindOptionTile({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: selected ? 0.55 : 0.32,
      ),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? activeColor : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
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
