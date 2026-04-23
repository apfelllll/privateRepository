import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/invoices/add_line_dialog.dart';
import 'package:doordesk/features/invoices/invoice_line_row.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Rechnungs-Detail in der Hauptfläche (analog [QuoteDetailShell] /
/// [OrderDetailShell]).
///
/// Wird NICHT als Vollbild-Route per Navigator gepusht — sondern direkt in die
/// rechte Detail-Spalte der `OrdersPage` gerendert, damit die Left-Rail und
/// die untere Tab-Leiste sichtbar bleiben.
///
/// Der Parent (`OrdersPage`) hält die Rechnungsliste; alle Änderungen am
/// lokalen Entwurf werden über [onInvoiceUpdated] zurückgemeldet. Der
/// Finalisierungs-Flow liegt bewusst außerhalb dieser Shell, damit er auf
/// Ebene der `OrdersPage` (inklusive Bestätigungsdialog) angestoßen werden
/// kann.
class InvoiceDetailShell extends StatefulWidget {
  const InvoiceDetailShell({
    super.key,
    required this.initialInvoice,
    required this.onClose,
    required this.onInvoiceUpdated,
    this.canManage = false,
  });

  final Invoice initialInvoice;
  final VoidCallback onClose;
  final ValueChanged<Invoice> onInvoiceUpdated;
  final bool canManage;

  @override
  State<InvoiceDetailShell> createState() => _InvoiceDetailShellState();
}

class _InvoiceDetailShellState extends State<InvoiceDetailShell> {
  late Invoice _invoice;

  bool _onEscapeKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    widget.onClose();
    return true;
  }

  @override
  void initState() {
    super.initState();
    _invoice = widget.initialInvoice;
    HardwareKeyboard.instance.addHandler(_onEscapeKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onEscapeKey);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InvoiceDetailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Der Parent kann den Entwurf von außen aktualisieren (z. B. nach dem
    // Finalisieren via Title-Row-Button). Wir ziehen den neuen Stand nach.
    if (widget.initialInvoice.id == _invoice.id &&
        !identical(widget.initialInvoice, _invoice)) {
      setState(() => _invoice = widget.initialInvoice);
    }
  }

  void _applyChange(Invoice updated) {
    setState(() => _invoice = updated);
    widget.onInvoiceUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InvoiceDetailPanel(
        invoice: _invoice,
        canManage: widget.canManage,
        onInvoiceUpdated: _applyChange,
      ),
    );
  }
}

/// Inhalt der Rechnungs-Detailseite — alles auf einem einzigen „Blatt“,
/// damit die Seite wie ein echtes Rechnungsdokument liest (von oben nach
/// unten). Keine verschachtelten Cards mehr, stattdessen Trennlinien
/// zwischen den Abschnitten.
///
/// Reihenfolge: „Rechnung auf einen Blick“ · Meta (Nummer, Status, Daten) ·
/// Anschrift · optional Finalisiert-Banner · Arbeit · Material · Frei ·
/// Summen.
class InvoiceDetailPanel extends StatelessWidget {
  const InvoiceDetailPanel({
    super.key,
    required this.invoice,
    required this.onInvoiceUpdated,
    this.canManage = false,
  });

  final Invoice invoice;

  /// Wird aufgerufen, wenn der Nutzer Positionen hinzufügt, bearbeitet oder
  /// entfernt. Der Parent (`InvoiceDetailShell`) hält den Entwurf im State
  /// und reicht Änderungen bis zur `OrdersPage` durch.
  final ValueChanged<Invoice> onInvoiceUpdated;

  /// Darf der aktuelle Nutzer Inhalte bearbeiten? Bei `false` — oder bei
  /// finalisierter Rechnung — werden die Schreibaktionen ausgeblendet.
  final bool canManage;

  bool get _readOnly =>
      !canManage || invoice.status == InvoiceStatus.finalisiert;

  void _applyLines(List<InvoiceLineItem> lines) {
    onInvoiceUpdated(invoice.copyWith(lines: lines));
  }

  void _updateLine(InvoiceLineItem updated) {
    final list = <InvoiceLineItem>[
      for (final l in invoice.lines)
        if (l.id == updated.id) updated else l,
    ];
    _applyLines(list);
  }

  void _deleteLine(InvoiceLineItem l) {
    _applyLines(invoice.lines.where((x) => x.id != l.id).toList());
  }

  Future<void> _addLine(BuildContext context) async {
    final line = await showAddInvoiceLineDialog(context);
    if (line == null) return;
    _applyLines([...invoice.lines, line]);
  }

  void _updateIntroText(String text) {
    onInvoiceUpdated(invoice.copyWith(introText: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rechnung auf einen Blick',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              _InvoiceSheet(
                invoice: invoice,
                readOnly: _readOnly,
                onAddLine: _readOnly ? null : () => _addLine(context),
                onChangedLine: _updateLine,
                onDeleteLine: _deleteLine,
                onIntroTextChanged: _readOnly ? null : _updateIntroText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein einziges großes „Blatt“ (weiß, abgerundet, dezenter Rahmen), das alle
/// Rechnungs-Blöcke untereinander enthält. Zwischen den Blöcken stehen
/// schmale Trennlinien, damit das Dokument-Feeling erhalten bleibt.
class _InvoiceSheet extends StatelessWidget {
  const _InvoiceSheet({
    required this.invoice,
    required this.readOnly,
    required this.onChangedLine,
    required this.onDeleteLine,
    this.onAddLine,
    this.onIntroTextChanged,
  });

  final Invoice invoice;
  final bool readOnly;
  final VoidCallback? onAddLine;
  final ValueChanged<InvoiceLineItem> onChangedLine;
  final ValueChanged<InvoiceLineItem> onDeleteLine;

  /// Wird aufgerufen, wenn der Nutzer den Einleitungstext ändert.
  /// `null` = Feld ist read-only (finalisiert oder fehlende Berechtigung).
  final ValueChanged<String>? onIntroTextChanged;

  @override
  Widget build(BuildContext context) {
    final arbeit = invoice.linesOf(InvoiceLineKind.arbeit);
    final material = invoice.linesOf(InvoiceLineKind.material);
    final frei = invoice.linesOf(InvoiceLineKind.frei);
    final showFreiSection = frei.isNotEmpty || !readOnly;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaBlock(invoice: invoice),
          const SizedBox(height: 24),
          _AddressBlock(invoice: invoice),
          const SizedBox(height: 24),
          _IntroTextBlock(
            salutationLine: invoice.customer.salutationLine,
            initialBodyText: invoice.introText,
            onBodyChanged: onIntroTextChanged,
          ),
          if (invoice.status == InvoiceStatus.finalisiert) ...[
            const SizedBox(height: 20),
            _FinalizedBanner(invoice: invoice),
          ],
          const SizedBox(height: 28),
          const _SheetDivider(),
          _SectionBlock(
            title: 'Arbeit',
            icon: Icons.schedule_rounded,
            emptyHint:
                'Keine Arbeitszeiten übernommen. Über das „+“-Symbol manuell ergänzen.',
            lines: arbeit,
            subtotal: invoice.subtotalFor(InvoiceLineKind.arbeit),
            readOnly: readOnly,
            onAdd: onAddLine,
            onChanged: onChangedLine,
            onDelete: onDeleteLine,
          ),
          const _SheetDivider(),
          _SectionBlock(
            title: 'Material',
            icon: Icons.inventory_2_outlined,
            emptyHint:
                'Noch kein Material erfasst. Über das „+“-Symbol eine Material-Position anlegen.',
            lines: material,
            subtotal: invoice.subtotalFor(InvoiceLineKind.material),
            readOnly: readOnly,
            onAdd: onAddLine,
            onChanged: onChangedLine,
            onDelete: onDeleteLine,
          ),
          if (showFreiSection) ...[
            const _SheetDivider(),
            _SectionBlock(
              title: 'Freie Positionen',
              icon: Icons.edit_note_rounded,
              emptyHint:
                  'Keine freien Positionen. Über das „+“-Symbol ergänzen.',
              lines: frei,
              subtotal: invoice.subtotalFor(InvoiceLineKind.frei),
              readOnly: readOnly,
              onAdd: onAddLine,
              onChanged: onChangedLine,
              onDelete: onDeleteLine,
            ),
          ],
          const _SheetDivider(thicker: true),
          _TotalsBlock(invoice: invoice),
        ],
      ),
    );
  }
}

/// Kopfzeile des Rechnungsblatts: Rechnungsnummer + Status-Chip, Erstell-
/// und Finalisierungsdatum, zugehöriger Auftrag.
class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMMd('de_DE');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Rechnung ${invoice.invoiceNumber}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            _StatusChip(status: invoice.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Erstellt am ${dateFmt.format(invoice.createdAt)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          'Auftrag ${invoice.orderNumber} — '
          '${invoice.orderTitle.isEmpty ? 'Ohne Titel' : invoice.orderTitle}',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Anschrift-Block unter dem Kopf — mehrzeilig, automatisch aus dem
/// Kunden-Snapshot aufgebaut. Der Snapshot enthält bereits die
/// Rechnungsadresse mit Fallback auf die Lieferadresse (siehe
/// [InvoiceCustomerSnapshot.fromCustomer]); leere Zeilen werden
/// ausgeblendet.
class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = invoice.customer;

    final nameLine = c.displayTitle.trim();
    final streetLine =
        '${c.billingStreet.trim()} ${c.billingHouseNumber.trim()}'.trim();
    final cityParts = <String>[
      if (c.billingZip.trim().isNotEmpty) c.billingZip.trim(),
      if (c.billingCity.trim().isNotEmpty) c.billingCity.trim(),
    ];
    final cityLine = cityParts.join(' ');

    final addressLines = <String>[
      if (nameLine.isNotEmpty) nameLine,
      if (streetLine.isNotEmpty) streetLine,
      if (cityLine.isNotEmpty) cityLine,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anschrift',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (addressLines.isEmpty)
          Text(
            'Keine Anschrift hinterlegt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < addressLines.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
                  child: Text(
                    addressLines[i],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      // Den Namen etwas kräftiger — orientiert sich am
                      // typografischen Aufbau klassischer Briefanschriften.
                      fontWeight: i == 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (status) {
      InvoiceStatus.entwurf => (
        const Color(0xFFFFF4E5),
        const Color(0xFFB25C00),
      ),
      InvoiceStatus.finalisiert => (
        const Color(0xFFE7F7EC),
        const Color(0xFF2E7D4F),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayLabel,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FinalizedBanner extends StatelessWidget {
  const _FinalizedBanner({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = invoice.finalizedAt == null
        ? ''
        : ' am ${DateFormat.yMMMd('de_DE').add_Hm().format(invoice.finalizedAt!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3E0C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFF2E7D4F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Diese Rechnung wurde finalisiert$date. Änderungen sind nur '
              'über eine neue Version oder eine Gutschrift möglich.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF1E5935),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Schmale Trennlinie zwischen zwei Abschnitten auf dem Rechnungsblatt.
/// `thicker = true` wird vor dem Summen-Abschnitt verwendet, um das
/// Gesamtergebnis optisch vom Rest abzuheben.
class _SheetDivider extends StatelessWidget {
  const _SheetDivider({this.thicker = false});

  final bool thicker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: thicker ? 20 : 16),
      child: Divider(
        height: 1,
        thickness: thicker ? 1.2 : 1,
        color: AppColors.border,
      ),
    );
  }
}

/// Ein Abschnitt des Rechnungsblatts (Arbeit / Material / Freie Positionen).
/// Kein eigener Rahmen — nur Überschrift, Positionen und Zwischensumme,
/// damit der gesamte Eindruck „ein Blatt“ bleibt.
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.icon,
    required this.emptyHint,
    required this.lines,
    required this.subtotal,
    required this.readOnly,
    required this.onChanged,
    required this.onDelete,
    this.onAdd,
  });

  final String title;
  final IconData icon;
  final String emptyHint;
  final List<InvoiceLineItem> lines;
  final double subtotal;
  final bool readOnly;
  final ValueChanged<InvoiceLineItem> onChanged;
  final ValueChanged<InvoiceLineItem> onDelete;

  /// Wenn gesetzt, erscheint rechts oben im Abschnitt ein „+“-Button.
  /// `null` — Abschnitt ist komplett read-only (kein Add möglich).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Zwischensumme: ${_fmtEuro(subtotal)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 12),
              Tooltip(
                message: 'Position hinzufügen',
                child: IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.35),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                InvoiceLineRow(
                  key: ValueKey(lines[i].id),
                  line: lines[i],
                  readOnly: readOnly,
                  onChanged: onChanged,
                  onDelete: () => onDelete(lines[i]),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Summen-Abschnitt am Ende des Rechnungsblatts — kein eigener Rahmen, nur
/// Zeilen mit Zwischensummen und einem hervorgehobenen Gesamtbetrag.
class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ergebnis',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _totalRow(
          theme,
          'Arbeit',
          invoice.subtotalFor(InvoiceLineKind.arbeit),
        ),
        _totalRow(
          theme,
          'Material',
          invoice.subtotalFor(InvoiceLineKind.material),
        ),
        if (invoice.subtotalFor(InvoiceLineKind.frei) != 0)
          _totalRow(
            theme,
            'Freie Positionen',
            invoice.subtotalFor(InvoiceLineKind.frei),
          ),
        const SizedBox(height: 10),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Gesamt (netto)',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _fmtEuro(invoice.netTotal),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Umsatzsteuer wird im nächsten Ausbauschritt ergänzt.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _totalRow(ThemeData theme, String label, double v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(
            _fmtEuro(v),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Einleitungstext-Block — zwei parametrisch zusammengesetzte Zeilen:
///
/// 1. Die Anrede-Zeile (z. B. „Sehr geehrter Herr Brühl,") wird automatisch
///    aus dem Kunden-Snapshot abgeleitet ([InvoiceCustomerSnapshot.salutationLine])
///    und ist im Rechnungs-Editor **nicht** direkt editierbar — sie folgt der
///    Anrede am Kunden.
/// 2. Der Body (z. B. „nachfolgend berechnen wir Ihnen wie vorab besprochen:")
///    ist frei editierbar und wird in [Invoice.introText] persistiert.
///
/// Implementierung als StatefulWidget, damit der lokale [TextEditingController]
/// über Rebuilds hinweg stabil bleibt und der Cursor beim Tippen nicht springt.
class _IntroTextBlock extends StatefulWidget {
  const _IntroTextBlock({
    required this.salutationLine,
    required this.initialBodyText,
    required this.onBodyChanged,
  });

  /// Auto-generierte Anrede (read-only, aus dem Kunden-Snapshot).
  final String salutationLine;

  /// Startwert für den editierbaren Body-Text — entspricht [Invoice.introText].
  final String initialBodyText;

  /// `null` = Body ist read-only (finalisierte Rechnung / fehlende
  /// Berechtigung). Der Text wird dann nur statisch angezeigt.
  final ValueChanged<String>? onBodyChanged;

  @override
  State<_IntroTextBlock> createState() => _IntroTextBlockState();
}

class _IntroTextBlockState extends State<_IntroTextBlock> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBodyText);
  }

  @override
  void didUpdateWidget(covariant _IntroTextBlock old) {
    super.didUpdateWidget(old);
    // Externe Änderungen übernehmen, ohne den Cursor springen zu lassen —
    // nur, wenn sich der Inhalt tatsächlich unterscheidet.
    if (widget.initialBodyText != _controller.text) {
      _controller.text = widget.initialBodyText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readOnly = widget.onBodyChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Einleitungstext',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        // Zeile 1 — automatisch aus den Kundendaten abgeleitet.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.salutationLine,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Die Anrede wird automatisch aus der beim Kunden '
                    'hinterlegten Anrede (Herr/Frau) und dem Nachnamen '
                    'erzeugt. Anpassen direkt am Kunden.',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Zeile 2 — editierbarer Body.
        if (readOnly)
          _ReadOnlyIntroBody(text: widget.initialBodyText)
        else
          TextField(
            controller: _controller,
            onChanged: widget.onBodyChanged,
            minLines: 2,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            decoration: InputDecoration(
              hintText: kDefaultInvoiceIntroBody,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyIntroBody extends StatelessWidget {
  const _ReadOnlyIntroBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (text.trim().isEmpty) {
      return Text(
        'Kein Einleitungstext hinterlegt.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
    );
  }
}

String _fmtEuro(double v) {
  final f = NumberFormat.currency(locale: 'de_DE', symbol: '€');
  return f.format(v);
}
