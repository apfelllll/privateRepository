import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/quote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zeigt einen Dialog zum Erstellen oder Bearbeiten einer [QuoteLineItem].
///
/// Wird [initial] übergeben, läuft der Dialog im Bearbeitungs-Modus (Felder
/// sind vorbefüllt, Button-Label „Speichern"). Ohne [initial] legt der
/// Dialog eine neue Position an.
///
/// Liefert die (ggf. aktualisierte) Position zurück oder `null`, wenn der
/// Nutzer den Dialog abbricht.
Future<QuoteLineItem?> showQuoteLineDialog(
  BuildContext context, {
  QuoteLineItem? initial,
}) {
  return showDialog<QuoteLineItem>(
    context: context,
    builder: (_) => _QuoteLineDialog(initial: initial),
  );
}

class _QuoteLineDialog extends StatefulWidget {
  const _QuoteLineDialog({this.initial});

  final QuoteLineItem? initial;

  @override
  State<_QuoteLineDialog> createState() => _QuoteLineDialogState();
}

class _QuoteLineDialogState extends State<_QuoteLineDialog> {
  late QuoteLineKind _kind;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _kind = init?.kind ?? QuoteLineKind.material;
    _description = TextEditingController(text: init?.description ?? '');
    _quantity = TextEditingController(
      text: init != null ? _fmtNum(init.quantity) : '1',
    );
    _unitPrice = TextEditingController(
      text: init != null ? _fmtNum(init.unitPrice) : '',
    );
    _unit = TextEditingController(
      text: (init != null && init.unit.isNotEmpty) ? init.unit : 'Stk',
    );
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _unit.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial != null;

  void _submit() {
    final desc = _description.text.trim();
    final qty = _parseNum(_quantity.text) ?? 0;
    final price = _parseNum(_unitPrice.text) ?? 0;
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Beschreibung eingeben.')),
      );
      return;
    }
    final unit = _kind == QuoteLineKind.material ? _unit.text.trim() : '';
    final id = widget.initial?.id ??
        'qline_${DateTime.now().microsecondsSinceEpoch}_${_kind.name}';
    final line = QuoteLineItem(
      id: id,
      kind: _kind,
      active: widget.initial?.active ?? true,
      description: desc,
      quantity: qty,
      unitPrice: price,
      unit: unit,
    );
    Navigator.of(context).pop(line);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEdit ? 'Position bearbeiten' : 'Neue Position'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Art',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<QuoteLineKind>(
              segments: const [
                ButtonSegment(
                  value: QuoteLineKind.arbeit,
                  icon: Icon(Icons.schedule_rounded),
                  label: Text('Arbeitszeit'),
                ),
                ButtonSegment(
                  value: QuoteLineKind.material,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Material'),
                ),
                ButtonSegment(
                  value: QuoteLineKind.frei,
                  icon: Icon(Icons.edit_note_rounded),
                  label: Text('Frei'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Beschreibung',
                hintText: _hintForKind(_kind),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: _kind == QuoteLineKind.arbeit
                          ? 'Stunden'
                          : 'Menge',
                    ),
                  ),
                ),
                if (_kind == QuoteLineKind.material) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Einheit',
                        hintText: 'Stk',
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _unitPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: _kind == QuoteLineKind.arbeit
                          ? 'Stundensatz (€)'
                          : 'Einzelpreis (€)',
                      hintText: '0,00',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }
}

String _hintForKind(QuoteLineKind kind) => switch (kind) {
  QuoteLineKind.arbeit => 'z. B. Montage Haustür',
  QuoteLineKind.material => 'z. B. Kantholz Fichte 60x60 mm',
  QuoteLineKind.frei => 'z. B. Entsorgungspauschale',
};

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString().replaceAll('.', ',');
}

double? _parseNum(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned);
}
