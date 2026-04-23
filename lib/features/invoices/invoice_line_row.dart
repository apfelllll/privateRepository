import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Eine Zeile im Rechnungs-Editor — sowohl fuer Arbeit als auch Material/Frei.
///
/// Bei `readOnly = true` (finalisierte Rechnung) sind alle Felder deaktiviert
/// und die Lösch-Aktion ist entfernt. Editier-Callbacks werden via [onChanged]
/// gebuendelt — der Editor-Parent ersetzt dann die Zeile in seinem State.
class InvoiceLineRow extends StatefulWidget {
  const InvoiceLineRow({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onDelete,
    this.readOnly = false,
  });

  final InvoiceLineItem line;
  final ValueChanged<InvoiceLineItem> onChanged;
  final VoidCallback onDelete;
  final bool readOnly;

  @override
  State<InvoiceLineRow> createState() => _InvoiceLineRowState();
}

class _InvoiceLineRowState extends State<InvoiceLineRow> {
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: widget.line.description);
    _quantity = TextEditingController(text: _fmtNum(widget.line.quantity));
    _unitPrice = TextEditingController(text: _fmtNum(widget.line.unitPrice));
    _unit = TextEditingController(text: widget.line.unit);
  }

  @override
  void didUpdateWidget(covariant InvoiceLineRow old) {
    super.didUpdateWidget(old);
    // Externe Aenderungen (z. B. Neuberechnung) spiegeln — nur, wenn sich der
    // Wert wirklich unterscheidet (sonst springt der Cursor beim Tippen).
    if (widget.line.description != _description.text) {
      _description.text = widget.line.description;
    }
    final qtyText = _fmtNum(widget.line.quantity);
    if (qtyText != _quantity.text) {
      _quantity.text = qtyText;
    }
    final priceText = _fmtNum(widget.line.unitPrice);
    if (priceText != _unitPrice.text) {
      _unitPrice.text = priceText;
    }
    if (widget.line.unit != _unit.text) {
      _unit.text = widget.line.unit;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = widget.line;
    final disabled = widget.readOnly || !line.active;
    final isWork = line.kind == InvoiceLineKind.arbeit;
    final isMaterial = line.kind == InvoiceLineKind.material;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: line.active
            ? AppColors.surface
            : AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWork) _workMetaRow(theme, line),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: line.active ? 'Position deaktivieren' : 'Position aktivieren',
                waitDuration: const Duration(milliseconds: 400),
                child: Checkbox(
                  value: line.active,
                  onChanged: widget.readOnly
                      ? null
                      : (v) => widget.onChanged(
                          line.copyWith(active: v ?? true),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 4,
                child: _field(
                  controller: _description,
                  label: 'Beschreibung',
                  hint: 'Beschreibung',
                  enabled: !disabled,
                  onChanged: (v) =>
                      widget.onChanged(line.copyWith(description: v)),
                  disabledLineThrough: !line.active && !widget.readOnly,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _field(
                  controller: _quantity,
                  label: isWork ? 'Stunden' : 'Menge',
                  hint: isWork ? 'Stunden' : 'Menge',
                  enabled: !disabled,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  onChanged: (v) {
                    final q = _parseNum(v);
                    if (q == null) return;
                    widget.onChanged(line.copyWith(quantity: q));
                  },
                ),
              ),
              if (isMaterial) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _field(
                    controller: _unit,
                    label: 'Einheit',
                    hint: 'Stk',
                    enabled: !disabled,
                    onChanged: (v) =>
                        widget.onChanged(line.copyWith(unit: v)),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _field(
                  controller: _unitPrice,
                  label: isWork ? 'Stundensatz' : 'Einzelpreis',
                  hint: '0,00',
                  enabled: !disabled,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  onChanged: (v) {
                    final p = _parseNum(v);
                    if (p == null) return;
                    widget.onChanged(line.copyWith(unitPrice: p));
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Summe',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmtEuro(line.lineTotal),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: line.active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        decoration: line.active
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.readOnly)
                IconButton(
                  tooltip: 'Position loeschen',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: widget.onDelete,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  /// Kleiner Meta-Header fuer Arbeitspositionen: Datum, Mitarbeiter.
  Widget _workMetaRow(ThemeData theme, InvoiceLineItem line) {
    final parts = <String>[];
    if (line.workDate != null) {
      parts.add(DateFormat.yMMMd('de_DE').format(line.workDate!));
    }
    if (line.employeeName.isNotEmpty) {
      final qLabel = line.qualification?.suffixLabel ?? '';
      parts.add('${line.employeeName}${qLabel.isEmpty ? '' : ' $qLabel'}');
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 6),
      child: Text(
        parts.join('  ·  '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
    bool disabledLineThrough = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textAlign: textAlign,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge?.copyWith(
            decoration: disabledLineThrough
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            fontFeatures: keyboardType != null
                ? const [FontFeature.tabularFigures()]
                : null,
          ),
          inputFormatters: keyboardType != null
              ? <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

String _fmtNum(double v) {
  // 2 Nachkommastellen, deutsches Komma.
  final f = NumberFormat('0.##', 'de_DE');
  return f.format(v);
}

double? _parseNum(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned);
}

String _fmtEuro(double v) {
  final f = NumberFormat.currency(locale: 'de_DE', symbol: '€');
  return f.format(v);
}
