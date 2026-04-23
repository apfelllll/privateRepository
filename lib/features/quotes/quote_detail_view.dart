import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/quotes/add_quote_line_dialog.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:doordesk/models/quote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Angebots-Detail in der Hauptfläche (analog [OrderDetailShell]).
///
/// Wird NICHT als Vollbild-Route per Navigator gepusht — sondern direkt in
/// die rechte Detail-Spalte der `OrdersPage` gerendert, damit die Left-Rail
/// ("Aufträge"/"Kunden") und die untere Tab-Leiste sichtbar bleiben.
///
/// Der Parent (`OrdersPage`) hält die eigentliche Angebotsliste; Änderungen
/// am lokalen Entwurf werden über [onQuoteUpdated] zurückgemeldet.
class QuoteDetailShell extends StatefulWidget {
  const QuoteDetailShell({
    super.key,
    required this.initialQuote,
    required this.onClose,
    required this.onQuoteUpdated,
    this.canManage = false,
  });

  final Quote initialQuote;
  final VoidCallback onClose;
  final ValueChanged<Quote> onQuoteUpdated;
  final bool canManage;

  @override
  State<QuoteDetailShell> createState() => _QuoteDetailShellState();
}

class _QuoteDetailShellState extends State<QuoteDetailShell> {
  late Quote _quote;

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
    _quote = widget.initialQuote;
    HardwareKeyboard.instance.addHandler(_onEscapeKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onEscapeKey);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuoteDetailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuote.id == _quote.id &&
        !identical(widget.initialQuote, _quote)) {
      setState(() => _quote = widget.initialQuote);
    }
  }

  void _applyChange(Quote updated) {
    setState(() => _quote = updated);
    widget.onQuoteUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: QuoteDetailPanel(
        quote: _quote,
        canManage: widget.canManage,
        onQuoteUpdated: _applyChange,
      ),
    );
  }
}

/// Inhalt der Angebots-Detailseite (ohne eigenes Scaffold/AppBar — die
/// Titelzeile liefert die umgebende Shell).
///
/// Die Seite dient als Überblick („Angebot auf einen Blick"): Kopfdaten,
/// Positions-Tabelle (Arbeit/Material/Freie Positionen) und Summe. Neue
/// Positionen werden über den „+"-Button rechts oben in der Tabelle
/// angelegt; Klick auf eine Zeile öffnet sie im Bearbeiten-Dialog.
class QuoteDetailPanel extends StatelessWidget {
  const QuoteDetailPanel({
    super.key,
    required this.quote,
    required this.onQuoteUpdated,
    this.canManage = false,
  });

  final Quote quote;

  /// Wird aufgerufen, wenn der Nutzer Positionen hinzufügt, bearbeitet oder
  /// entfernt. Der Parent (`QuoteDetailShell`) hält den Entwurf im State
  /// und reicht Änderungen bis zur `OrdersPage` durch.
  final ValueChanged<Quote> onQuoteUpdated;

  /// Darf der aktuelle Nutzer Inhalte bearbeiten? Bei `false` werden die
  /// Schreibaktionen (Positionen hinzufügen/entfernen/bearbeiten) ausgeblendet.
  final bool canManage;

  Future<void> _addLine(BuildContext context) async {
    final line = await showQuoteLineDialog(context);
    if (line == null) return;
    onQuoteUpdated(quote.copyWith(lines: [...quote.lines, line]));
  }

  Future<void> _editLine(BuildContext context, QuoteLineItem original) async {
    final updated = await showQuoteLineDialog(context, initial: original);
    if (updated == null) return;
    final next = <QuoteLineItem>[
      for (final l in quote.lines)
        if (l.id == original.id) updated else l,
    ];
    onQuoteUpdated(quote.copyWith(lines: next));
  }

  Future<void> _deleteLine(BuildContext context, QuoteLineItem line) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Position entfernen?'),
        content: Text(
          '„${line.description}" wird aus dem Angebot entfernt.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    onQuoteUpdated(
      quote.copyWith(
        lines: quote.lines.where((l) => l.id != line.id).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Angebot auf einen Blick',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _HeaderCard(quote: quote),
          const SizedBox(height: 20),
          _PositionsCard(
            quote: quote,
            canManage: canManage,
            onAdd: () => _addLine(context),
            onEdit: (l) => _editLine(context, l),
            onDelete: (l) => _deleteLine(context, l),
          ),
          const SizedBox(height: 16),
          _TotalsCard(quote: quote),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMMd('de_DE');
    final c = quote.customer;
    final addressLine1 = '${c.billingStreet} ${c.billingHouseNumber}'.trim();
    final addressLine2 = '${c.billingZip} ${c.billingCity}'.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Angebot ${quote.quoteNumber}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(status: quote.status),
                  ],
                ),
                if (quote.title.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    quote.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Erstellt am ${dateFmt.format(quote.createdAt)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Auftrag ${quote.orderNumber} — '
                  '${quote.orderTitle.isEmpty ? 'Ohne Titel' : quote.orderTitle}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (quote.validUntil != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Gültig bis ${dateFmt.format(quote.validUntil!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Angebotsempfänger',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.displayTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (addressLine1.isNotEmpty)
                  Text(addressLine1, style: theme.textTheme.bodyMedium),
                if (addressLine2.isNotEmpty)
                  Text(addressLine2, style: theme.textTheme.bodyMedium),
                if (c.customerNumber.trim().isNotEmpty)
                  Text(
                    'Kundennummer: ${c.customerNumber}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (status) {
      QuoteStatus.entwurf => (
        const Color(0xFFFFF4E5),
        const Color(0xFFB25C00),
      ),
      QuoteStatus.versendet => (
        const Color(0xFFE3EEFF),
        const Color(0xFF1F4FAF),
      ),
      QuoteStatus.angenommen => (
        const Color(0xFFE7F7EC),
        const Color(0xFF2E7D4F),
      ),
      QuoteStatus.abgelehnt => (
        const Color(0xFFFDE2E2),
        const Color(0xFFB02828),
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

/// Positions-Tabelle auf der Angebotsseite.
///
/// Spalten: Typ-Icon · Beschreibung · Menge + Einheit · Einzelpreis · Summe
/// · Aktionen. Oben rechts liegt der „+"-Button zum Hinzufügen einer neuen
/// Position (Arbeit/Material/Frei, gewählt im Dialog).
class _PositionsCard extends StatelessWidget {
  const _PositionsCard({
    required this.quote,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final Quote quote;
  final bool canManage;
  final VoidCallback onAdd;
  final ValueChanged<QuoteLineItem> onEdit;
  final ValueChanged<QuoteLineItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.view_list_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Positionen',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canManage)
                Tooltip(
                  message: 'Position hinzufügen',
                  child: FilledButton.tonalIcon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Position'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (quote.lines.isEmpty)
            _EmptyPositions(canManage: canManage)
          else
            _PositionsTable(
              lines: quote.lines,
              canManage: canManage,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

class _EmptyPositions extends StatelessWidget {
  const _EmptyPositions({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        canManage
            ? 'Noch keine Positionen. Über den Button „Position" oben '
                  'rechts eine neue Arbeitszeit-, Material- oder freie '
                  'Position anlegen.'
            : 'Dieses Angebot enthält noch keine Positionen.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PositionsTable extends StatelessWidget {
  const _PositionsTable({
    required this.lines,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final List<QuoteLineItem> lines;
  final bool canManage;
  final ValueChanged<QuoteLineItem> onEdit;
  final ValueChanged<QuoteLineItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _TableHeader(showActions: canManage),
            for (var i = 0; i < lines.length; i++) ...[
              const Divider(
                height: 1,
                color: AppColors.border,
              ),
              _TableRow(
                line: lines[i],
                striped: i.isOdd,
                canManage: canManage,
                onTap: canManage ? () => onEdit(lines[i]) : null,
                onDelete: canManage ? () => onDelete(lines[i]) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.showActions});

  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.2,
    );
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('Typ', style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: Text('Beschreibung', style: style)),
          Expanded(
            flex: 2,
            child: Text('Menge', style: style, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'Einzelpreis',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text('Summe', style: style, textAlign: TextAlign.right),
          ),
          if (showActions) const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.line,
    required this.striped,
    required this.canManage,
    this.onTap,
    this.onDelete,
  });

  final QuoteLineItem line;
  final bool striped;
  final bool canManage;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final qty = _fmtNum(line.quantity);
    final qtyText = line.kind == QuoteLineKind.material && line.unit.isNotEmpty
        ? '$qty ${line.unit}'
        : line.kind == QuoteLineKind.arbeit
        ? '$qty h'
        : qty;
    final numericStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        color: striped ? const Color(0xFFFAFBFD) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Tooltip(
                message: _labelForKind(line.kind),
                child: Icon(
                  _iconForKind(line.kind),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Text(
                line.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(qtyText, style: numericStyle, textAlign: TextAlign.right),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                money.format(line.unitPrice),
                style: numericStyle,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                money.format(line.lineTotal),
                style: numericStyle?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
            if (canManage)
              SizedBox(
                width: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Tooltip(
                    message: 'Position entfernen',
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _subtotalRow(
            theme,
            'Arbeitszeit',
            quote.subtotalFor(QuoteLineKind.arbeit),
            money,
          ),
          _subtotalRow(
            theme,
            'Material',
            quote.subtotalFor(QuoteLineKind.material),
            money,
          ),
          if (quote.subtotalFor(QuoteLineKind.frei) != 0)
            _subtotalRow(
              theme,
              'Freie Positionen',
              quote.subtotalFor(QuoteLineKind.frei),
              money,
            ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gesamt (netto)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                money.format(quote.netTotal),
                style: theme.textTheme.titleMedium?.copyWith(
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
      ),
    );
  }

  Widget _subtotalRow(
    ThemeData theme,
    String label,
    double value,
    NumberFormat money,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            money.format(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForKind(QuoteLineKind kind) => switch (kind) {
  QuoteLineKind.arbeit => Icons.schedule_rounded,
  QuoteLineKind.material => Icons.inventory_2_outlined,
  QuoteLineKind.frei => Icons.edit_note_rounded,
};

String _labelForKind(QuoteLineKind kind) => switch (kind) {
  QuoteLineKind.arbeit => 'Arbeitszeit',
  QuoteLineKind.material => 'Material',
  QuoteLineKind.frei => 'Freie Position',
};

String _fmtNum(double v) {
  if (v == v.roundToDouble()) {
    return NumberFormat.decimalPattern('de_DE').format(v.toInt());
  }
  return NumberFormat.decimalPattern('de_DE').format(v);
}
